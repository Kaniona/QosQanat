import '../core/constants/curriculum_data.dart';
import 'curriculum.dart';
import 'lessons/math_lessons.dart';

/// Анықтамалық жазба: бір сабақтың «ұстамасы» — формула + тірек қорытынды.
/// Сабақтардан АВТО-құрастырылады (жаңа контент жазылмайды): formula бар
/// әр сабақ — бір карта. lessonNodeId арқылы толық теорияға өтуге болады.
class RefEntry {
  const RefEntry({
    required this.subject,
    required this.grade,
    required this.module,
    required this.title,
    required this.formula,
    required this.takeaway,
    this.commonMistake,
  });

  final String subject;
  final int grade;
  final int module;
  final String title;
  final String formula;
  final String takeaway;
  final String? commonMistake;

  /// Толық теория сабағының node id-і (n0 — әрқашан сабақ).
  String get lessonNodeId => '${subject}_g${grade}_m${module}_n0';
}

/// Барлық пәннің анықтамалық жазбалары (пән → сынып → модуль ретімен).
/// ТАЗА функция: Curriculum.moduleCount пен lessonFor-дан құрастырылады,
/// сондықтан жаңа сабақ қосылса — анықтамалық өздігінен жаңарады.
List<RefEntry> buildReferenceEntries() {
  final entries = <RefEntry>[];
  for (final subject in CurriculumData.subjects) {
    for (var grade = 1; grade <= 11; grade++) {
      final moduleCount = Curriculum.moduleCount(subject.id, grade);
      for (var module = 1; module <= moduleCount; module++) {
        final lesson = lessonFor(subject.id, grade, module);
        final formula = lesson?.formula;
        if (lesson == null || formula == null || formula.isEmpty) continue;
        entries.add(RefEntry(
          subject: subject.id,
          grade: grade,
          module: module,
          title: lesson.title,
          formula: formula,
          takeaway: lesson.takeaway,
          commonMistake: lesson.commonMistake,
        ));
      }
    }
  }
  return entries;
}

/// Іздеу мен пән сүзгісі — ТАЗА функция (экран осыны шақырады).
/// [query] бос болса — тек пән сүзгісі; әйтпесе тақырып/формула/қорытынды
/// мәтінінен регистрсіз ізделеді.
List<RefEntry> filterReferenceEntries(
  List<RefEntry> entries, {
  String? subject,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  return [
    for (final e in entries)
      if ((subject == null || e.subject == subject) &&
          (q.isEmpty ||
              e.title.toLowerCase().contains(q) ||
              e.formula.toLowerCase().contains(q) ||
              e.takeaway.toLowerCase().contains(q)))
        e,
  ];
}
