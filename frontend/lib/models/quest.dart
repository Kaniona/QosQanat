import 'enums.dart';

/// Күнделікті тапсырма (квест).
class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.type,
    required this.target,
    this.coinReward = 0,
    this.akylReward = 0,
    this.xpReward = 0,
    this.icon = '🎯',
  });

  final String id;
  final String title;
  final QuestType type;

  /// Мақсатқа жету саны (мыс. 3 тапсырма).
  final int target;
  final int coinReward;
  final int akylReward;
  final int xpReward;
  final String icon;
}

/// Күнделікті квесттің қолданушы прогресі.
class QuestProgress {
  const QuestProgress({
    required this.questId,
    this.progress = 0,
    this.claimed = false,
  });

  final String questId;
  final int progress;
  final bool claimed;

  QuestProgress copyWith({int? progress, bool? claimed}) => QuestProgress(
        questId: questId,
        progress: progress ?? this.progress,
        claimed: claimed ?? this.claimed,
      );

  Map<String, dynamic> toJson() => {
        'quest_id': questId,
        'progress': progress,
        'claimed': claimed,
      };

  factory QuestProgress.fromJson(Map<String, dynamic> json) => QuestProgress(
        questId: json['quest_id'] as String,
        progress: json['progress'] as int? ?? 0,
        claimed: json['claimed'] as bool? ?? false,
      );
}
