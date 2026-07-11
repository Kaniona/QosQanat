import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/models/enums.dart';
import 'package:qosqanat/models/task_node.dart';
import 'package:qosqanat/providers/ubt_provider.dart';

void main() {
  group('ҰБТ сынағын құрастыру (таза функциялар)', () {
    test('блок реті мен саны: міндетті 3 пән + таңдалған 2 профиль', () {
      final qs = buildUbtQuestions(['physics', 'cs'], 11, random: Random(42));
      expect(qs.length, UbtConfig.totalQuestions);

      // Блоктар тізбектеле жүреді: history → math → kazakh → physics → cs.
      final order = <String>[];
      for (final q in qs) {
        if (order.isEmpty || order.last != q.subject) order.add(q.subject);
      }
      expect(order, ['history', 'math', 'kazakh', 'physics', 'cs']);

      for (final s in UbtConfig.mandatorySubjects) {
        expect(qs.where((q) => q.subject == s).length, UbtConfig.perMandatory,
            reason: '$s блогы');
      }
      for (final s in ['physics', 'cs']) {
        expect(qs.where((q) => q.subject == s).length, UbtConfig.perProfile,
            reason: '$s блогы');
      }
    });

    test('барлық профиль жұптары үшін құрастырылады (10 және 11 сынып)', () {
      for (final grade in [10, 11]) {
        for (var i = 0; i < UbtConfig.profileChoices.length; i++) {
          for (var j = i + 1; j < UbtConfig.profileChoices.length; j++) {
            final profile = [
              UbtConfig.profileChoices[i],
              UbtConfig.profileChoices[j],
            ];
            final qs = buildUbtQuestions(profile, grade,
                random: Random(grade + i + j));
            expect(qs.length, UbtConfig.totalQuestions,
                reason: 'g$grade $profile');
          }
        }
      }
    });

    test('сәйкестендіру кірмейді, блок ішінде мәтін қайталанбайды', () {
      final qs = buildUbtQuestions(['biology', 'english'], 10,
          random: Random(7));
      final seenPerSubject = <String, Set<String>>{};
      for (final q in qs) {
        expect(q.question.type == QuestionType.matchPairs, isFalse,
            reason: 'емтихан қарқынына сәйкестендіру сай емес');
        expect(q.question.options, isNotEmpty);
        final seen = seenPerSubject.putIfAbsent(q.subject, () => {});
        expect(seen.add(q.question.text), isTrue,
            reason: '${q.subject}: «${q.question.text}» қайталанды');
      }
    });

    test('блок ішінде қиындық кемімейді (жеңілден қиынға)', () {
      final qs = buildUbtQuestions(['chemistry', 'cs'], 11, random: Random(3));
      String? current;
      var last = 0;
      for (final q in qs) {
        if (q.subject != current) {
          current = q.subject;
          last = 0;
        }
        expect(q.question.difficulty.index, greaterThanOrEqualTo(last),
            reason: '${q.subject} блогында қиындық кері кетті');
        last = q.question.difficulty.index;
      }
    });

    test('сұрақтар оқушының 2 сыныбынан ғана (өткен + ағымдағы)', () {
      final qs = buildUbtQuestions(['physics', 'cs'], 10, random: Random(1));
      for (final q in qs) {
        expect(q.nodeId, matches(RegExp('_g(9|10)_')),
            reason: '${q.nodeId} 9–10 сыныптан тыс');
      }
    });

    test('buildUbtSubjectQuestions сұралған санды береді', () {
      final qs =
          buildUbtSubjectQuestions('history', 11, 12, random: Random(5));
      expect(qs.length, 12);
      expect(qs.every((q) => q.subject == 'history'), isTrue);
    });
  });

  group('ҰБТ бағалау мен талдау', () {
    UbtQuestion uq(String subject, int module, int correctIndex) =>
        UbtQuestion(
          subject: subject,
          question: Question(
            id: '$subject-$module-$correctIndex',
            text: 'Сұрақ $subject $module $correctIndex',
            options: const ['a', 'b', 'c'],
            correctIndex: correctIndex,
          ),
          nodeId: '${subject}_g10_m${module}_n0',
          module: module,
          moduleTitle: 'Тақырып $module',
        );

    test('scoreUbt: пән блоктары мен жалпы ұпай дұрыс', () {
      final questions = [
        uq('history', 1, 0),
        uq('history', 1, 1),
        uq('math', 1, 2),
        uq('math', 2, 0),
      ];
      final attempt = scoreUbt(
        grade: 10,
        questions: questions,
        answers: [0, 0, 2, 1], // дұрыс, қате, дұрыс, қате
        durationSec: 90,
      );
      expect(attempt.subject, UbtConfig.attemptSubject);
      expect(attempt.correct, 2);
      expect(attempt.total, 4);
      expect(attempt.percent, 50);
      expect(attempt.modules.length, 2);
      expect(attempt.modules.first.title, 'Қазақстан тарихы');
      expect(attempt.modules.first.correct, 1);
      expect(attempt.modules.first.total, 2);
      expect(attempt.modules.last.title, 'Математика');
      expect(attempt.modules.last.correct, 1);
    });

    test('жауап жетпесе (уақыт бітті) — қате саналады', () {
      final questions = [uq('history', 1, 0), uq('history', 1, 1)];
      final attempt = scoreUbt(
        grade: 11,
        questions: questions,
        answers: [0], // екіншісіне жауап жоқ
        durationSec: 600,
      );
      expect(attempt.correct, 1);
      expect(attempt.total, 2);
    });

    test('ubtWeakTopics: әлсіз тақырып теория сілтемесімен табылады', () {
      final questions = [
        // 1-модуль: 0/2 — әлсіз.
        uq('history', 1, 0),
        uq('history', 1, 0),
        // 2-модуль: 2/2 — мықты.
        uq('history', 2, 1),
        uq('history', 2, 1),
        // math 1-модуль: 1 ғана сұрақ — қорытынды жасалмайды.
        uq('math', 1, 0),
      ];
      final weak = ubtWeakTopics(questions, [1, 1, 1, 1, 1]);
      expect(weak.length, 1);
      expect(weak.single.subject, 'history');
      expect(weak.single.module, 1);
      expect(weak.single.lessonNodeId, 'history_g10_m1_n0');
    });
  });
}
