/// Оқушы/мұғалім «қате» деп белгілеген сұрақ — контент сапасын (zero-errors)
/// үздіксіз жақсартуға арналған craudsourced QA жазбасы.
class FlaggedQuestion {
  const FlaggedQuestion({
    required this.questionId,
    required this.nodeId,
    required this.text,
    required this.reason,
    required this.byUserId,
    required this.createdAt,
  });

  final String questionId;
  final String nodeId;
  final String text;

  /// Себеп (мыс. «Жауабы қате», «Түсініксіз», «Қайталанады»).
  final String reason;
  final String byUserId;
  final DateTime createdAt;

  /// Сақтау кілті (бір сұраққа бір белгі — соңғысы қалады).
  String get id => questionId;

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'node_id': nodeId,
        'text': text,
        'reason': reason,
        'by_user_id': byUserId,
        'created_at': createdAt.toIso8601String(),
      };

  factory FlaggedQuestion.fromJson(Map<String, dynamic> json) =>
      FlaggedQuestion(
        questionId: json['question_id'] as String? ?? '',
        nodeId: json['node_id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        byUserId: json['by_user_id'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
