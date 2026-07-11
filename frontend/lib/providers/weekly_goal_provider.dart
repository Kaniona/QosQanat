import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'daily_challenge_provider.dart' show dailyDateKey;
import 'game_provider.dart';

/// Апталық мақсат деңгейлері: (XP мақсаты, атау кілті UI-да AppStrings-тен).
const List<int> weeklyGoalTiers = [150, 300, 600];

/// Апта кілті — аптаның ДҮЙСЕНБІСІНІҢ күні ('yyyy-MM-dd'): апта ауысқанын
/// салыстыруға жеткілікті әрі адамға оқылады. ТАЗА функция.
String weekKey(DateTime d) =>
    dailyDateKey(d.subtract(Duration(days: d.weekday - 1)));

/// Апталық XP жинағын жаңарту — ТАЗА функция. [raw] — 'weekKey|xp' немесе
/// null; апта сәйкес келсе қосады, ауысса нөлден бастайды.
String bumpWeeklyRaw(String? raw, String wk, int by) {
  var current = 0;
  if (raw != null) {
    final parts = raw.split('|');
    if (parts.length == 2 && parts[0] == wk) {
      current = int.tryParse(parts[1]) ?? 0;
    }
  }
  return '$wk|${current + by}';
}

/// Осы аптада жиналған XP — ТАЗА функция (апта ауысса 0).
int weeklyEarned(String? raw, String wk) {
  if (raw == null) return 0;
  final parts = raw.split('|');
  if (parts.length != 2 || parts[0] != wk) return 0;
  return int.tryParse(parts[1]) ?? 0;
}

/// Апталық мақсат күйі: қойылған мақсат (жоқ болса null) + осы аптаның XP-і.
/// XP өзгерген сайын қайта оқылады (gameProvider.xp бақыланады).
typedef WeeklyGoalState = ({int? goal, int earned});

final weeklyGoalProvider = Provider.autoDispose<WeeklyGoalState>((ref) {
  ref.watch(gameProvider.select((g) => g.xp));
  final uid = ref.watch(authProvider.select((s) => s.user?.id));
  if (uid == null) return (goal: null, earned: 0);
  try {
    final storage = ref.read(storageProvider);
    return (
      goal: storage.getWeeklyGoal(uid),
      earned: weeklyEarned(storage.getWeeklyXp(uid), weekKey(DateTime.now())),
    );
  } catch (_) {
    return (goal: null, earned: 0);
  }
});
