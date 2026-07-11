import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/providers/league_provider.dart';

void main() {
  group('Лига дәрежесі', () {
    test('ұпай дұрыс дәрежеге түседі', () {
      expect(standingForPoints(0).tier, LeagueTier.bronze);
      expect(standingForPoints(499).tier, LeagueTier.bronze);
      expect(standingForPoints(500).tier, LeagueTier.silver);
      expect(standingForPoints(1500).tier, LeagueTier.gold);
      expect(standingForPoints(3500).tier, LeagueTier.platinum);
      expect(standingForPoints(99999).tier, LeagueTier.diamond);
    });

    test('келесі дәреже мен прогресс дұрыс есептеледі', () {
      final s = standingForPoints(1000); // silver (500..1499)
      expect(s.tier, LeagueTier.silver);
      expect(s.next, LeagueTier.gold);
      expect(s.toNext, 500); // 1500 - 1000
      expect(s.progress, closeTo(0.5, 1e-9)); // (1000-500)/(1500-500)
    });

    test('ең жоғары дәреже — келесісі жоқ, прогресс толық', () {
      final s = standingForPoints(8000);
      expect(s.tier, LeagueTier.diamond);
      expect(s.next, isNull);
      expect(s.toNext, 0);
      expect(s.progress, 1);
    });
  });
}
