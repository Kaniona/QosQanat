import 'enums.dart';
import 'task_node.dart';

/// Батлдағы бір сұрақтың раунд нәтижесі.
class BattleRound {
  const BattleRound({
    required this.questionIndex,
    this.myAnswer,
    this.opponentAnswer,
    this.myCorrect = false,
    this.opponentCorrect = false,
  });

  final int questionIndex;
  final int? myAnswer;
  final int? opponentAnswer;
  final bool myCorrect;
  final bool opponentCorrect;

  Map<String, dynamic> toJson() => {
        'question_index': questionIndex,
        'my_answer': myAnswer,
        'opponent_answer': opponentAnswer,
        'my_correct': myCorrect,
        'opponent_correct': opponentCorrect,
      };

  factory BattleRound.fromJson(Map<String, dynamic> json) => BattleRound(
        questionIndex: json['question_index'] as int,
        myAnswer: json['my_answer'] as int?,
        opponentAnswer: json['opponent_answer'] as int?,
        myCorrect: json['my_correct'] as bool? ?? false,
        opponentCorrect: json['opponent_correct'] as bool? ?? false,
      );
}

/// 1v1 батл деректері. Offline режімде қарсылас жауаптары
/// детерминистік түрде имитацияланады.
class Battle {
  const Battle({
    required this.id,
    required this.challengerId,
    required this.opponentId,
    required this.opponentName,
    required this.opponentLevel,
    required this.subject,
    required this.questions,
    this.rounds = const [],
    this.myScore = 0,
    this.opponentScore = 0,
    this.result = BattleResult.pending,
    required this.createdAt,
  });

  final String id;
  final String challengerId;
  final String opponentId;
  final String opponentName;
  final int opponentLevel;

  /// Пән фильтрі ('all' = барлығы).
  final String subject;
  final List<Question> questions;
  final List<BattleRound> rounds;
  final int myScore;
  final int opponentScore;
  final BattleResult result;
  final DateTime createdAt;

  Battle copyWith({
    List<BattleRound>? rounds,
    int? myScore,
    int? opponentScore,
    BattleResult? result,
  }) {
    return Battle(
      id: id,
      challengerId: challengerId,
      opponentId: opponentId,
      opponentName: opponentName,
      opponentLevel: opponentLevel,
      subject: subject,
      questions: questions,
      rounds: rounds ?? this.rounds,
      myScore: myScore ?? this.myScore,
      opponentScore: opponentScore ?? this.opponentScore,
      result: result ?? this.result,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'challenger_id': challengerId,
        'opponent_id': opponentId,
        'opponent_name': opponentName,
        'opponent_level': opponentLevel,
        'subject': subject,
        'questions': questions.map((q) => q.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'my_score': myScore,
        'opponent_score': opponentScore,
        'result': result.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory Battle.fromJson(Map<String, dynamic> json) => Battle(
        id: json['id'] as String,
        challengerId: json['challenger_id'] as String,
        opponentId: json['opponent_id'] as String,
        opponentName: json['opponent_name'] as String? ?? '',
        opponentLevel: json['opponent_level'] as int? ?? 1,
        subject: json['subject'] as String? ?? 'all',
        questions: (json['questions'] as List? ?? [])
            .map((q) => Question.fromJson(Map<String, dynamic>.from(q as Map)))
            .toList(),
        rounds: (json['rounds'] as List? ?? [])
            .map((r) =>
                BattleRound.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
        myScore: json['my_score'] as int? ?? 0,
        opponentScore: json['opponent_score'] as int? ?? 0,
        result: BattleResult.fromName(json['result'] as String?),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
