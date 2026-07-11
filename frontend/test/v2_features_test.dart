import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/data/lessons/math_lessons.dart';
import 'package:qosqanat/data/reference.dart';
import 'package:qosqanat/models/exam.dart';
import 'package:qosqanat/providers/daily_challenge_provider.dart';
import 'package:qosqanat/providers/ubt_provider.dart';
import 'package:qosqanat/providers/weekly_goal_provider.dart';

void main() {
  group('v2: Формулалар анықтамалығы', () {
    final entries = buildReferenceEntries();

    test('барлық пәннен жазба бар және формулалар бос емес', () {
      const subjects = [
        'math', 'kazakh', 'english', 'physics', 'cs', 'biology',
        'chemistry', 'history',
      ];
      for (final s in subjects) {
        expect(entries.any((e) => e.subject == s), isTrue,
            reason: '$s пәнінен жазба жоқ');
      }
      for (final e in entries) {
        expect(e.formula, isNotEmpty, reason: e.title);
        expect(e.takeaway, isNotEmpty, reason: e.title);
      }
      expect(entries.length, greaterThanOrEqualTo(150));
    });

    test('әр жазба нақты сабаққа сілтейді', () {
      for (final e in entries) {
        expect(lessonFor(e.subject, e.grade, e.module), isNotNull,
            reason: e.lessonNodeId);
      }
    });

    test('сүзгі: пән + іздеу дұрыс жұмыс істейді', () {
      final math = filterReferenceEntries(entries, subject: 'math');
      expect(math, isNotEmpty);
      expect(math.every((e) => e.subject == 'math'), isTrue);

      final pifagor = filterReferenceEntries(entries, query: 'Пифагор');
      expect(pifagor, isNotEmpty);
      expect(
        pifagor.every((e) =>
            '${e.title} ${e.formula} ${e.takeaway}'
                .toLowerCase()
                .contains('пифагор')),
        isTrue,
      );

      expect(filterReferenceEntries(entries, query: 'zzz_qqq_yoq'), isEmpty);
    });
  });

  group('v2: Күнделікті марафон (таза функциялар)', () {
    test('күн кілті мен seed пішімі', () {
      final d = DateTime(2026, 7, 4);
      expect(dailyDateKey(d), '2026-07-04');
      expect(dailySeed(d), 20260704);
    });

    test('бір күнге детерминистік, басқа күнге басқа жиынтық', () {
      final day = DateTime(2026, 7, 4);
      final a = buildDailyQuestions(8, day);
      final b = buildDailyQuestions(8, day);
      expect(a.length, DailyConfig.questionCount);
      expect([for (final q in a) q.text], [for (final q in b) q.text]);

      final c = buildDailyQuestions(8, DateTime(2026, 7, 5));
      expect(
        [for (final q in a) q.text],
        isNot(equals([for (final q in c) q.text])),
      );
    });

    test('марапат: мінсіз өткенге бонус қосылады', () {
      final (xpFull, coinsFull) = dailyReward(10, 10);
      expect(xpFull, 10 * DailyConfig.xpPerCorrect + DailyConfig.perfectBonus);
      expect(coinsFull, 10 * DailyConfig.coinsPerCorrect);

      final (xpPart, _) = dailyReward(7, 10);
      expect(xpPart, 7 * DailyConfig.xpPerCorrect);

      final (xpZero, coinsZero) = dailyReward(0, 10);
      expect(xpZero, 0);
      expect(coinsZero, 0);
    });
  });

  group('v2.1: Апталық мақсат (таза функциялар)', () {
    test('weekKey — аптаның дүйсенбісі; бір аптада бірдей', () {
      // 2026-07-04 — сенбі, дүйсенбісі 2026-06-29.
      expect(weekKey(DateTime(2026, 7, 4)), '2026-06-29');
      expect(weekKey(DateTime(2026, 6, 29)), '2026-06-29');
      expect(weekKey(DateTime(2026, 7, 5)), '2026-06-29'); // жексенбі
      expect(weekKey(DateTime(2026, 7, 6)), '2026-07-06'); // келесі дүйсенбі
    });

    test('bumpWeeklyRaw: жинақтайды, апта ауысса нөлден бастайды', () {
      expect(bumpWeeklyRaw(null, '2026-06-29', 50), '2026-06-29|50');
      expect(bumpWeeklyRaw('2026-06-29|50', '2026-06-29', 25),
          '2026-06-29|75');
      expect(bumpWeeklyRaw('2026-06-22|900', '2026-06-29', 10),
          '2026-06-29|10');
    });

    test('weeklyEarned: тек ағымдағы аптаны оқиды', () {
      expect(weeklyEarned('2026-06-29|75', '2026-06-29'), 75);
      expect(weeklyEarned('2026-06-22|900', '2026-06-29'), 0);
      expect(weeklyEarned(null, '2026-06-29'), 0);
      expect(weeklyEarned('bұзылған', '2026-06-29'), 0);
    });

    test('мақсат деңгейлері өсу ретімен', () {
      expect(weeklyGoalTiers.length, 3);
      for (var i = 1; i < weeklyGoalTiers.length; i++) {
        expect(weeklyGoalTiers[i], greaterThan(weeklyGoalTiers[i - 1]));
      }
    });
  });

  group('v2: ҰБТ дайындық индексі', () {
    ExamAttempt attempt(DateTime date, int correct, int total) => ExamAttempt(
          id: '${date.millisecondsSinceEpoch}',
          subject: 'ubt',
          grade: 10,
          date: date,
          correct: correct,
          total: total,
          durationSec: 60,
          modules: [
            ModuleScore(
                module: 1,
                title: 'Математика',
                correct: correct,
                total: total),
          ],
        );

    test('жаңа әрекет ескісінен салмақтырақ (3/2/1)', () {
      final readiness = ubtReadiness([
        attempt(DateTime(2026, 7, 4), 10, 10), // жаңа: 100% × 3
        attempt(DateTime(2026, 7, 3), 0, 10), // ескі: 0% × 2
      ]);
      // (1.0·3 + 0·2) / 5 = 0.6
      expect(readiness['Математика'], closeTo(.6, .0001));
    });

    test('3 әрекеттен көбі есепке алынбайды, бос тізім — бос карта', () {
      expect(ubtReadiness(const []), isEmpty);
      final readiness = ubtReadiness([
        attempt(DateTime(2026, 7, 4), 10, 10),
        attempt(DateTime(2026, 7, 3), 10, 10),
        attempt(DateTime(2026, 7, 2), 10, 10),
        attempt(DateTime(2026, 7, 1), 0, 10), // 4-ші — еленбейді
      ]);
      expect(readiness['Математика'], closeTo(1.0, .0001));
    });
  });
}
