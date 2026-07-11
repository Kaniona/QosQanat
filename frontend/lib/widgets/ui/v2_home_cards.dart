import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weekly_goal_provider.dart';
import 'panels.dart';

/// «Не жаңалық» картасының көрінуі (нұсқаға байланған, жабылса қайтпайды).
final whatsNewVisibleProvider = StateProvider.autoDispose<bool>((ref) {
  try {
    return !ref.read(storageProvider).whatsNewDismissed('2.1.0');
  } catch (_) {
    return false;
  }
});

/// Апталық мақсат картасы (v2.1): мақсат қойылмаса — шақыру; қойылса —
/// прогресс-сақина; орындалса — жасыл мереке күйі. Басқанда деңгей таңдау
/// парағы ашылады.
class WeeklyGoalCard extends ConsumerWidget {
  const WeeklyGoalCard({super.key});

  void _pickTier(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp5, AppSpacing.sp3, AppSpacing.sp5, AppSpacing.sp5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.weeklyGoalPick, style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sp3),
              for (var i = 0; i < weeklyGoalTiers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sp2),
                  child: Pressable(
                    onTap: () async {
                      AppHaptics.tap();
                      final uid = ref.read(authProvider).user?.id;
                      if (uid != null) {
                        try {
                          await ref
                              .read(storageProvider)
                              .setWeeklyGoal(uid, weeklyGoalTiers[i]);
                        } catch (_) {}
                      }
                      ref.invalidate(weeklyGoalProvider);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp4,
                          vertical: AppSpacing.sp3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.rLg,
                        border: Border.all(
                          color:
                              AppColors.eagleBlue.withValues(alpha: .35),
                          width: 1.3,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            i == 0
                                ? Icons.directions_walk_rounded
                                : (i == 1
                                    ? Icons.directions_run_rounded
                                    : Icons.rocket_launch_rounded),
                            size: 22,
                            color: AppColors.eagleBlue,
                          ),
                          const SizedBox(width: AppSpacing.sp3),
                          Expanded(
                            child: Text(
                              i == 0
                                  ? AppStrings.weeklyGoalEasy
                                  : (i == 1
                                      ? AppStrings.weeklyGoalNormal
                                      : AppStrings.weeklyGoalHero),
                              style: AppTypography.body
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            '${weeklyGoalTiers[i]} XP',
                            style: AppTypography.body.copyWith(
                              color: AppColors.eagleBlue,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:goal, :earned) = ref.watch(weeklyGoalProvider);
    final done = goal != null && earned >= goal;
    final frac =
        goal == null ? 0.0 : (earned / goal).clamp(0.0, 1.0).toDouble();

    return Pressable(
      onTap: () {
        AppHaptics.tap();
        _pickTier(context, ref);
      },
      child: PanelCard(
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: goal == null ? 0 : frac,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor:
                          AppColors.eagleBlue.withValues(alpha: .14),
                      valueColor: AlwaysStoppedAnimation(
                        done ? AppColors.successJade : AppColors.eagleBlue,
                      ),
                    ),
                  ),
                  Icon(
                    done ? Icons.check_rounded : Icons.flag_rounded,
                    size: 22,
                    color: done ? AppColors.successJade : AppColors.eagleBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sp4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.weeklyGoalTitle,
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal == null
                        ? AppStrings.weeklyGoalSet
                        : (done
                            ? AppStrings.weeklyGoalDone
                            : '$earned / $goal XP'),
                    style: AppTypography.caption.copyWith(
                      color: done ? AppColors.successJade : AppColors.inkSoft,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.tune_rounded, size: 18, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// «Не жаңалық — 2.1» картасы: жаңартудан кейін бір рет көрінеді,
/// «Түсінікті» басылса біржола жабылады (prefs).
class WhatsNewCard extends ConsumerWidget {
  const WhatsNewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(whatsNewVisibleProvider);
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sp4),
      child: PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 20, color: AppColors.cosmicPurple),
                const SizedBox(width: AppSpacing.sp2),
                Text(
                  AppStrings.whatsNewTitle,
                  style:
                      AppTypography.body.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp2),
            Text(
              AppStrings.whatsNewBody,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSoft,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sp3),
            Align(
              alignment: Alignment.centerRight,
              child: Pressable(
                onTap: () async {
                  AppHaptics.tap();
                  try {
                    await ref.read(storageProvider).dismissWhatsNew('2.1.0');
                  } catch (_) {}
                  ref.read(whatsNewVisibleProvider.notifier).state = false;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp4, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.tintBlue,
                    borderRadius: AppRadius.rFull,
                  ),
                  child: Text(
                    AppStrings.whatsNewDismiss,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.eagleBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
