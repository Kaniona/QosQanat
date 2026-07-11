import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// Лига дәрежесі — Ақыл ұпайына қарай (офлайн, детерминистік).
enum LeagueTier {
  bronze('Қола лигасы', 0, Color(0xFFCD7F32), '🥉'),
  silver('Күміс лигасы', 500, Color(0xFFAAB4BE), '🥈'),
  gold('Алтын лигасы', 1500, Color(0xFFF5A623), '🥇'),
  platinum('Платина лигасы', 3500, Color(0xFF36C5B0), '💠'),
  diamond('Алмас лигасы', 7000, Color(0xFF4A6CF7), '💎');

  const LeagueTier(this.label, this.minPoints, this.color, this.emoji);

  final String label;
  final int minPoints;
  final Color color;
  final String emoji;
}

/// Оқушының лигадағы орны + келесі дәрежеге дейінгі прогресс.
class LeagueStanding {
  const LeagueStanding(this.tier, this.points, this.next);

  final LeagueTier tier;
  final int points;
  final LeagueTier? next;

  double get progress {
    if (next == null) return 1;
    final span = next!.minPoints - tier.minPoints;
    if (span <= 0) return 1;
    return ((points - tier.minPoints) / span).clamp(0, 1);
  }

  int get toNext => next == null ? 0 : (next!.minPoints - points);
}

/// Ұпайға сай лига орнын есептейді (таза, тестке ыңғайлы).
LeagueStanding standingForPoints(int pts) {
  final tiers = LeagueTier.values;
  var tier = tiers.first;
  for (final t in tiers) {
    if (pts >= t.minPoints) tier = t;
  }
  final nextIdx = tier.index + 1;
  final next = nextIdx < tiers.length ? tiers[nextIdx] : null;
  return LeagueStanding(tier, pts, next);
}

final leagueProvider = Provider<LeagueStanding>((ref) {
  final pts = ref.watch(currentUserProvider.select((u) => u?.akylPoints ?? 0));
  return standingForPoints(pts);
});
