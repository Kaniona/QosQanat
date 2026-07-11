/// Бейімделетін оқыту дерек қабаты — қосымша әр оқушыны «таниды».
///
/// Прогресс бұған дейін тек node деңгейінде сақталатын (жұлдыз/ұпай). Мұнда екі
/// жұқа сигнал қосылады:
///  - [SkillStat] — ТАҚЫРЫП (subject+grade+module) бойынша қазіргі шеберлік (EMA).
///  - [ReviewItem] — қате жіберілген СҰРАҚТЫ интервалды қайталау кезегі (SM-2-lite).
/// Бәрі офлайн (Hive), толық локаль. Деректі жасапты компьютер емес, баланың
/// нақты жауаптары қалыптастырады.
library;

import 'enums.dart';

/// Тақырып (skill) идентификаторы — node id-дің префиксімен бірдей:
/// `math_g7_m3`. Бір модуль = бір тақырып = бір шеберлік бірлігі.
String skillIdFor(String subject, int grade, int module) =>
    '${subject}_g${grade}_m$module';

/// node id-ден тақырып id-ін шығару: `math_g7_m3_n2` → `math_g7_m3`.
String? skillIdFromNode(String nodeId) {
  final i = nodeId.indexOf('_n');
  return i == -1 ? null : nodeId.substring(0, i);
}

/// Тақырыпты меңгеру деңгейі (UI түсі мен мәтіні осыдан оқылады).
enum MasteryLevel {
  fresh, // Жаңа — әлі жаттықпаған
  learning, // Үйренуде — қате көп / деректі аз
  proven, // Бекіді — сенімді
  mastered; // Шебер — толық меңгерген

  String get label => switch (this) {
        MasteryLevel.fresh => 'Жаңа',
        MasteryLevel.learning => 'Үйренуде',
        MasteryLevel.proven => 'Бекіді',
        MasteryLevel.mastered => 'Шебер',
      };

  /// 0..3 — heatmap/сұрыптау үшін.
  int get rank => index;
}

/// Соңғы жауаптарға салмақ беретін EMA коэффициенті (жуықтап «жадының» жылдамдығы).
const double _emaAlpha = 0.4;

/// Бір ТАҚЫРЫП бойынша оқушының қазіргі шеберлігі.
class SkillStat {
  const SkillStat({
    required this.skillId,
    required this.subject,
    required this.grade,
    required this.module,
    this.attempts = 0,
    this.correct = 0,
    this.ema = 0,
    this.lastPracticed,
  });

  final String skillId;
  final String subject;
  final int grade;
  final int module;

  /// Жалпы жауап саны (барлық сессиялар).
  final int attempts;

  /// Дұрыс жауап саны.
  final int correct;

  /// Экспоненциалды орташа дәлдік (0..1) — соңғы жауаптарға салмақты.
  final double ema;

  final DateTime? lastPracticed;

  factory SkillStat.initial(
          String subject, int grade, int module) =>
      SkillStat(
        skillId: skillIdFor(subject, grade, module),
        subject: subject,
        grade: grade,
        module: module,
      );

  /// Жалпы дәлдік (барлық уақыт).
  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  /// Қазіргі меңгеру деңгейі (EMA + деректің жеткіліктілігі).
  MasteryLevel get level {
    if (attempts == 0) return MasteryLevel.fresh;
    if (attempts < 2) return MasteryLevel.learning;
    if (ema >= 0.85 && attempts >= 4) return MasteryLevel.mastered;
    if (ema >= 0.6) return MasteryLevel.proven;
    return MasteryLevel.learning;
  }

  /// Әлсіз тұс па (қайталау/жаттығу қажет ететін, бірақ жаттыққан тақырып).
  bool get isWeak =>
      attempts > 0 &&
      (level == MasteryLevel.learning ||
          (level == MasteryLevel.proven && ema < 0.7));

