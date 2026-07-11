import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/data/banks/english_gen.dart';
import 'package:qosqanat/data/banks/kazakh_gen.dart';
import 'package:qosqanat/data/curriculum.dart';
import 'package:qosqanat/models/enums.dart';

void main() {
  group('Тіл генераторлары — валидтілік', () {
    test('қазақ/ағылшын генераторы 4 бірегей нұсқа, дұрыс индекс береді', () {
      final r = Random(42);
      for (var i = 0; i < 800; i++) {
        for (final d in Difficulty.values) {
          for (final gen in [kazakhGenQuestion, englishGenQuestion]) {
            final q = gen('g$i', 7, r, d);
            expect(q.options.length, 4, reason: q.text);
            expect(q.options.toSet().length, 4,
                reason: 'нұсқалар қайталанбауы керек: ${q.text}');
            expect(q.correctIndex, inInclusiveRange(0, 3), reason: q.text);
            expect(q.options[q.correctIndex], isNotEmpty, reason: q.text);
            expect(q.difficulty, d);
          }
        }
      }
    });
  });

  group('Тіл пәндерінің пулы байыды', () {
    test('қазақ/ағылшын node-ында 6 деңгей де бар (генератор тиерлерімен)', () {
      for (final subject in ['kazakh', 'english']) {
        for (final grade in [6, 8, 11]) {
          for (final node in Curriculum.nodesForGrade(subject, grade)) {
            final levels = node.questions.map((q) => q.difficulty).toSet();
            expect(levels.length, Difficulty.values.length,
                reason: '$subject g$grade ${node.id}: 6 деңгей толық емес');
          }
        }
      }
    });

    test('node пулында сұрақ мәтіні қайталанбайды (сессия дубликатсыз)', () {
      // Регрессия: бұрын (1) генератор тиері бірдей мәтінді екі рет бере
      // алатын, (2) банк жолында light пен easy бір тізімді басынан қайта
      // оқып, пулға кепілді дубликат түсетін.
      for (final (s, g) in [
        ('english', 8),
        ('kazakh', 7),
        ('physics', 6),
        ('cs', 7),
        ('math', 2),
      ]) {
        final node = Curriculum.nodesForGrade(s, g).first;
        final texts = node.questions
            .where((q) => q.type != QuestionType.matchPairs)
            .map((q) => q.text)
            .toList();
        expect(texts.toSet().length, texts.length,
            reason: '$s g$g ${node.id}: пулда дубликат бар');
      }
    });

    test('генератор сессияда қайталанбайтын мазмұн береді (бір тиерде)', () {
      // Бір node сессиясында light сұрақтары мәтіні бойынша бірегей.
      final node = Curriculum.nodesForGrade('english', 8).first;
      final session = Curriculum.sessionQuestions(node);
      final lightTexts = session
          .where((q) => q.difficulty == Difficulty.light)
          .map((q) => q.text)
          .toList();
      expect(lightTexts.length, lightTexts.toSet().length,
          reason: 'сессияда бірдей light сұрақ қайталанбауы тиіс');
    });
  });
}
