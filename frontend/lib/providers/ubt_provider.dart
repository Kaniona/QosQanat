import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/curriculum_data.dart';
import '../data/curriculum.dart';
import '../models/enums.dart';
import '../models/exam.dart';
import '../models/task_node.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'game_provider.dart';
import 'mastery_provider.dart';

/// ҰБТ дайындық сынағының параметрлері. ТЕК қосымшада бар пәндер:
/// міндетті блок — Қазақстан тарихы, математика (мат. сауаттылық),
/// қазақ тілі (оқу сауаттылығы); профиль — қалған пәндерден 2-уі.
abstract final class UbtConfig {
  /// Міндетті блок пәндері (ҰБТ ретімен).
  static const List<String> mandatorySubjects = ['history', 'math', 'kazakh'];

  /// Профильге таңдауға болатын пәндер (қосымшада барлары ғана).
  static const List<String> profileChoices = [
    'physics', 'cs', 'biology', 'chemistry', 'english',
  ];

  /// Таңдалатын профиль пәндерінің саны.
  static const int profileCount = 2;

  /// Міндетті пән блогындағы сұрақ саны.
  static const int perMandatory = 10;

  /// Профиль пән блогындағы сұрақ саны.
  static const int perProfile = 15;

  /// Бір сұраққа берілетін уақыт (жалпы таймер = сұрақ саны × осы).
  static const int secondsPerQuestion = 60;

  /// Осы дәлдіктен төмен пән/тақырып «күшейту керек» деп белгіленеді.
  static const double weakThreshold = .6;

  /// Бір дұрыс жауаптың XP марапаты.
  static const int xpPerCorrect = 4;

  /// Сынақтағы жалпы сұрақ саны.
  static int get totalQuestions =>
      mandatorySubjects.length * perMandatory + profileCount * perProfile;

  /// ҰБТ тарихының Hive-тағы «пән» кілті (ExamAttempt.subject).
  static const String attemptSubject = 'ubt';
}

/// ҰБТ сынағының бір сұрағы: пәні қоса жүреді (блоктық ағын мен
/// пәндік талдау үшін).
class UbtQuestion {
  const UbtQuestion({
    required this.subject,
    required this.question,
    required this.nodeId,
    required this.module,
    required this.moduleTitle,
  });

  final String subject;
  final Question question;
  final String nodeId;
  final int module;
  final String moduleTitle;
}

/// Бір пәннің ҰБТ сұрақтарын құрастыру — ТАЗА функция.
/// Дереккөз: пәннің ЕКІ сыныбы (өткен + ағымдағы) — ҰБТ өткен материалды
/// да қамтитынына сай. Инварианттар: сәйкестендіру кірмейді; мәтін
/// қайталанбайды; қиындық жеңілден қиынға өседі; тақырыптар «жолақпен»
/// тең қамтылады (buildExamQuestions үлгісі).
List<UbtQuestion> buildUbtSubjectQuestions(
  String subject,
  int grade,
  int count, {
  Random? random,
}) {
  final rnd = random ?? Random();
  final grades = <int>{(grade - 1).clamp(1, 11), grade.clamp(1, 11)};

  final usedTexts = <String>{};
  final pool = <UbtQuestion>[];
  for (final g in grades) {
    for (final node in Curriculum.nodesForGrade(subject, g)) {
      for (final q in node.questions) {
        if (q.type == QuestionType.matchPairs || q.options.isEmpty) continue;
        if (!usedTexts.add(q.text)) continue;
        pool.add(UbtQuestion(
          subject: subject,
          question: q,
          nodeId: node.id,
          module: node.module,
          moduleTitle: node.moduleTitle,
        ));
      }
    }
  }
  if (pool.isEmpty) return const [];

  pool.sort((a, b) =>
      a.question.difficulty.index.compareTo(b.question.difficulty.index));

  // Қиындық «жолақтарына» бөліп, әрқайсысынан 1 кездейсоқ сұрақ —
  // блок іші жеңілден қиынға тең қамтылады.
  final n = min(count, pool.length);
  final base = pool.length ~/ n;
  final rem = pool.length % n;
  final picked = <UbtQuestion>[];
  var start = 0;
  for (var band = 0; band < n; band++) {
    final size = base + (band < rem ? 1 : 0);
    picked.add(pool[start + rnd.nextInt(size)]);
    start += size;
  }
  // Пул жұқа болса (n == pool.length) band іріктеуі детерминистік болып
  // қалады — бір деңгей ішіндегі ретті араластырып, қиындық қисығын
  // қайта орнатамыз: әр қайталауда түрленеді, «жеңілден қиынға» сақталады.
  picked.shuffle(rnd);
  picked.sort((a, b) =>
      a.question.difficulty.index.compareTo(b.question.difficulty.index));
  return picked;
}

