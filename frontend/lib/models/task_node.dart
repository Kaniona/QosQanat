import 'enums.dart';

/// Сәйкестендіру сұрағының бір жұбы (сол жақ ↔ оң жақ).
class MatchPair {
  const MatchPair(this.left, this.right);

  final String left;
  final String right;

  Map<String, dynamic> toJson() => {'left': left, 'right': right};

  factory MatchPair.fromJson(Map<String, dynamic> json) =>
      MatchPair(json['left'] as String, json['right'] as String);
}

/// Викторина сұрағы (4 формат: таңдау, дұрыс/бұрыс, бос орын, сәйкестендіру).
class Question {
  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.hint,
    this.type = QuestionType.multipleChoice,
    this.difficulty = Difficulty.easy,
    this.pairs = const [],
  });

  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;

  /// Қате жауапта көрсетілетін түсіндірме.
  final String? hint;

  final QuestionType type;
  final Difficulty difficulty;

  /// matchPairs форматы үшін жұптар (өзге форматтарда бос).
  final List<MatchPair> pairs;

  String get correctAnswer =>
      options.isEmpty ? '' : options[correctIndex];

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'correct_index': correctIndex,
        'hint': hint,
        'type': type.name,
        'difficulty': difficulty.name,
        'pairs': pairs.map((p) => p.toJson()).toList(),
      };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        text: json['text'] as String,
        options: List<String>.from(json['options'] as List),
        correctIndex: json['correct_index'] as int,
        hint: json['hint'] as String?,
        type: QuestionType.fromName(json['type'] as String?),
        difficulty: Difficulty.fromName(json['difficulty'] as String?),
        pairs: (json['pairs'] as List? ?? const [])
            .map((p) => MatchPair.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList(),
      );
}

/// Оқу картасының бір node-ы (сабақ / викторина / босс / қазына).
class TaskNode {
  const TaskNode({
    required this.id,
    required this.subject,
    required this.grade,
    required this.module,
    required this.moduleTitle,
    required this.indexInModule,
    required this.type,
    required this.title,
    required this.questions,
    this.requiredGrade = 1,
    this.xpReward = 30,
    this.coinReward = 10,
    this.akylReward = 5,
  });

  final String id;
  final String subject;
  final int grade;
  final int module;
  final String moduleTitle;
  final int indexInModule;
  final NodeType type;
  final String title;
  final List<Question> questions;
  final int requiredGrade;
  final int xpReward;
  final int coinReward;
  final int akylReward;
}

/// Node бойынша қолданушы прогресі (Hive-та сақталады).
class NodeProgress {
  const NodeProgress({
    required this.nodeId,
    this.status = NodeStatus.locked,
    this.stars = 0,
    this.bestScore = 0,
    this.completedAt,
  });

  final String nodeId;
  final NodeStatus status;

  /// 0-3 жұлдыз.
  final int stars;

  /// Үздік нәтиже, %.
  final int bestScore;
  final DateTime? completedAt;

  NodeProgress copyWith({
    NodeStatus? status,
    int? stars,
    int? bestScore,
    DateTime? completedAt,
  }) {
    return NodeProgress(
      nodeId: nodeId,
      status: status ?? this.status,
      stars: stars ?? this.stars,
      bestScore: bestScore ?? this.bestScore,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'node_id': nodeId,
        'status': status.name,
        'stars': stars,
        'best_score': bestScore,
        'completed_at': completedAt?.toIso8601String(),
      };

  factory NodeProgress.fromJson(Map<String, dynamic> json) => NodeProgress(
        nodeId: json['node_id'] as String,
        status: NodeStatus.fromName(json['status'] as String?),
        stars: json['stars'] as int? ?? 0,
        bestScore: json['best_score'] as int? ?? 0,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
      );
}
