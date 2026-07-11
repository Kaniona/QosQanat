import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/data/lessons/math_lessons.dart';
import 'package:qosqanat/models/lesson.dart';

void main() {
  group('Сабақтар (теория)', () {
    test('5–11 сыныптың әр математика модулінде сабақ бар', () {
      for (var g = 5; g <= 11; g++) {
        for (var m = 1; m <= 6; m++) {
          expect(lessonFor('math', g, m), isNotNull,
              reason: 'g$g m$m сабағы жоқ');
        }
      }
    });

    test('5–11 сыныптың әр пәнінде барлық модульге сабақ бар', () {
      for (final entry in _modulesPerSubject.entries) {
        for (var g = 5; g <= 11; g++) {
          for (var m = 1; m <= entry.value; m++) {
            expect(lessonFor(entry.key, g, m), isNotNull,
                reason: '${entry.key} g$g m$m сабағы жоқ');
          }
        }
      }
    });

    test('сабақ толық: hook, идея, қадамдар, формула, үлгі, тірек бар', () {
      for (var g = 5; g <= 11; g++) {
        for (var m = 1; m <= 6; m++) {
          _expectComplete(lessonFor('math', g, m)!, 'math g$g m$m');
        }
      }
      for (final entry in _modulesPerSubject.entries) {
        for (var g = 5; g <= 11; g++) {
          for (var m = 1; m <= entry.value; m++) {
            _expectComplete(lessonFor(entry.key, g, m)!, '${entry.key} g$g m$m');
          }
        }
      }
    });

    test('әр үлгі есептің жауабы нұсқалардың ішінде бар (интерактив дұрыс)', () {
      void check(String subject, int g, int m) {
        final lesson = lessonFor(subject, g, m)!;
        for (final ex in lesson.examples) {
          expect(ex.steps, isNotEmpty,
              reason: '$subject g$g m$m «${ex.problem}» қадамсыз');
          if (ex.choices.isNotEmpty) {
            expect(ex.choices.contains(ex.answer), isTrue,
                reason: '$subject g$g m$m «${ex.problem}»: жауабы нұсқаларда жоқ');
          }
        }
      }

      for (var g = 5; g <= 11; g++) {
        for (var m = 1; m <= 6; m++) {
          check('math', g, m);
        }
      }
      for (final entry in _modulesPerSubject.entries) {
        for (var g = 5; g <= 11; g++) {
          for (var m = 1; m <= entry.value; m++) {
            check(entry.key, g, m);
          }
        }
      }
    });
  });
}

/// Пән → 5–11 сыныптағы модуль (сабақ) саны. Тарих пен информатика жаңа
/// тақырыптармен 4 модульге кеңейді; қалғандары — 2.
const _modulesPerSubject = {
  'kazakh': 2,
  'english': 2,
  'physics': 2,
  'cs': 4,
  'biology': 2,
  'chemistry': 2,
  'history': 4,
};

void _expectComplete(Lesson lesson, String where) {
  expect(lesson.hook, isNotNull, reason: '$where hook (өмірден кіріспе)');
  expect(lesson.hook!.length, greaterThan(20), reason: '$where hook қысқа');
  expect(lesson.intro.length, greaterThan(20), reason: '$where intro');
  expect(lesson.explainSteps.length, greaterThanOrEqualTo(2),
      reason: '$where explainSteps (қадамдық түсіндірме)');
  expect(lesson.formula, isNotNull, reason: '$where formula');
  expect(lesson.examples, isNotEmpty, reason: '$where examples');
  expect(lesson.takeaway, isNotEmpty, reason: '$where takeaway');
}