/// Толық ҰБТ сынағын құрастыру — ТАЗА функция. Блок реті: міндетті 3 пән,
/// сосын таңдалған 2 профиль пәні; әр блок ішінде қиындық өседі.
List<UbtQuestion> buildUbtQuestions(
  List<String> profileSubjects,
  int grade, {
  Random? random,
}) {
  final rnd = random ?? Random();
  final questions = <UbtQuestion>[];
  for (final s in UbtConfig.mandatorySubjects) {
    questions.addAll(
        buildUbtSubjectQuestions(s, grade, UbtConfig.perMandatory,
            random: rnd));
  }
  for (final s in profileSubjects.take(UbtConfig.profileCount)) {
    questions.addAll(
        buildUbtSubjectQuestions(s, grade, UbtConfig.perProfile, random: rnd));
  }
  return questions;
}

/// Жауап парағын бағалау — ТАЗА функция. Пән блоктары [ModuleScore]
/// ретінде жазылады (module = блок реті, title = пән атауы) — бар
/// ExamAttempt/Hive құрылымы өзгеріссіз қайта пайдаланылады.
ExamAttempt scoreUbt({
  required int grade,
  required List<UbtQuestion> questions,
  required List<int?> answers,
  required int durationSec,
  DateTime? date,
}) {
  var correct = 0;
  final order = <String>[];
  final correctBySubject = <String, int>{};
  final totalBySubject = <String, int>{};
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    final ok = i < answers.length && answers[i] == q.question.correctIndex;
    if (ok) correct++;
    if (!order.contains(q.subject)) order.add(q.subject);
    correctBySubject[q.subject] =
        (correctBySubject[q.subject] ?? 0) + (ok ? 1 : 0);
    totalBySubject[q.subject] = (totalBySubject[q.subject] ?? 0) + 1;
  }
  final now = date ?? DateTime.now();
  return ExamAttempt(
    id: '${now.millisecondsSinceEpoch}',
    subject: UbtConfig.attemptSubject,
    grade: grade,
    date: now,
    correct: correct,
    total: questions.length,
    durationSec: durationSec,
    modules: [
      for (var b = 0; b < order.length; b++)
        ModuleScore(
          module: b + 1,
          title: CurriculumData.subjectById(order[b]).title,
          correct: correctBySubject[order[b]] ?? 0,
          total: totalBySubject[order[b]] ?? 0,
        ),
    ],
  );
}

/// Әлсіз тақырып сілтемесі: пән + сынып + модуль (теория сабағына жол).
class UbtWeakTopic {
  const UbtWeakTopic({
    required this.subject,
    required this.grade,
    required this.module,
    required this.title,
  });

  final String subject;
  final int grade;
  final int module;
  final String title;

  /// Тақырыптың теория сабағының node id-і.
  String get lessonNodeId => '${subject}_g${grade}_m${module}_n0';
}

