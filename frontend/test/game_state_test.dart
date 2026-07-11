import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/providers/game_provider.dart';

void main() {
  group('XP → деңгей формуласы (50·L·(L−1))', () {
    test('xpToReach межелік мәндері', () {
      expect(GameState.xpToReach(1), 0);
      expect(GameState.xpToReach(2), 100);
      expect(GameState.xpToReach(3), 300);
      expect(GameState.xpToReach(5), 1000);
    });

    test('levelFromXp шектерде дұрыс деңгей береді', () {
      expect(GameState.levelFromXp(0), 1);
      expect(GameState.levelFromXp(99), 1);
      expect(GameState.levelFromXp(100), 2); // дәл шегі
      expect(GameState.levelFromXp(299), 2);
      expect(GameState.levelFromXp(300), 3);
      expect(GameState.levelFromXp(1000), 5);
    });

    test('деңгей 100-ден аспайды (cap)', () {
      expect(GameState.levelFromXp(1 << 30), 100);
    });
  });

  group('Деңгей ішіндегі прогресс', () {
    test('xpIntoLevel мен xpForNextLevel дұрыс есептеледі', () {
      const s = GameState(level: 2, xp: 150);
      expect(s.xpIntoLevel, 50); // 150 − 100
      expect(s.xpForNextLevel, 200); // 300 − 100
    });

    test('levelProgress 0..1 аралығында', () {
      const start = GameState(level: 2, xp: 100);
      expect(start.levelProgress, 0.0);
      const quarter = GameState(level: 2, xp: 150);
      expect(quarter.levelProgress, 0.25);
    });

    test('100-деңгейде прогресс толық (1.0), келесіге XP — 0', () {
      const maxed = GameState(level: 100, xp: 99999999);
      expect(maxed.xpForNextLevel, 0);
      expect(maxed.levelProgress, 1.0);
    });
  });
}
