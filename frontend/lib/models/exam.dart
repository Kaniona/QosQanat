import 'task_node.dart';

/// Байқау сынағының бір сұрағы: сұрақ + шыққан тақырыбы
/// (нәтиже талдауы мен шеберлік движогіне азық).
class ExamQuestion {
  const ExamQuestion({
    required this.question,
    required this.nodeId,
    required this.module,
    required this.moduleTitle,
  });

  final Question question;
  final String nodeId;
  final int module;
  final String moduleTitle;
}

/// Бір тақырып (модуль) бойынша сынақ нәтижесі.
class ModuleScore {
  const ModuleScore({
    required this.module,
    required this.title,
    required this.correct,
    required this.total,
  });

  final int module;
  final String title;
  final int correct;
  final int total;

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {
        'module': module,
        'title': title,
        'correct': correct,
        'total': total,
      };

  factory ModuleScore.fromJson(Map<String, dynamic> json) => ModuleScore(
        module: json['module'] as int,
        title: json['title'] as String? ?? '',
        correct: json['correct'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );
}

/// Аяқталған байқау сынағы (тарихта сақталады, Hive).
class ExamAttempt {
  const ExamAttempt({
    required this.id,
    required this.subject,
    required this.grade,
    required this.date,
    required this.correct,
    required this.total,
    required this.durationSec,
    required this.modules,
  });

  /// millisecondsSinceEpoch — уақыт бойынша сұрыптауға жарамды кілт.
  final String id;
  final String subject;
  final int grade;
  final DateTime date;
  final int correct;
  final int total;

  /// Жұмсалған уақыт (секунд).
  final int durationSec;

  /// Тақырып бойынша талдау (module ретімен).
  final List<ModuleScore> modules;

  int get percent => total == 0 ? 0 : (correct * 100 / total).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'grade': grade,
        'date': date.toIso8601String(),
        'correct': correct,
        'total': total,
        'duration_sec': durationSec,
        'modules': modules.map((m) => m.toJson()).toList(),
      };

  factory ExamAttempt.fromJson(Map<String, dynamic> json) => ExamAttempt(
        id: json['id'] as String,
        subject: json['subject'] as String,
        grade: json['grade'] as int? ?? 1,
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        correct: json['correct'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        durationSec: json['duration_sec'] as int? ?? 0,
        modules: [
          for (final m in json['modules'] as List? ?? const [])
            ModuleScore.fromJson(Map<String, dynamic>.from(m as Map)),
        ],
      );
}