/// Дәлдігі [UbtConfig.weakThreshold]-тан төмен тақырыптар — ТАЗА функция
/// (нәтиже экранындағы «теорияны қайтала» сілтемелері).
List<UbtWeakTopic> ubtWeakTopics(
  List<UbtQuestion> questions,
  List<int?> answers,
) {
  final correctByKey = <String, int>{};
  final totalByKey = <String, int>{};
  final meta = <String, UbtWeakTopic>{};
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    // nodeId пішімі: subject_gX_mY_nZ → сынып id-ден оқылады.
    final gradePart = q.nodeId.split('_').firstWhere(
          (p) => p.startsWith('g') && int.tryParse(p.substring(1)) != null,
          orElse: () => 'g0',
        );
    final grade = int.parse(gradePart.substring(1));
    final key = '${q.subject}|$grade|${q.module}';
    meta[key] ??= UbtWeakTopic(
      subject: q.subject,
      grade: grade,
      module: q.module,
      title: q.moduleTitle,
    );
    final ok = i < answers.length && answers[i] == q.question.correctIndex;
    correctByKey[key] = (correctByKey[key] ?? 0) + (ok ? 1 : 0);
    totalByKey[key] = (totalByKey[key] ?? 0) + 1;
  }
  final weak = <UbtWeakTopic>[];
  for (final key in meta.keys) {
    final total = totalByKey[key] ?? 0;
    if (total < 2) continue; // 1 сұрақтан қорытынды жасалмайды
    final accuracy = (correctByKey[key] ?? 0) / total;
    if (accuracy < UbtConfig.weakThreshold) weak.add(meta[key]!);
  }
  return weak;
}

/// Дайындық индексі — ТАЗА функция: соңғы 3 ҰБТ әрекетінің пән-блок
/// дәлдіктерінің салмақты орташасы (жаңасы салмақтырақ: 3/2/1).
/// Кілт — пән атауы (ModuleScore.title), мәні — 0..1 үлес.
Map<String, double> ubtReadiness(List<ExamAttempt> attempts) {
  final sums = <String, double>{};
  final weights = <String, double>{};
  var w = 3.0;
  for (final a in attempts.take(3)) {
    for (final m in a.modules) {
      if (m.total == 0) continue;
      sums[m.title] = (sums[m.title] ?? 0) + m.accuracy * w;
      weights[m.title] = (weights[m.title] ?? 0) + w;
    }
    w -= 1;
  }
  return {for (final k in sums.keys) k: sums[k]! / weights[k]!};
}

/// Сынақ фазасы: профиль таңдау/ережелер → сұрақтар → нәтиже.
enum UbtPhase { intro, running, finished }

/// ҰБТ сынағының ағымдағы күйі (экран осыдан оқиды).
class UbtState {
  const UbtState({
    this.phase = UbtPhase.intro,
    this.profile = const [],
    this.questions = const [],
    this.index = 0,
    this.answers = const [],
    this.secondsLeft = 0,
    this.attempt,
    this.weakTopics = const [],
  });

  final UbtPhase phase;

  /// Таңдалған профиль пәндері (интро экранында жиналады).
  final List<String> profile;

  final List<UbtQuestion> questions;
  final int index;
  final List<int?> answers;
  final int secondsLeft;

  /// Аяқталған сынақтың нәтижесі (phase == finished болғанда).
  final ExamAttempt? attempt;

  /// Әлсіз тақырыптар — finish() кезінде ЕСЕПТЕЛІП қойылады (виджет
  /// build-інде бизнес-логика болмауы үшін).
  final List<UbtWeakTopic> weakTopics;

  /// Ағымдағы сұрақтың пәні мен блок ішіндегі орны («Тарих · 3/10»).
  (String subject, int at, int of) get blockProgress {
    if (questions.isEmpty) return ('', 0, 0);
    final subject = questions[index].subject;
    var at = 0;
    var of = 0;
    for (var i = 0; i < questions.length; i++) {
      if (questions[i].subject != subject) continue;
      of++;
      if (i <= index) at++;
    }
    return (subject, at, of);
  }

