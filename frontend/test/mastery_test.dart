import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/models/enums.dart';
import 'package:qosqanat/models/mastery.dart';

void main() {
  group('skillId', () {
    test('node id-ден тақырып id шығады', () {
      expect(skillIdFromNode('math_g7_m3_n2'), 'math_g7_m3');
      expect(skillIdFor('math', 7, 3), 'math_g7_m3');
      expect(skillIdFromNode('bad'), isNull);
    });
  });

  group('SkillStat — EMA мен деңгей', () {
    test('жаттықпаған тақырып — fresh', () {
      final s = SkillStat.initial('math', 6, 1);
      expect(s.level, MasteryLevel.fresh);
      expect(s.attempts, 0);
      expect(s.isWeak, isFalse);
    });

    test('дұрыс жауаптар деңгейді көтереді (≥4 → шебер)', () {
      var s = SkillStat.initial('math', 6, 1);
      s = s.record(true); // attempts 1
      expect(s.level, MasteryLevel.learning); // деректі аз
      s = s.record(true);
      s = s.record(true);
      s = s.record(true); // attempts 4, ema=1.0
      expect(s.ema, closeTo(1.0, 1e-9));
      expect(s.level, MasteryLevel.mastered);
      expect(s.isWeak, isFalse);
    });

    test('қате жауаптар әлсіз тұс ретінде көрінеді', () {
      var s = SkillStat.initial('math', 6, 1);
      s = s.record(false);
      s = s.record(false);
      expect(s.level, MasteryLevel.learning);
      expect(s.isWeak, isTrue);
      expect(s.accuracy, 0);
    });

    test('EMA соңғы жауапқа салмақ береді (қалпына келу)', () {
      var s = SkillStat.initial('math', 6, 1);
      for (var i = 0; i < 5; i++) {
        s = s.record(false);
      }
      final low = s.ema;
      for (var i = 0; i < 5; i++) {
        s = s.record(true);
      }
      expect(s.ema, greaterThan(low));
      expect(s.ema, greaterThan(0.6));
    });
  });

  group('ReviewItem — интервалды қайталау (SRS)', () {
    test('қате жауап сұрақты бүгінге қайта әкеледі', () {
      final now = DateTime(2026, 6, 23, 12);
      final item = ReviewItem.create('q1', 'math_g6_m1_n0', 'math_g6_m1',
          Difficulty.medium, now: now);
      expect(item.isDue(now), isTrue);
      expect(item.lapses, 1);
    });

    test('дұрыс жауап мерзімді алға жылжытады', () {
      final now = DateTime(2026, 6, 23, 12);
      var item = ReviewItem.create('q1', 'n', 's', Difficulty.easy, now: now);
      item = item.schedule(true, now: now);
      expect(item.reps, 1);
      expect(item.intervalDays, 1);
      expect(item.isDue(now), isFalse); // ертеңге жылжыды
    });

    test('қайта қателесу мерзімді нөлге қайтарады', () {
      final now = DateTime(2026, 6, 23, 12);
      var item = ReviewItem.create('q1', 'n', 's', Difficulty.hard, now: now);
      item = item.schedule(true, now: now); // алға
      item = item.schedule(false, now: now); // қайта қате
      expect(item.reps, 0);
      expect(item.isDue(now), isTrue);
      expect(item.lapses, 2);
    });

    test('бірнеше дұрыс жауаптан соң бекіп, кезектен шығады', () {
      var now = DateTime(2026, 6, 23, 12);
      var item = ReviewItem.create('q1', 'n', 's', Difficulty.easy, now: now);
      for (var i = 0; i < 6; i++) {
        item = item.schedule(true, now: now);
        now = item.dueAt;
      }
      expect(item.graduated, isTrue);
    });
  });
}
