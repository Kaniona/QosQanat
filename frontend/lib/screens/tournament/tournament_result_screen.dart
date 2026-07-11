import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/tournament.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/panels.dart';
import '../../widgets/ui/stat_label.dart';

/// Турнир нәтижесі: орын + жүлде + толық кесте (оқушы ерекшеленеді).
class TournamentResultScreen extends ConsumerStatefulWidget {
  const TournamentResultScreen({super.key, required this.result});

  final TournamentResult result;

  @override
  ConsumerState<TournamentResultScreen> createState() =>
      _TournamentResultScreenState();
}

class _TournamentResultScreenState
    extends ConsumerState<TournamentResultScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    if (widget.result.isPodium) _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final medal = switch (r.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '🏅',
    };
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.sp5,
                      AppSpacing.sp5, AppSpacing.sp5, AppSpacing.sp3),
                  child: PanelCard(
                    gradient: r.isPodium
                        ? AppColors.heroGold
                        : AppColors.heroEagle,
                    child: Column(
                      children: [
                        Text(medal, style: const TextStyle(fontSize: 56)),
                        const SizedBox(height: AppSpacing.sp2),
                        Text(
                          '${r.rank}-${AppStrings.tournamentRankShort} '
                          '/ ${r.fieldSize}',
                          style: AppTypography.h1.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text('${AppStrings.score}: ${r.score}/${r.total}',
                            style: AppTypography.body.copyWith(
                                color: Colors.white.withValues(alpha: .9))),
                        const SizedBox(height: AppSpacing.sp3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (r.coins > 0) ...[
                              StatLabel(
                                  icon: AppIcons.coin,
                                  text: '+${r.coins}',
                                  color: Colors.white),
                              const SizedBox(width: AppSpacing.sp4),
                            ],
                            if (r.akyl > 0)
                              StatLabel(
                                  icon: AppIcons.akyl,
                                  text: '+${r.akyl}',
                                  color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp5, vertical: AppSpacing.sp1),
                  child: Row(
                    children: [
                      const OyuDiamond(),
                      const SizedBox(width: AppSpacing.sp3),
                      Text(AppStrings.tournamentLeaderboard,
                          style: AppTypography.h3
                              .copyWith(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.sp5,
                        AppSpacing.sp2, AppSpacing.sp5, AppSpacing.sp4),
                    itemCount: r.board.length,
                    itemBuilder: (context, i) =>
                        _Row(rank: i + 1, entrant: r.board[i]),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.sp5, 0,
                      AppSpacing.sp5,
                      AppSpacing.sp5 + MediaQuery.paddingOf(context).bottom),
                  child: AppButton(
                    label: AppStrings.done,
                    onPressed: () => context.go('/tournament'),
                  ),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 28,
            maxBlastForce: 20,
            gravity: .22,
            colors: const [
              AppColors.steppeGold,
              AppColors.goldBright,
              AppColors.eagleBlue,
              AppColors.successJade,
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.rank, required this.entrant});
  final int rank;
  final TournamentEntrant entrant;

  @override
  Widget build(BuildContext context) {
    final me = entrant.isMe;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp2),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
      decoration: BoxDecoration(
        color: me ? AppColors.eagleBlue.withValues(alpha: .12) : AppColors.surface,
        borderRadius: AppRadius.rMd,
        border: me
            ? Border.all(color: AppColors.eagleBlue, width: 1.5)
            : Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$rank',
                style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w900,
                    color: rank <= 3 ? AppColors.steppeGoldDeep : AppColors.muted)),
          ),
          const SizedBox(width: AppSpacing.sp2),
          Expanded(
            child: Text(
              me ? '${entrant.name} (сен)' : entrant.name,
              style: AppTypography.body.copyWith(
                  fontWeight: me ? FontWeight.w900 : FontWeight.w600,
                  color: me ? AppColors.eagleBlue : AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${entrant.score}',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
