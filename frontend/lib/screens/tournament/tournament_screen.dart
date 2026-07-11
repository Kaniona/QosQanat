import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/tournament.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/empty_state.dart';
import '../../widgets/ui/oyu_ornament.dart';
import '../../widgets/ui/reward_toast.dart';

/// Турнир: жүлде қоры + кері санақ + қатысушылар + «Қатысу».
class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(tournamentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🏟️ ${AppStrings.tournamentTitle}')),
      body: tournaments.isEmpty
          ? const EmptyState(
              icon: Icons.emoji_events_rounded,
              title: AppStrings.tournamentEmpty,
              subtitle: AppStrings.tournamentEmptySub,
              accent: AppColors.steppeGold,
            )
          : ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: tournaments.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sp4),
              itemBuilder: (context, index) =>
                  _TournamentCard(tournament: tournaments[index])
                      .animate()
                      .fadeIn(delay: (80 * index).ms)
                      .slideY(begin: .08),
            ),
    );
  }
}

class _TournamentCard extends ConsumerWidget {
  const _TournamentCard({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = tournament.endsAt.difference(DateTime.now()).inDays;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.cosmicNight,
        borderRadius: AppRadius.rXl,
        boxShadow: AppColors.sh3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OyuDashBand(opacity: .7),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sp5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Тақырып + статус ----
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tournament.title,
                        style: AppTypography.h2
                            .copyWith(color: AppColors.white),
                      ),
                    ),
                    if (tournament.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp3,
                          vertical: AppSpacing.sp1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successJade,
                          borderRadius: AppRadius.rFull,
                        ),
                        child: Text(
                          AppStrings.drawerActive,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.white, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp3),
                Text(
                  tournament.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: .75),
                  ),
                ),
                const SizedBox(height: AppSpacing.sp5),

                // ---- Жүлде қоры ----
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sp4),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldSoar,
                    borderRadius: AppRadius.rLg,
                    boxShadow: AppColors.goldGlow,
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.tournamentPrize,
                        style: AppTypography.caption
                            .copyWith(color: const Color(0xFF7A4A00)),
                      ),
                      Text(
                        '${Formatters.number(tournament.prizePool)} ₸',
                        style: AppTypography.numberDisplay
                            .copyWith(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sp4),

                // ---- Кері санақ + қатысушылар ----
                Row(
                  children: [
                    _InfoTile(
                      icon: Icons.timer_outlined,
                      label: AppStrings.tournamentEnds,
                      value: '$daysLeft ${AppStrings.daysShort}',
                    ),
                    const SizedBox(width: AppSpacing.sp2),
                    _InfoTile(
                      icon: Icons.groups_rounded,
                      label: AppStrings.participants,
                      value: Formatters.number(tournament.participants),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp5),

                // ---- Қатысу / Жарысу ----
                if (!tournament.joined)
                  AppButton(
                    label: AppStrings.tournamentJoin,
                    variant: AppButtonVariant.gold,
                    icon: Icons.emoji_events_rounded,
                    onPressed: !tournament.isActive
                        ? null
                        : () async {
                            await ref
                                .read(tournamentProvider.notifier)
                                .join(tournament.id);
                            if (context.mounted) {
                              RewardToast.show(
                                context,
                                message: AppStrings.tournamentJoinedToast(
                                  tournament.title,
                                ),
                              );
                            }
                          },
                  )
                else ...[
                  if (tournament.played)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sp3),
                      decoration: BoxDecoration(
                        color: AppColors.steppeGold.withValues(alpha: .14),
                        borderRadius: AppRadius.rMd,
                      ),
                      child: Center(
                        child: Text(
                          '${AppStrings.tournamentYourRank}: '
                          '${tournament.rank}-${AppStrings.tournamentRankShort} '
                          '· ${tournament.bestScore} ұпай',
                          style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.steppeGoldDeep),
                        ),
                      ),
                    ),
                  AppButton(
                    label: tournament.played
                        ? AppStrings.tournamentReplay
                        : AppStrings.tournamentPlay,
                    variant: AppButtonVariant.gold,
                    icon: Icons.sports_esports_rounded,
                    onPressed: !tournament.isActive
                        ? null
                        : () =>
                            context.push('/tournament/play/${tournament.id}'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp3),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: .08),
          borderRadius: AppRadius.rMd,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.steppeGold),
            const SizedBox(height: AppSpacing.sp1),
            Text(
              value,
              style: AppTypography.body.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.white.withValues(alpha: .55),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
