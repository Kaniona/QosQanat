import 'enums.dart';

/// Жетістік медалі.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.coinReward = 0,
    this.akylReward = 0,
    this.targetValue = 1,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementCategory category;
  final int coinReward;
  final int akylReward;

  /// Ашылу шартының сандық мәні (мыс. 100 тапсырма).
  final int targetValue;
}