  /// Бір жауапты тіркеп, жаңартылған көшірмесін қайтарады.
  SkillStat record(bool isCorrect, {DateTime? at}) {
    final v = isCorrect ? 1.0 : 0.0;
    final newEma = attempts == 0 ? v : ema * (1 - _emaAlpha) + v * _emaAlpha;
    return SkillStat(
      skillId: skillId,
      subject: subject,
      grade: grade,
      module: module,
      attempts: attempts + 1,
      correct: correct + (isCorrect ? 1 : 0),
      ema: newEma,
      lastPracticed: at ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'skill_id': skillId,
        'subject': subject,
        'grade': grade,
        'module': module,
        'attempts': attempts,
        'correct': correct,
        'ema': ema,
        'last_practiced': lastPracticed?.toIso8601String(),
      };

  factory SkillStat.fromJson(Map<String, dynamic> json) => SkillStat(
        skillId: json['skill_id'] as String,
        subject: json['subject'] as String,
        grade: json['grade'] as int,
        module: json['module'] as int,
        attempts: json['attempts'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
        ema: (json['ema'] as num?)?.toDouble() ?? 0,
        lastPracticed: json['last_practiced'] != null
            ? DateTime.tryParse(json['last_practiced'] as String)
            : null,
      );
}

/// Қате жіберілген (немесе бекіп үлгермеген) бір СҰРАҚТЫҢ қайталау жазбасы.
/// SM-2 алгоритмінің жеңіл нұсқасы: дұрыс жауап интервалды ұзартады, қате —
/// сұрақты бүгінге қайта әкеледі.
class ReviewItem {
  const ReviewItem({
    required this.questionId,
    required this.nodeId,
    required this.skillId,
    required this.difficulty,
    required this.dueAt,
    this.reps = 0,
    this.intervalDays = 0,
    this.ease = 2.3,
    this.lapses = 0,
  });

  final String questionId;
  final String nodeId;
  final String skillId;
  final Difficulty difficulty;

  /// Қашан қайталауға тиіс.
  final DateTime dueAt;

  /// Қатарынан дұрыс жауап саны.
  final int reps;
  final double intervalDays;
  final double ease;

  /// Қанша рет қайта қателесті.
  final int lapses;

  /// Жаңа қайта қарау жазбасы — алғаш қате жауаптан кейін (бүгін қайта сұралады).
  factory ReviewItem.create(
    String questionId,
    String nodeId,
    String skillId,
    Difficulty difficulty, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    return ReviewItem(
      questionId: questionId,
      nodeId: nodeId,
      skillId: skillId,
      difficulty: difficulty,
      dueAt: n,
      lapses: 1,
    );
  }

  bool isDue(DateTime now) => !dueAt.isAfter(now);

  /// Толық бекіді (кезектен шығаруға болады).
  bool get graduated => reps >= 3 && intervalDays >= 21;

  /// Жауапқа қарай келесі мерзімді есептейді.
  ReviewItem schedule(bool isCorrect, {DateTime? now}) {
    final n = now ?? DateTime.now();
    if (!isCorrect) {
      return ReviewItem(
        questionId: questionId,
        nodeId: nodeId,
        skillId: skillId,
        difficulty: difficulty,
        dueAt: n, // дереу қайта сұралады
        reps: 0,
        intervalDays: 0,
        ease: (ease - 0.2).clamp(1.3, 2.8),
        lapses: lapses + 1,
      );
    }
    final newReps = reps + 1;
    final newInterval = switch (newReps) {
      1 => 1.0,
      2 => 3.0,
      _ => (intervalDays <= 0 ? 3.0 : intervalDays) * ease,
    };
    return ReviewItem(
      questionId: questionId,
      nodeId: nodeId,
      skillId: skillId,
      difficulty: difficulty,
      dueAt: n.add(Duration(days: newInterval.round())),
      reps: newReps,
      intervalDays: newInterval,
      ease: (ease + 0.1).clamp(1.3, 2.8),
      lapses: lapses,
    );
  }

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'node_id': nodeId,
        'skill_id': skillId,
        'difficulty': difficulty.name,
        'due_at': dueAt.toIso8601String(),
        'reps': reps,
        'interval_days': intervalDays,
        'ease': ease,
        'lapses': lapses,
      };

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        questionId: json['question_id'] as String,
        nodeId: json['node_id'] as String,
        skillId: json['skill_id'] as String,
        difficulty: Difficulty.fromName(json['difficulty'] as String?),
        dueAt: DateTime.tryParse(json['due_at'] as String? ?? '') ??
            DateTime.now(),
        reps: json['reps'] as int? ?? 0,
        intervalDays: (json['interval_days'] as num?)?.toDouble() ?? 0,
        ease: (json['ease'] as num?)?.toDouble() ?? 2.3,
        lapses: json['lapses'] as int? ?? 0,
      );
}

/// Ұстаз/ата-ана берген тапсырма: бір оқушыға бір тақырыпты жаттығу.
/// Оқушы сол тақырыпты «Бекіді» деңгейіне жеткізгенде өзі жабылады.
class Assignment {
  const Assignment({
    required this.studentId,
    required this.subject,
    required this.grade,
    required this.module,
    required this.createdAt,
  });

  final String studentId;
  final String subject;
  final int grade;
  final int module;
  final DateTime createdAt;

  String get skillId => skillIdFor(subject, grade, module);

  /// Сақтау кілті (бір оқушыға бір тақырып — біреу ғана).
  String get id => '$studentId|$skillId';

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'subject': subject,
        'grade': grade,
        'module': module,
        'created_at': createdAt.toIso8601String(),
      };

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        studentId: json['student_id'] as String,
        subject: json['subject'] as String,
        grade: json['grade'] as int,
        module: json['module'] as int,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
