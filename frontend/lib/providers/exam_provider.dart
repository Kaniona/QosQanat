import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/curriculum.dart';
import '../models/enums.dart';
import '../models/exam.dart';
import 'auth_provider.dart';
import 'game_provider.dart';
import 'mastery_provider.dart';

/// Байқау сынағының параметрлері.
abstract final class ExamConfig {
  /// Бір сынақтағы сұрақтың болжалды жалпы саны.
  static const int targetTotal = 18;

  /// Бір сұраққа берілетін уақыт (жалпы таймер = сұрақ саны × осы).
  static const int secondsPerQuestion = 50;

  /// Осы дәлдіктен төмен тақырып «күшейту керек» деп белгіленеді.
  static const double weakThreshold = .6;

  /// Бір дұрыс жауаптың XP марапаты (сынақ — диагностика, марапат қалыпты).
  static const int xpPerCorrect = 3;
}

/// Сынақ сұрақтарын құрастыру — ТАЗА функция (тесттелетін, UI-сіз).
/// Инварианттар: әр тақырыптан (модульден) тең үлес; қиындық жеңілден қиынға
/// өседі; сәйкестендіру форматы кірмейді (емтихан қарқынына сай емес);
/// бір сынақта сұрақ мәтіні қайталанбайды.
List<ExamQuestion> buildExamQuestions(
  String subject,
  int grade, {
  Random? random,
}) {
  final rnd = random ?? Random();
  final moduleCount = Curriculum.moduleCount(subject, grade);
  if (moduleCount <= 0) return const [];
  final perModule = max(2, (ExamConfig.targetTotal / moduleCount).ceil());

  final byModule = <int, List<ExamQuestion>>{};
  for (final node in Curriculum.nodesForGrade(subject, grade)) {
    for (final q in node.questions) {
      if (q.type == QuestionType.matchPairs || q.options.isEmpty) continue;
      byModule.putIfAbsent(node.module, () => []).add(ExamQuestion(
            question: q,
            nodeId: node.id,
            module: node.module,
            moduleTitle: node.moduleTitle,
          ));
    }
  }

  // Бүкіл сынақ бойынша мәтін қайталанбауын кепілдейтін ГЛОБАЛ жиын: бір
  // тақырыптың сұрағы екінші тақырыпта да кездессе (банк бөлінбеген жағдай),
  // сынаққа екі рет түспейді.
  final usedTexts = <String>{};
  final picked = <ExamQuestion>[];
  for (var m = 1; m <= moduleCount; m++) {
    final pool = byModule[m] ?? const [];
    if (pool.isEmpty) continue;
    // Мәтін бойынша қайталанбайтын сұрақтар, қиындық бойынша реттелген
    // (осы тақырыпта да, бұрынғы тақырыптарда да кездеспегендер).
    final unique = [
      for (final e in pool)
        if (usedTexts.add(e.question.text)) e,
    ]..sort((a, b) =>
        a.question.difficulty.index.compareTo(b.question.difficulty.index));
    if (unique.isEmpty) continue;
    // perModule «жолаққа» бөліп, әрқайсысынан 1 кездейсоқ сұрақ —
    // тақырып іші де жеңілден қиынға тең қамтылады.
    final n = min(perModule, unique.length);
    final base = unique.length ~/ n;
    final rem = unique.length % n;
    var start = 0;
    for (var band = 0; band < n; band++) {
      final size = base + (band < rem ? 1 : 0);
      picked.add(unique[start + rnd.nextInt(size)]);
      start += size;
    }
  }

  // Жалпы емтихан қисығы: жеңілден қиынға (тақырыптар араласып отырады).
  picked.sort((a, b) =>
      a.question.difficulty.index.compareTo(b.question.difficulty.index));
  return picked;
}

/// Жауап парағын бағалау + тақырыптық талдау — ТАЗА функция.
/// [answers] — таңдалған нұсқа индекстері (уақыт бітсе, жетпегені қате).
ExamAttempt scoreExam({
  required String subject,
  required int grade,
  required List<ExamQuestion> questions,
  required List<int?> answers,
  required int durationSec,
  DateTime? date,
}) {
  var correct = 0;
  final titles = <int, String>{};
  final correctByModule = <int, int>{};
  final totalByModule = <int, int>{};
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    final ok = i < answers.length && answers[i] == q.question.correctIndex;
    if (ok) correct++;
    titles[q.module] = q.moduleTitle;
    correctByModule[q.module] = (correctByModule[q.module] ?? 0) + (ok ? 1 : 0);
    totalByModule[q.module] = (totalByModule[q.module] ?? 0) + 1;
  }
  final now = date ?? DateTime.now();
  final modules = [
    for (final m in totalByModule.keys.toList()..sort())
      ModuleScore(
        module: m,
        title: titles[m] ?? '',
        correct: correctByModule[m] ?? 0,
        total: totalByModule[m] ?? 0,
      ),
  ];
  return ExamAttempt(
    id: '${now.millisecondsSinceEpoch}',
    subject: subject,
    grade: grade,
    date: now,
    correct: correct,
    total: questions.length,
    durationSec: durationSec,
    modules: modules,
  );
}

