import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/curriculum.dart';
import '../models/battle.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../services/local_storage_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'game_provider.dart';
import 'quest_provider.dart';

/// Батл ағымының күйі.
class BattleState {
  const BattleState({
    this.battle,
    this.currentIndex = 0,
    this.lastRound,
    this.finished = false,
    this.rewardCoins = 0,
    this.rewardAkyl = 0,
    this.rewardXp = 0,
  });

  final Battle? battle;
  final int currentIndex;

  /// Соңғы жауап берілген раунд (UI кері байланысы үшін).
  final BattleRound? lastRound;
  final bool finished;
  final int rewardCoins;
  final int rewardAkyl;
  final int rewardXp;

  BattleState copyWith({
    Battle? battle,
    int? currentIndex,
    BattleRound? lastRound,
    bool? finished,
    int? rewardCoins,
    int? rewardAkyl,
    int? rewardXp,
  }) {
    return BattleState(
      battle: battle ?? this.battle,
      currentIndex: currentIndex ?? this.currentIndex,
      lastRound: lastRound ?? this.lastRound,
      finished: finished ?? this.finished,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      rewardAkyl: rewardAkyl ?? this.rewardAkyl,
      rewardXp: rewardXp ?? this.rewardXp,
    );
  }
}

/// 1v1 батл. Offline режімде қарсыластың жауаптары қарсылас деңгейіне
/// байланысты детерминистік түрде имитацияланады (Random(battleId+index)).
class BattleNotifier extends StateNotifier<BattleState> {
  BattleNotifier(this._ref, this._storage, this._userId)
      : super(const BattleState());

  final Ref _ref;
  final LocalStorageService _storage;
  final String? _userId;

  /// Жаңа батл құру.
  Future<void> createBattle({
    required User opponent,
    required int questionCount,
    required String subject,
  }) async {
    if (_userId == null) return;
    final id = 'battle_${DateTime.now().millisecondsSinceEpoch}';
    final battle = Battle(
      id: id,
      challengerId: _userId,
      opponentId: opponent.id,
      opponentName: opponent.fullName,
      opponentLevel: opponent.level,
      subject: subject,
      questions: Curriculum.battleQuestions(
        subject: subject,
        count: questionCount,
        seed: id.hashCode,
        grade: _storage.getUser(_userId)?.grade ?? 7,
      ),
      createdAt: DateTime.now(),
    );
    state = BattleState(battle: battle);
    await _storage.saveBattle(battle);
  }

  /// Жауап беру (selected == null → уақыт бітті).
  /// Қарсыластың жауабы да осы сәтте «келеді».
  Future<void> submitAnswer(int? selected) async {
    final battle = state.battle;
    if (battle == null || state.finished) return;
    final index = state.currentIndex;
    if (index >= battle.questions.length) return;

    final question = battle.questions[index];
    final myCorrect = selected != null && selected == question.correctIndex;

    // Қарсылас имитациясы: дәлдік деңгейге байланысты 45-85%.
    final random = Random(battle.id.hashCode + index * 31);
    final accuracy = (0.45 + battle.opponentLevel * 0.013).clamp(0.45, 0.85);
    final oppCorrect = random.nextDouble() < accuracy;
    int oppAnswer;
    if (oppCorrect) {
      oppAnswer = question.correctIndex;
    } else {
      final wrong = List<int>.generate(question.options.length, (i) => i)
        ..remove(question.correctIndex);
      oppAnswer = wrong[random.nextInt(wrong.length)];
    }

    final round = BattleRound(
      questionIndex: index,
      myAnswer: selected,
      opponentAnswer: oppAnswer,
      myCorrect: myCorrect,
      opponentCorrect: oppCorrect,
    );

    final updated = battle.copyWith(
      rounds: [...battle.rounds, round],
      myScore: battle.myScore + (myCorrect ? 1 : 0),
      opponentScore: battle.opponentScore + (oppCorrect ? 1 : 0),
    );
    state = state.copyWith(
      battle: updated,
      currentIndex: index + 1,
      lastRound: round,
    );
    await _storage.saveBattle(updated);

    if (index + 1 >= battle.questions.length) {
      await _finish();
    }
  }

  Future<void> _finish() async {
    final battle = state.battle;
    if (battle == null || _userId == null) return;

    final result = battle.myScore > battle.opponentScore
        ? BattleResult.win
        : (battle.myScore < battle.opponentScore
            ? BattleResult.lose
            : BattleResult.draw);

    // Марапаттар: жеңіс — толық, жеңіліс — жұбаныш сыйлығы.
    final (coins, akyl, xp) = switch (result) {
      BattleResult.win => (50, 30, 40),
      BattleResult.draw => (25, 15, 20),
      _ => (10, 5, 10),
    };

    final finished = battle.copyWith(result: result);
    await _storage.saveBattle(finished);
    state = state.copyWith(
      battle: finished,
      finished: true,
      rewardCoins: coins,
      rewardAkyl: akyl,
      rewardXp: xp,
    );

    try {
      final game = _ref.read(gameProvider.notifier);
      await game.addCoins(coins);
      await game.addAkylPoints(akyl);
      await game.addXp(xp);

      final user = _storage.getUser(_userId);
      if (user != null) {
        final won = result == BattleResult.win;
        await _storage.saveUser(user.copyWith(
          battlesTotal: user.battlesTotal + 1,
          battlesWon: user.battlesWon + (won ? 1 : 0),
          winStreak: won ? user.winStreak + 1 : 0,
        ));
        _ref.read(authProvider.notifier).refreshUser();
      }

      final quests = _ref.read(questProvider.notifier);
      await quests.track(QuestType.battle);
      if (result == BattleResult.win) {
        await quests.track(QuestType.battleWin);
      }
      await _ref.read(achievementProvider.notifier).evaluate();
    } catch (_) {
      // Марапат қатесі батл нәтижесін бұзбауы керек.
    }
  }

  void reset() => state = const BattleState();
}

final battleProvider =
    StateNotifierProvider<BattleNotifier, BattleState>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  return BattleNotifier(ref, ref.watch(storageProvider), userId);
});

/// Қолданушының соңғы аяқталған батлдары (профильге).
/// Жартылай тасталған (pending) батлдар көрсетілмейді.
final recentBattlesProvider = Provider<List<Battle>>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  ref.watch(battleProvider); // жаңа батлдан кейін қайта есептеу
  if (userId == null) return const [];
  return ref
      .watch(storageProvider)
      .getBattlesForUser(userId)
      .where((b) => b.result != BattleResult.pending)
      .take(5)
      .toList();
});
