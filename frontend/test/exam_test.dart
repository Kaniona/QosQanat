import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/data/curriculum.dart';
import 'package:qosqanat/models/enums.dart';
import 'package:qosqanat/models/exam.dart';
import 'package:qosqanat/models/task_node.dart';
import 'package:qosqanat/providers/exam_provider.dart';

void main() {
  group('Байқау сынағын құрастыру', () {
    test('math g7: барлық тақырып қамтылады, формат жарамды', () {
      final qs = buildExamQuestions('math', 7, random: Random(1));
      expect(qs.length, greaterThanOrEqualTo(12));
      final modules = qs.map((q) => q.module).toSet();
      expect(
        modules,
        {for (var m = 1; m <= Curriculum.moduleCount('math', 7); m++) m},
        reason: 'әр тақырыптан кемінде бір сұрақ болуы тиіс',
      );
      for (final q in qs) {
        expect(q.question.type, isNot(QuestionType.matchPairs));
        expect(q.question.options, isNotEmpty);
        expect(
          q.question.correctIndex,
          inInclusiveRange(0, q.question.options.length - 1),
          reason: '«${q.question.text}» жауап индексі жарамсыз',
        );
        expect(q.moduleTitle, isNotEmpty);
      }
    });

    test('қиындық жеңілден қиынға өседі', () {
      final qs = buildExamQuestions('math', 8, random: Random(2));
      for (var i = 1; i < qs.length; i++) {
        expect(
          qs[i].question.difficulty.index,
          greaterThanOrEqualTo(qs[i - 1].question.difficulty.index),
        );
      }
    });

    test('бір сынақта сұрақ мәтіні қайталанбайды', () {
      final qs = buildExamQuestions('kazakh', 6, random: Random(3));
      final texts = qs.map((q) => q.question.text).toList();
      expect(texts.toSet().length, texts.length);
    });

    test('бірдей seed — бірдей сынақ (детерминизм)', () {
      List<String> ids(int seed) =>
          buildExamQuestions('physics', 9, random: Random(seed))
              .map((q) => q.question.id)
              .toList();
      expect(ids(7), ids(7));
    });

    test('барлық пән, 5–11 сынып: сынақ құрастырылады', () {
      for (final s in ['math', 'kazakh', 'english', 'physics', 'cs']) {
        for (var g = 5; g <= 11; g++) {
          final qs = buildExamQuestions(s, g, random: Random(g));
          expect(qs.length, greaterThanOrEqualTo(8), reason: '$s g$g');
        }
      }
    });
  });

  group('Бағалау мен тақырыптық талдау', () {
    ExamQuestion eq(String id, int module, int correctIndex) => ExamQuestion(
          question: Question(
            id: id,
            text: 'Сұрақ $id',
            options: const ['a', 'b', 'c'],
            correctIndex: correctIndex,
          ),
          nodeId: 'math_g5_m${module}_n0',
          module: module,
          moduleTitle: 'Тақырып $module',
        );

    test('дұрыс санау + модуль бөлінісі + пайыз', () {
      final questions = [
        eq('a', 1, 0),
        eq('b', 1, 1),
        eq('c', 2, 2),
        eq('d', 2, 0),
      ];
      final attempt = scoreExam(
        subject: 'math',
        grade: 5,
        questions: questions,
        answers: [0, 0, 2, null],
        durationSec: 100,
      );
      expect(attempt.correct, 2);
      expect(attempt.total, 4);
      expect(attempt.percent, 50);
      expect(attempt.modules.length, 2);
      expect(attempt.modules.first.module, 1);
      expect(attempt.modules.first.correct, 1);
      expect(attempt.modules.first.total, 2);
      expect(attempt.modules.last.correct, 1);
      expect(attempt.modules.last.total, 2);
    });

    test('жауап парағы қысқа болса (уақыт бітті) — қалғаны қате', () {
      final questions = [eq('a', 1, 0), eq('b', 1, 0), eq('c', 1, 0)];
      final attempt = scoreExam(
        subject: 'math',
        grade: 5,
        questions: questions,
        answers: [0],
        durationSec: 30,
      );
      expect(attempt.correct, 1);
      expect(attempt.total, 3);
      expect(attempt.modules.single.total, 3);
    });

    test('ExamAttempt JSON roundtrip (Hive сақтау форматы)', () {
      final attempt = ExamAttempt(
        id: '1751443200000',
        subject: 'math',
        grade: 7,
        date: DateTime(2026, 7, 2, 10, 30),
        correct: 14,
        total: 18,
        durationSec: 540,
        modules: const [
          ModuleScore(module: 1, title: 'Дәреже', correct: 2, total: 3),
          ModuleScore(module: 2, title: 'Теңдеулер', correct: 3, total: 3),
        ],
      );
      final round = ExamAttempt.fromJson(attempt.toJson());
      expect(round.id, attempt.id);
      expect(round.subject, attempt.subject);
      expect(round.grade, attempt.grade);
      expect(round.date, attempt.date);
      expect(round.correct, attempt.correct);
      expect(round.total, attempt.total);
      expect(round.durationSec, attempt.durationSec);
      expect(round.percent, 78);
      expect(round.modules.length, 2);
      expect(round.modules.first.title, 'Дәреже');
      expect(round.modules.first.accuracy, closeTo(2 / 3, 1e-9));
    });
  });
}
