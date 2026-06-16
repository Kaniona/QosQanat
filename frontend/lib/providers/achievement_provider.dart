import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/achievements.dart';
import '../models/achievement.dart';
import '../models/enums.dart';
import '../services/local_storage_service.dart';
import 'auth_provider.dart';
import 'game_provider.dart';

class AchievementState {
  const AchievementState({
    this.unlockedIds = const {},
    this.pendingToasts = const [],
  });

  final Set<String> unlockedIds;

  /// UI әлі көрсетпеген жаңа жетістіктер кезегі.
  final List<Achievement> pendingToasts;

  AchievementState copyWith({
    Set<String>? unlockedIds,
    List<Achievement>? pendingToasts,
  }) {
    return AchievementState(
      unlockedIds: unlockedIds ?? this.unlockedIds,
      pendingToasts: pendingToasts ?? this.pendingToasts,
    );
  }
}

/// Жетістіктерді шарт бойынша ашу + хабарландыру кезегі.
class AchievementNotifier extends StateNotifier<AchievementState> {
  AchievementNotifier(this._ref, this._storage, this._userId)
      : super(const AchievementState()) {
    _load();
  }

  final Ref _ref;
  final LocalStorageService _storage;
  final String? _userId;

  void _load() {
    if (_userId == null) return;
    final user = _storage.getUser(_userId);
    if (user == null) return;
    state = AchievementState(unlockedIds: user.unlockedAchievements.toSet());
  }

  /// Қолданушының ағымдағы статистикасына қарап барлық шарттарды тексеру.
  Future<void> evaluate() async {
    if (_userId == null) return;
    try {
      final user = _storage.getUser(_userId);
      if (user == null) return;
      final game = _ref.read(gameProvider);
      final hour = DateTime.now().hour;
      final friendCount = _friendCount();

      final newlyUnlocked = <Achievement>[];
      for (final ach in AchievementsData.all) {
        if (state.unlockedIds.contains(ach.id)) continue;
        final met = switch (ach.id) {
          'ach_first_task' => user.tasksCompleted >= 1,
          'ach_tasks_10' => user.tasksCompleted >= 10,
          'ach_tasks_50' => user.tasksCompleted >= 50,
          'ach_tasks_100' => user.tasksCompleted >= 100,
          'ach_tasks_300' => user.tasksCompleted >= 300,
          'ach_level_5' => game.level >= 5,
          'ach_level_10' => game.level >= 10,
          'ach_level_25' => game.level >= 25,
          'ach_level_50' => game.level >= 50,
          'ach_level_100' => game.level >= 100,
          'ach_first_battle' => user.battlesTotal >= 1,
          'ach_battle_win' => user.battlesWon >= 1,
          'ach_battles_10' => user.battlesTotal >= 10,
          'ach_battles_50' => user.battlesTotal >= 50,
          'ach_wins_10' => user.battlesWon >= 10,
          'ach_wins_25' => user.battlesWon >= 25,
          'ach_win_streak_3' => user.winStreak >= 3,
          'ach_perfect_10' => user.perfectTasks >= 10,
          'ach_boss_5' => user.bossesDefeated >= 5,
          'ach_first_friend' => friendCount >= 1,
          'ach_friends_5' => friendCount >= 5,
          'ach_friends_10' => friendCount >= 10,
          'ach_first_purchase' => user.purchasedItems.isNotEmpty,
          'ach_items_5' => user.purchasedItems.length >= 5,
          'ach_items_15' => user.purchasedItems.length >= 15,
          'ach_first_pet' =>
            user.purchasedItems.any((id) => id.startsWith('pet_')),
          'ach_legendary' => user.purchasedItems.any((id) =>
              id == 'top_armor_gold' ||
              id == 'top_cosmonaut' ||
              id == 'bottom_pants_ninja' ||
              id == 'hat_crown_gold' ||
              id == 'hat_helmet_space' ||
              id == 'acc_cape_hero' ||
              id == 'acc_shield_oyu' ||
              id == 'pet_snow_leopard' ||
              id == 'pet_dragon'),
          'ach_coins_5000' => game.coins >= 5000,
          'ach_streak_3' => user.currentStreak >= 3,
          'ach_streak_7' => user.currentStreak >= 7,
          'ach_streak_30' => user.currentStreak >= 30,
          'ach_streak_100' => user.currentStreak >= 100,
          'ach_early_bird' => hour < 7 && user.tasksCompleted >= 1,
          'ach_night_owl' => hour >= 23 && user.tasksCompleted >= 1,
          _ => false,
        };
        if (met) newlyUnlocked.add(ach);
      }

      if (newlyUnlocked.isEmpty) return;

      final ids = {...state.unlockedIds, ...newlyUnlocked.map((a) => a.id)};
      await _storage.saveUser(
        user.copyWith(unlockedAchievements: ids.toList()),
      );
      state = state.copyWith(
        unlockedIds: ids,
        pendingToasts: [...state.pendingToasts, ...newlyUnlocked],
      );

      // Жетістік марапаттары.
      final gameNotifier = _ref.read(gameProvider.notifier);
      for (final ach in newlyUnlocked) {
        if (ach.coinReward > 0) await gameNotifier.addCoins(ach.coinReward);
        if (ach.akylReward > 0) {
          await gameNotifier.addAkylPoints(ach.akylReward);
        }
      }
      _ref.read(authProvider.notifier).refreshUser();
    } catch (_) {
      // Жетістік тексерісі ойынды бұзбауы керек.
    }
  }

  /// Қабылданған дос өтінімдерінің саны (екі бағытта да).
  int _friendCount() {
    if (_userId == null) return 0;
    final ids = <String>{};
    for (final r in _storage.getAllFriendRequests()) {
      if (r.status != FriendRequestStatus.accepted) continue;
      if (r.fromUserId == _userId) ids.add(r.toUserId);
      if (r.toUserId == _userId) ids.add(r.fromUserId);
    }
    return ids.length;
  }

  /// Арнайы жетістікті тікелей ашу (мыс. турнирге қатысу).
  Future<void> unlock(String id) async {
    if (_userId == null || state.unlockedIds.contains(id)) return;
    final ach = AchievementsData.byId(id);
    if (ach == null) return;
    final user = _storage.getUser(_userId);
    if (user == null) return;

    final ids = {...state.unlockedIds, id};
    await _storage.saveUser(user.copyWith(unlockedAchievements: ids.toList()));
    state = state.copyWith(
      unlockedIds: ids,
      pendingToasts: [...state.pendingToasts, ach],
    );
    final game = _ref.read(gameProvider.notifier);
    if (ach.coinReward > 0) await game.addCoins(ach.coinReward);
    if (ach.akylReward > 0) await game.addAkylPoints(ach.akylReward);
    _ref.read(authProvider.notifier).refreshUser();
  }

  /// Toast көрсетілген соң кезектен алу.
  void consumeToast() {
    if (state.pendingToasts.isEmpty) return;
    state = state.copyWith(pendingToasts: state.pendingToasts.sublist(1));
  }
}

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  return AchievementNotifier(ref, ref.watch(storageProvider), userId);
});
