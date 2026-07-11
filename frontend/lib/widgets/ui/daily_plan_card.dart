import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daily_plan_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/mastery_provider.dart';
import 'panels.dart';

/// «Бүгінгі жоспар» картасы — бала жаттыққан сайын қадамдар белгіленеді,
/// бәрі бітсе мереке (конфетти, күніне бір рет).
class DailyPlanCard extends ConsumerStatefulWidget {
  const DailyPlanCard({super.key});

  @override
  ConsumerState<DailyPlanCard> createState() => _DailyPlanCardState();
}

class _DailyPlanCardState extends ConsumerState<DailyPlanCard> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _celebrateOnce(DailyPlan plan) {
    if (!plan.allDone) return;
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;
    final storage = ref.read(storageProvider);
    final today = dateKey(DateTime.now());
    if (storage.dailyPlanDone(uid) == today) return; // бүгін мерекеленген
    storage.setDailyPlanDone(uid, today);
    _confetti.play();
    // Күндік жоспарды бітіргені үшін марапат.
    ref.read(gameProvider.notifier).addCoins(30);
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(dailyPlanProvider);
    // Бәрі бітсе — бір рет мерекелейміз (build-тен кейін).
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrateOnce(plan));

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        plan.allDone ? _doneCard() : _checklistCard(plan),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 24,
          maxBlastForce: 18,
          gravity: .22,
          colors: const [
            AppColors.steppeGold,
            AppColors.goldBright,
            AppColors.eagleBlue,
            AppColors.successJade,
          ],
        ),
      ],
    );
  }

  Widget _doneCard() {
    return PanelCard(
      gradient: AppColors.heroJade,
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.dailyPlanDone,
                    style: AppTypography.h3.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(AppStrings.dailyPlanDoneSub,
                    style: AppTypography.caption
                        .copyWith(color: Colors.white.withValues(alpha: .9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistCard(DailyPlan plan) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const OyuDiamond(),
              const SizedBox(width: AppSpacing.sp3),
              Expanded(
                child: Text(AppStrings.dailyPlanTitle,
                    style:
                        AppTypography.h3.copyWith(fontWeight: FontWeight.w900)),
              ),
              Text('${plan.doneCount}/${plan.steps.length}',
                  style: AppTypography.caption
                      .copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.sp2),
          ClipRRect(
            borderRadius: AppRadius.rFull,
            child: LinearProgressIndicator(
              value: plan.progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.successJade),
            ),
          ),
          const SizedBox(height: AppSpacing.sp2),
          for (final step in plan.steps) _StepRow(step: step),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final DailyStep step;

  @override
  Widget build(BuildContext context) {
    final color = step.done ? AppColors.successJade : AppColors.eagleBlue;
    return InkWell(
      onTap: step.done ? null : () => context.push(step.route),
      borderRadius: AppRadius.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp2),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.done ? Icons.check_rounded : step.icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sp3),
            Expanded(
              child: Text(
                step.extra == null || step.done
                    ? step.label
                    : '${step.label} · ${step.extra}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: step.done ? AppColors.muted : AppColors.ink,
                  decoration:
                      step.done ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!step.done)
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