  UbtState copyWith({
    UbtPhase? phase,
    List<String>? profile,
    List<UbtQuestion>? questions,
    int? index,
    List<int?>? answers,
    int? secondsLeft,
    ExamAttempt? attempt,
    List<UbtWeakTopic>? weakTopics,
  }) {
    return UbtState(
      phase: phase ?? this.phase,
      profile: profile ?? this.profile,
      questions: questions ?? this.questions,
      index: index ?? this.index,
      answers: answers ?? this.answers,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      attempt: attempt ?? this.attempt,
      weakTopics: weakTopics ?? this.weakTopics,
    );
  }
}

/// ҰБТ сынағы: профиль таңдау, таймер, жауап қабылдау, аяқтау (сақтау +
/// шеберлік движогіне азық + XP).
class UbtNotifier extends StateNotifier<UbtState> {
  UbtNotifier(this._ref) : super(const UbtState());

  final Ref _ref;
  Timer? _timer;
  DateTime? _startedAt;

  int get _grade => (_ref.read(authProvider).user?.grade ?? 10).clamp(1, 11);

  /// Профиль пәнін таңдау/алып тастау (интро фазасында).
  void toggleProfile(String subject) {
    if (state.phase != UbtPhase.intro) return;
    final profile = List<String>.from(state.profile);
    if (profile.contains(subject)) {
      profile.remove(subject);
    } else {
      if (profile.length >= UbtConfig.profileCount) return;
      profile.add(subject);
    }
    state = state.copyWith(profile: profile);
  }

  /// Сынақты бастау: блоктар құрастырылып, таймер қосылады.
  void start() {
    if (state.profile.length != UbtConfig.profileCount) return;
    final questions = buildUbtQuestions(state.profile, _grade);
    if (questions.isEmpty) return;
    _timer?.cancel();
    _startedAt = DateTime.now();
    state = UbtState(
      phase: UbtPhase.running,
      profile: state.profile,
      questions: questions,
      secondsLeft: questions.length * UbtConfig.secondsPerQuestion,
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
    if (state.phase != UbtPhase.running) return;
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
    if (state.phase != UbtPhase.running) return;
    _timer?.cancel();
    final durationSec = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inSeconds;
    final attempt = scoreUbt(
      grade: _grade,
      questions: state.questions,
      answers: state.answers,
      durationSec: durationSec,
    );
    state = state.copyWith(
      phase: UbtPhase.finished,
      attempt: attempt,
      weakTopics: ubtWeakTopics(state.questions, state.answers),
    );

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
            .addXp(attempt.correct * UbtConfig.xpPerCorrect);
      }
      await _ref.read(achievementProvider.notifier).unlock('ach_first_ubt');
      if (attempt.percent >= 80) {
        await _ref
            .read(achievementProvider.notifier)
            .unlock('ach_ubt_master');
      }
    } catch (_) {}
  }

  /// Интроға қайтару («Қайта тапсыру») — профиль таңдауы сақталады.
  void reset() {
    _timer?.cancel();
    state = UbtState(profile: state.profile);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final ubtProvider = StateNotifierProvider.autoDispose<UbtNotifier, UbtState>(
  (ref) => UbtNotifier(ref),
);

/// ҰБТ сынақтарының тарихы (соңғысы бірінші); жаңа әрекеттен кейін жаңарады.
final ubtHistoryProvider = Provider.autoDispose<List<ExamAttempt>>((ref) {
  ref.watch(ubtProvider.select((s) => s.attempt?.id));
  final uid = ref.watch(authProvider.select((s) => s.user?.id));
  if (uid == null) return const [];
  try {
    return [
      for (final a in ref.read(storageProvider).getExamAttempts(uid))
        if (a.subject == UbtConfig.attemptSubject) a,
    ];
  } catch (_) {
    return const [];
  }
});
