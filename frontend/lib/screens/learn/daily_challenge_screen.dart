import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../providers/daily_challenge_provider.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/panels.dart';

/// Күнделікті марафон экраны (v2): күніне бір рет — аралас 10 сұрақ,
/// соңында ұпай мен XP/монета марапаты. Фазалар: дайын → сұрақтар → нәтиже.
class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(dailyChallengeProvider.select((s) => s.phase));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dailyTitle)),
      body: SafeArea(
        child: switch (phase) {
          DailyPhase.ready => const _ReadyView(),
          DailyPhase.running => const _RunView(),
          DailyPhase.done => const _DoneView(),
        },
      ),
    );
  }
}

/// Дайын: формат сипаты + бір ғана CTA.
class _ReadyView extends ConsumerWidget {
  const _ReadyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sp5),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sp5),
          decoration: BoxDecoration(
            gradient: AppColors.heroGold,
            borderRadius: AppRadius.rXl,
            boxShadow:
                AppColors.glow(AppColors.steppeGold, opacity: .3, blur: 18),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.white, size: 42),
              const SizedBox(width: AppSpacing.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.dailyTitle,
                      style: AppTypography.h2.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.dailySub,
                      style: AppTypography.body.copyWith(
                        color: AppColors.white.withValues(alpha: .92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 320.ms).slideY(begin: .08),
        const SizedBox(height: AppSpacing.sp5),
        AppButton(
          label: AppStrings.dailyStart,
          icon: Icons.play_arrow_rounded,
          onPressed: () {
            AppHaptics.tap();
            ref.read(dailyChallengeProvider.notifier).start();
          },
        ),
      ],
    );
  }
}

/// Сұрақ ағыны: прогресс + сұрақ + нұсқалар (кері байланыссыз, таймерсіз).
class _RunView extends ConsumerWidget {
  const _RunView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyChallengeProvider);
    if (state.questions.isEmpty) return const SizedBox.shrink();
    final q = state.questions[state.index];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sp5, AppSpacing.sp2, AppSpacing.sp5, AppSpacing.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.rFull,
                  child: LinearProgressIndicator(
                    value: state.index / state.questions.length,
                    minHeight: 6,
                    backgroundColor:
                        AppColors.steppeGold.withValues(alpha: .15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.steppeGold),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp3),
              Text(
                '${state.index + 1}/${state.questions.length}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp4),
          Expanded(
            child: ListView(
              key: ValueKey(state.index),
              children: [
                PanelCard(
                  padding: const EdgeInsets.all(AppSpacing.sp5),
                  child: Text(q.text,
                      style: AppTypography.h3.copyWith(height: 1.4)),
                ),
                const SizedBox(height: AppSpacing.sp4),
                for (var i = 0; i < q.options.length; i++) ...[
                  Pressable(
                    onTap: () {
                      AppHaptics.tap();
                      ref.read(dailyChallengeProvider.notifier).answer(i);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp4,
                          vertical: AppSpacing.sp4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.rLg,
                        border: Border.all(
                          color:
                              AppColors.steppeGold.withValues(alpha: .4),
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        q.options[i],
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                ],
              ]
                  .animate(interval: 40.ms)
                  .fadeIn(duration: 220.ms)
                  .slideY(begin: .06, curve: Curves.easeOutCubic),
            ),
          ),
        ],
      ),
    );
  }
}

/// Бітті: бүгінгі ұпай + марапат + «ертең жаңасы» ескертпесі.
class _DoneView extends ConsumerWidget {
  const _DoneView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyChallengeProvider);
    final score = state.todayScore ?? state.correct;
    final total = state.questions.isEmpty
        ? DailyConfig.questionCount
        : state.questions.length;
    final perfect = score >= total;
    final (xp, coins) = dailyReward(score, total);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sp5),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sp5),
          decoration: BoxDecoration(
            gradient: perfect ? AppColors.heroJade : AppColors.heroGold,
            borderRadius: AppRadius.rXl,
            boxShadow:
                AppColors.glow(AppColors.steppeGold, opacity: .25, blur: 18),
          ),
          child: Column(
            children: [
              Text(
                '$score/$total',
                style: AppTypography.h1.copyWith(
                  color: AppColors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                perfect ? AppStrings.dailyPerfect : AppStrings.dailyDoneToday,
                style: AppTypography.body.copyWith(
                  color: AppColors.white.withValues(alpha: .95),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sp3),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp4, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .16),
                  borderRadius: AppRadius.rFull,
                ),
                child: Text(
                  '+$xp XP · +$coins',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 320.ms).scaleXY(begin: .96),
        const SizedBox(height: AppSpacing.sp4),
        PanelCard(
          child: Row(
            children: [
              const Icon(Icons.nightlight_round,
                  size: 20, color: AppColors.eagleBlue),
              const SizedBox(width: AppSpacing.sp3),
              Expanded(
                child: Text(
                  AppStrings.dailyCome,
                  style: AppTypography.body
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sp5),
        AppButton(
          label: AppStrings.examDone,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

/// Үй экранындағы марафон картасы: тапсырылмаса — шақыру, тапсырылса —
/// бүгінгі ұпай. Басқанда /daily ашылады.
class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyChallengeProvider);
    final done = state.phase == DailyPhase.done;
    final score = state.todayScore;

    return Pressable(
      onTap: () {
        AppHaptics.tap();
        context.push('/daily');
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp4),
        decoration: BoxDecoration(
          gradient: AppColors.heroGold,
          borderRadius: AppRadius.rXl,
          boxShadow:
              AppColors.glow(AppColors.steppeGold, opacity: .25, blur: 14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .18),
                borderRadius: AppRadius.rLg,
              ),
              child: Icon(
                done
                    ? Icons.emoji_events_rounded
                    : Icons.local_fire_department_rounded,
                color: AppColors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.sp4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.dailyTitle,
                    style: AppTypography.h3.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    done && score != null
                        ? '${AppStrings.dailyYourScore}: '
                            '$score/${DailyConfig.questionCount}'
                        : AppStrings.dailySub,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: .92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
