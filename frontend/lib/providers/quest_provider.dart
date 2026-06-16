import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests.dart';
import '../models/enums.dart';
import '../models/quest.dart';
import '../services/local_storage_service.dart';
import 'auth_provider.dart';
import 'game_provider.dart';

/// Бір күндік квест + прогресс жұбы.
class DailyQuest {
  const DailyQuest({required this.quest, required this.progress});

  final Quest quest;
  final QuestProgress progress;

  bool get isComplete => progress.progress >= quest.target;
  bool get canClaim => isComplete && !progress.claimed;
  double get fraction => (progress.progress / quest.target).clamp(0, 1).toDouble();
}

/// Күнделікті квесттер: дата бойынша пулдан 5 квест таңдалады,
/// прогресс Hive-та сақталады.
class QuestNotifier extends StateNotifier<List<DailyQuest>> {
  QuestNotifier(this._ref, this._storage, this._userId) : super(const []) {
    _loadToday();
  }

  static const _dailyCount = 5;

  final Ref _ref;
  final LocalStorageService _storage;
  final String? _userId;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _loadToday() {
    if (_userId == null) return;
    try {
      final saved = _storage.getDailyQuests(_userId, _todayKey);
      if (saved != null) {
        state = [
          for (final id in saved.questIds)
            if (QuestsData.byId(id) != null)
              DailyQuest(
                quest: QuestsData.byId(id)!,
                progress: saved.progress[id] ?? QuestProgress(questId: id),
              ),
        ];
        return;
      }
      // Жаңа күн — пулдан детерминистік таңдау.
      final random = Random('$_userId|$_todayKey'.hashCode);
      final pool = List<Quest>.from(QuestsData.pool)..shuffle(random);
      final picked = pool.take(_dailyCount).toList();
      state = [
        for (final q in picked)
          DailyQuest(quest: q, progress: QuestProgress(questId: q.id)),
      ];
      _save();
    } catch (_) {
      state = const [];
    }
  }

  Future<void> _save() async {
    if (_userId == null) return;
    await _storage.saveDailyQuests(
      _userId,
      _todayKey,
      state.map((d) => d.quest.id).toList(),
      {for (final d in state) d.quest.id: d.progress},
    );
  }

  /// Оқиға бойынша сәйкес квесттердің прогресін арттыру.
  Future<void> track(QuestType type, [int amount = 1]) async {
    var changed = false;
    state = [
      for (final d in state)
        if (d.quest.type == type && !d.progress.claimed && !d.isComplete)
          () {
            changed = true;
            return DailyQuest(
              quest: d.quest,
              progress: d.progress.copyWith(
                progress: min(d.progress.progress + amount, d.quest.target),
              ),
            );
          }()
        else
          d,
    ];
    if (changed) await _save();
  }

  /// Streak квесттері ағымдағы streak мәнімен тікелей жаңартылады.
  Future<void> syncStreak(int streak) async {
    var changed = false;
    state = [
      for (final d in state)
        if (d.quest.type == QuestType.streak && !d.progress.claimed)
          () {
            changed = true;
            return DailyQuest(
              quest: d.quest,
              progress: d.progress.copyWith(
                progress: min(streak, d.quest.target),
              ),
            );
          }()
        else
          d,
    ];
    if (changed) await _save();
  }

  /// Сыйлықты алу: марапаттар game_provider арқылы беріледі.
  Future<bool> claimReward(String questId) async {
    final index = state.indexWhere((d) => d.quest.id == questId);
    if (index == -1) return false;
    final daily = state[index];
    if (!daily.canClaim) return false;

    state = [
      for (final d in state)
        if (d.quest.id == questId)
          DailyQuest(
            quest: d.quest,
            progress: d.progress.copyWith(claimed: true),
          )
        else
          d,
    ];
    await _save();

    final game = _ref.read(gameProvider.notifier);
    if (daily.quest.coinReward > 0) await game.addCoins(daily.quest.coinReward);
    if (daily.quest.akylReward > 0) {
      await game.addAkylPoints(daily.quest.akylReward);
    }
    if (daily.quest.xpReward > 0) await game.addXp(daily.quest.xpReward);
    return true;
  }
}

final questProvider =
    StateNotifierProvider<QuestNotifier, List<DailyQuest>>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  return QuestNotifier(ref, ref.watch(storageProvider), userId);
});
