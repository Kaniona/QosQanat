import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/curriculum.dart';
import '../models/task_node.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'game_provider.dart';

/// Күнделікті марафон (v2) параметрлері: күніне БІР рет, аралас пәндерден
/// [questionCount] сұрақ; seed — күнтізбелік күн, сондықтан бір күні барлық
/// қолданушыға бірдей жиынтық түседі (адал жарыс), ертең — жаңасы.
abstract final class DailyConfig {
  static const int questionCount = 10;
  static const int xpPerCorrect = 6;
  static const int perfectBonus = 40;
  static const int coinsPerCorrect = 2;
}

/// Күн кілті — 'yyyy-MM-dd' (сақтау мен салыстыру үшін). ТАЗА функция.
String dailyDateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Күннің детерминистік seed-і. ТАЗА функция.
int dailySeed(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

/// Бүгінгі марафон сұрақтары — ТАЗА функция (күнге детерминистік,
/// оқушының сыныбына сай, барлық пәннен аралас).
List<Question> buildDailyQuestions(int grade, DateTime date) =>
    Curriculum.battleQuestions(
      count: DailyConfig.questionCount,
      seed: dailySeed(date),
      grade: grade,
    );

/// Марапат есебі — ТАЗА функция: (xp, coins).
(int, int) dailyReward(int correct, int total) => (
      correct * DailyConfig.xpPerCorrect +
          (total > 0 && correct == total ? DailyConfig.perfectBonus : 0),
      correct * DailyConfig.coinsPerCorrect,
    );

/// Марафон фазасы: дайын → жүріп жатыр → бітті (бүгінге жабық).
enum DailyPhase { ready, running, done }

/// Марафон күйі (экран мен үй картасы осыдан оқиды).
class DailyState {
  const DailyState({
    this.phase = DailyPhase.ready,
    this.questions = const [],
    this.index = 0,
    this.correct = 0,
    this.todayScore,
  });

  final DailyPhase phase;
  final List<Question> questions;
  final int index;
  final int correct;

  /// Бүгін аяқталған марафонның ұпайы (жоқ болса — әлі тапсырылмаған).
  final int? todayScore;

  DailyState copyWith({
    DailyPhase? phase,
    List<Question>? questions,
    int? index,
    int? correct,
    int? todayScore,
  }) {
    return DailyState(
      phase: phase ?? this.phase,
      questions: questions ?? this.questions,
      index: index ?? this.index,
      correct: correct ?? this.correct,
      todayScore: todayScore ?? this.todayScore,
    );
  }
}

/// Күнделікті марафон: бүгінгі күйді оқу, өту, марапаттау, жабу.
class DailyChallengeNotifier extends StateNotifier<DailyState> {
  DailyChallengeNotifier(this._ref) : super(const DailyState()) {
    _load();
  }

  final Ref _ref;

  int get _grade => (_ref.read(authProvider).user?.grade ?? 7).clamp(1, 11);
  String? get _uid => _ref.read(authProvider).user?.id;

  /// Бүгінгі күйді оқу: бүгін тапсырылса — done + ұпай.
  void _load() {
    try {
      final uid = _uid;
      if (uid == null) return;
      final raw = _ref.read(storageProvider).getDailyQuizResult(uid);
      if (raw == null) return;
      final parts = raw.split('|');
      if (parts.length != 2) return;
      if (parts[0] != dailyDateKey(DateTime.now())) return;
      state = DailyState(
        phase: DailyPhase.done,
        todayScore: int.tryParse(parts[1]),
      );
    } catch (_) {}
  }

  /// Марафонды бастау (бүгін тапсырылмаған болса ғана).
  void start() {
    if (state.phase == DailyPhase.done) return;
    final questions = buildDailyQuestions(_grade, DateTime.now());
    if (questions.isEmpty) return;
    state = DailyState(phase: DailyPhase.running, questions: questions);
  }

  /// Жауап қабылдау: соңғы сұрақтан кейін аяқталады.
  Future<void> answer(int optionIndex) async {
    if (state.phase != DailyPhase.running) return;
    final q = state.questions[state.index];
    final correct =
        state.correct + (optionIndex == q.correctIndex ? 1 : 0);
    if (state.index + 1 >= state.questions.length) {
      await _finish(correct);
    } else {
      state = state.copyWith(index: state.index + 1, correct: correct);
    }
  }

  /// Аяқтау: нәтижені сақтау (бүгінге жабу) + XP/монета марапаты.
  Future<void> _finish(int correct) async {
    final total = state.questions.length;
    state = state.copyWith(
      phase: DailyPhase.done,
      correct: correct,
      todayScore: correct,
    );
    // Қосалқы әсерлер экранды құлатпайды (офлайн-first қағидасы).
    try {
      final uid = _uid;
      if (uid != null) {
        await _ref.read(storageProvider).setDailyQuizResult(
              uid,
              '${dailyDateKey(DateTime.now())}|$correct',
            );
      }
      final (xp, coins) = dailyReward(correct, total);
      if (xp > 0) await _ref.read(gameProvider.notifier).addXp(xp);
      if (coins > 0) await _ref.read(gameProvider.notifier).addCoins(coins);
      if (total > 0 && correct == total) {
        await _ref
            .read(achievementProvider.notifier)
            .unlock('ach_daily_perfect');
      }
    } catch (_) {}
  }
}

final dailyChallengeProvider =
    StateNotifierProvider.autoDispose<DailyChallengeNotifier, DailyState>(
  (ref) => DailyChallengeNotifier(ref),
);
