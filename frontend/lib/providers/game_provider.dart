import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage_service.dart';
import 'auth_provider.dart';
import 'weekly_goal_provider.dart' show bumpWeeklyRaw, weekKey;

/// Геймификация күйі: деңгей, XP, монета, ақыл, streak.
class GameState {
  const GameState({
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.akylPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.pendingLevelUp,
  });

  final int level;

  /// Жалпы жинақталған XP.
  final int xp;
  final int coins;
  final int akylPoints;
  final int currentStreak;
  final int longestStreak;

  /// UI көрсетпеген жаңа деңгей (level-up модалы үшін).
  final int? pendingLevelUp;

  /// L деңгейіне жету үшін қажет жалпы XP: 50·L·(L−1).
  static int xpToReach(int level) => 50 * level * (level - 1);

  static int levelFromXp(int xp) {
    var level = 1;
    while (level < 100 && xp >= xpToReach(level + 1)) {
      level++;
    }
    return level;
  }

  int get xpIntoLevel => xp - xpToReach(level);

  int get xpForNextLevel =>
      level >= 100 ? 0 : xpToReach(level + 1) - xpToReach(level);

  double get levelProgress =>
      xpForNextLevel == 0 ? 1 : (xpIntoLevel / xpForNextLevel).clamp(0, 1).toDouble();

  GameState copyWith({
    int? level,
    int? xp,
    int? coins,
    int? akylPoints,
    int? currentStreak,
    int? longestStreak,
    int? pendingLevelUp,
    bool clearLevelUp = false,
  }) {
    return GameState(
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      akylPoints: akylPoints ?? this.akylPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      pendingLevelUp:
          clearLevelUp ? null : (pendingLevelUp ?? this.pendingLevelUp),
    );
  }
}

/// Ойын циклін басқарады; әр өзгерісті Hive-тағы қолданушыға жазады.
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier(this._ref, this._storage, String? userId)
      : _userId = userId,
        super(const GameState()) {
    _load();
  }

  final Ref _ref;
  final LocalStorageService _storage;
  final String? _userId;

  void _load() {
    if (_userId == null) return;
    final user = _storage.getUser(_userId);
    if (user == null) return;
    state = GameState(
      level: GameState.levelFromXp(user.xp),
      xp: user.xp,
      coins: user.coins,
      akylPoints: user.akylPoints,
      currentStreak: user.currentStreak,
      longestStreak: user.longestStreak,
    );
  }

  Future<void> _persist() async {
    if (_userId == null) return;
    try {
      final user = _storage.getUser(_userId);
      if (user == null) return;
      await _storage.saveUser(user.copyWith(
        level: state.level,
        xp: state.xp,
        coins: state.coins,
        akylPoints: state.akylPoints,
        currentStreak: state.currentStreak,
        longestStreak: state.longestStreak,
      ));
      _ref.read(authProvider.notifier).refreshUser();
    } catch (_) {
      // Сақтау қатесі ойынды тоқтатпауы керек.
    }
  }

  /// XP қосу; деңгей көтерілсе pendingLevelUp орнатылады.
  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    final newXp = state.xp + amount;
    final newLevel = GameState.levelFromXp(newXp);
    final leveledUp = newLevel > state.level;
    state = state.copyWith(
      xp: newXp,
      level: newLevel,
      pendingLevelUp: leveledUp ? newLevel : null,
    );
    await _persist();
    // Апталық мақсатқа жинақтау (v2.1) — қатесі ойынды тоқтатпайды.
    try {
      final uid = _ref.read(authProvider).user?.id;
      if (uid != null) {
        final storage = _ref.read(storageProvider);
        final wk = weekKey(DateTime.now());
        await storage.setWeeklyXp(
            uid, bumpWeeklyRaw(storage.getWeeklyXp(uid), wk, amount));
      }
    } catch (_) {}
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    state = state.copyWith(coins: state.coins + amount);
    await _persist();
  }

  Future<void> addAkylPoints(int amount) async {
    if (amount <= 0) return;
    state = state.copyWith(akylPoints: state.akylPoints + amount);
    await _persist();
  }

  /// Монета жұмсау; жетіспесе false.
  Future<bool> spendCoins(int amount) async {
    if (amount > state.coins) return false;
    state = state.copyWith(coins: state.coins - amount);
    await _persist();
    return true;
  }

  /// Күнделікті streak тексерісі: қатарынан кірсе +1,
  /// 1 күн өткізіп алса 1-ден қайта басталады.
  Future<void> checkStreak() async {
    if (_userId == null) return;
    final user = _storage.getUser(_userId);
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = user.lastLoginDate;
    final lastDay =
        last == null ? null : DateTime(last.year, last.month, last.day);

    int streak;
    if (lastDay == null) {
      streak = 1;
    } else {
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        streak = user.currentStreak == 0 ? 1 : user.currentStreak;
      } else if (diff == 1) {
        streak = user.currentStreak + 1;
      } else {
        streak = 1;
      }
    }
    final longest =
        streak > user.longestStreak ? streak : user.longestStreak;

    final dayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final activity = List<String>.from(user.activityDays);
    if (!activity.contains(dayKey)) activity.add(dayKey);

    await _storage.saveUser(user.copyWith(
      currentStreak: streak,
      longestStreak: longest,
      lastLoginDate: now,
      activityDays: activity,
    ));
    state = state.copyWith(currentStreak: streak, longestStreak: longest);

    // Streak межелік сыйлығы: 3+ күн сайын бонус монета.
    if (streak >= 3 && streak != user.currentStreak && streak % 3 == 0) {
      await addCoins(streak * 5);
    }
    _ref.read(authProvider.notifier).refreshUser();
  }

  /// Level-up модалы көрсетілгеннен кейін шақырылады.
  void consumeLevelUp() {
    state = state.copyWith(clearLevelUp: true);
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  return GameNotifier(ref, ref.watch(storageProvider), userId);
});