/// Сынақ фазасы: ережелер → сұрақтар → нәтиже.
enum ExamPhase { intro, running, finished }

/// Сынақтың ағымдағы күйі (экран осыдан оқиды).
class ExamState {
  const ExamState({
    this.phase = ExamPhase.intro,
    this.questions = const [],
    this.index = 0,
    this.answers = const [],
    this.secondsLeft = 0,
    this.attempt,
  });

  final ExamPhase phase;
  final List<ExamQuestion> questions;
  final int index;
  final List<int?> answers;
  final int secondsLeft;

  /// Аяқталған сынақтың нәтижесі (phase == finished болғанда).
  final ExamAttempt? attempt;

  ExamState copyWith({
    ExamPhase? phase,
    List<ExamQuestion>? questions,
    int? index,
    List<int?>? answers,
    int? secondsLeft,
    ExamAttempt? attempt,
  }) {
    return ExamState(
      phase: phase ?? this.phase,
      questions: questions ?? this.questions,
      index: index ?? this.index,
      answers: answers ?? this.answers,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      attempt: attempt ?? this.attempt,
    );
  }
}

/// Бір пәннің байқау сынағы: таймер, жауап қабылдау, аяқтау (сақтау +
/// шеберлік движогіне азық + XP). family кілті — пән id.
class ExamNotifier extends StateNotifier<ExamState> {
  ExamNotifier(this._ref, this.subject) : super(const ExamState());

  final Ref _ref;
  final String subject;
  Timer? _timer;
  DateTime? _startedAt;

  int get _grade => (_ref.read(authProvider).user?.grade ?? 7).clamp(1, 11);

  /// Сынақты бастау: сұрақтар құрастырылып, таймер қосылады.
  void start() {
    final questions = buildExamQuestions(subject, _grade);
    if (questions.isEmpty) return;
    _timer?.cancel();
    _startedAt = DateTime.now();
    state = ExamState(
      phase: ExamPhase.running,
      questions: questions,
      secondsLeft: questions.length * ExamConfig.secondsPerQuestion,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsLeft <= 1) {
        finish();
      } else {
        state = state.copyWith(secondsLeft: state.secondsLeft - 1);
      }
    });
  }

  /// Жауап қабылдау: емтихан режимі — кері байланыссыз, бірден келесіге.
  Future<void> answer(int optionIndex) async {
    if (state.phase != ExamPhase.running) return;
    final answers = [...state.answers, optionIndex];
    if (answers.length >= state.questions.length) {
      state = state.copyWith(answers: answers);
      await finish();
    } else {
      state = state.copyWith(answers: answers, index: state.index + 1);
    }
  }

  /// Аяқтау (уақыт бітсе де шақырылады): бағалау, сақтау, шеберлік, XP.
  Future<void> finish() async {
    if (state.phase != ExamPhase.running) return;
    _timer?.cancel();
    final durationSec = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inSeconds;
    final attempt = scoreExam(
      subject: subject,
      grade: _grade,
      questions: state.questions,
      answers: state.answers,
      durationSec: durationSec,
    );
    state = state.copyWith(phase: ExamPhase.finished, attempt: attempt);

    // Қосалқы әсерлер экранды құлатпайды (офлайн-first қағидасы).
    try {
      final uid = _ref.read(authProvider).user?.id;
      if (uid != null) {
        await _ref.read(storageProvider).saveExamAttempt(uid, attempt);
      }
      await _ref.read(masteryProvider.notifier).recordSession([
        for (var i = 0; i < state.questions.length; i++)
          (
            questionId: state.questions[i].question.id,
            nodeId: state.questions[i].nodeId,
            correct: i < state.answers.length &&
                state.answers[i] == state.questions[i].question.correctIndex,
            difficulty: state.questions[i].question.difficulty,
          ),
      ]);
      if (attempt.correct > 0) {
        await _ref
            .read(gameProvider.notifier)
            .addXp(attempt.correct * ExamConfig.xpPerCorrect);
      }
    } catch (_) {}
  }

  /// Интроға қайтару («Қайта тапсыру»).
  void reset() {
    _timer?.cancel();
    state = const ExamState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final examProvider =
    StateNotifierProvider.autoDispose.family<ExamNotifier, ExamState, String>(
  (ref, subject) => ExamNotifier(ref, subject),
);

/// Пәннің сынақ тарихы (соңғысы бірінші); жаңа әрекеттен кейін жаңарады.
final examHistoryProvider =
    Provider.autoDispose.family<List<ExamAttempt>, String>((ref, subject) {
  ref.watch(examProvider(subject).select((s) => s.attempt?.id));
  final uid = ref.watch(authProvider.select((s) => s.user?.id));
  if (uid == null) return const [];
  try {
    return [
      for (final a in ref.read(storageProvider).getExamAttempts(uid))
        if (a.subject == subject) a,
    ];
  } catch (_) {
    return const [];
  }
});
