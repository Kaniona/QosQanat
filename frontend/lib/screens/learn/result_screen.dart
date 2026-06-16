import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/avatar/avatar_display.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/level_up_modal.dart';

/// Нәтиже экраны: конфетти + 3 жұлдыз + ұпай % + марапаттар (count-up)
/// + маскот + «Келесі биік ашылды!».
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.nodeId, required this.result});

  final String nodeId;
  final TaskResult result;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    if (widget.result.passed) _confetti.play();
    // Деңгей көтерілген болса — модал.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = ref.read(gameProvider).pendingLevelUp;
      if (pending != null && mounted) {
        LevelUpModal.show(context, pending);
        ref.read(gameProvider.notifier).consumeLevelUp();
      }
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    result.passed
                        ? AppStrings.taskComplete
                        : AppStrings.heartsOut,
                    style: AppTypography.h1,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().slideY(begin: .2),
                  const SizedBox(height: AppSpacing.sp5),

                  // ---- 3 жұлдыз ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          Icons.star_rounded,
                          size: i == 1 ? 72 : 56,
                          color: i < result.stars
                              ? AppColors.goldBright
                              : AppColors.cloudBorder,
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0, 0),
                              delay: (250 + i * 200).ms,
                              duration: 450.ms,
                              curve: Curves.elasticOut,
                            ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sp4),
                  Text(
                    '${AppStrings.accuracy}: ${result.scorePercent}%',
                    style: AppTypography.h2
                        .copyWith(color: AppColors.eagleBlue),
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: AppSpacing.sp6),

                  // ---- Марапаттар (count-up) ----
                  if (result.passed)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sp5),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.rLg,
                        boxShadow: AppColors.sh2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RewardCounter(
                            label: '⚡ XP',
                            value: result.xp,
                            color: AppColors.eagleBlue,
                          ),
                          _RewardCounter(
                            label: '💰',
                            value: result.coins,
                            color: AppColors.steppeGoldDeep,
                          ),
                          _RewardCounter(
                            label: '★',
                            value: result.akyl,
                            color: AppColors.cosmicPurple,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 900.ms).slideY(begin: .15),
                  const SizedBox(height: AppSpacing.sp5),
                  if (result.passed && result.firstCompletion)
                    Text(
                      AppStrings.nextUnlocked,
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.successJade),
                    ).animate().fadeIn(delay: 1100.ms),
                  const Spacer(),
                  AvatarDisplay(
                    assistant: user?.assistantType ?? AssistantType.bektur,
                    mood: result.passed
                        ? AvatarMood.celebrate
                        : AvatarMood.sad,
                    size: 110,
                  ),
                  const Spacer(),
                  AppButton(
                    label: AppStrings.continueBtn,
                    onPressed: () => context.pop(),
                  ).animate().fadeIn(delay: 1200.ms),
                  const SizedBox(height: AppSpacing.sp3),
                  AppButton(
                    label: AppStrings.retry,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.pushReplacement(
                      '/learn/task/${widget.nodeId}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            maxBlastForce: 20,
            gravity: .22,
            colors: const [
              AppColors.steppeGold,
              AppColors.goldBright,
              AppColors.eagleBlue,
              AppColors.cosmicPurple,
              AppColors.successJade,
            ],
          ),
        ],
      ),
    );
  }
}

/// 0-ден мәнге дейін санайтын марапат көрсеткіші.
class _RewardCounter extends StatelessWidget {
  const _RewardCounter({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Text(
            '+$v',
            style: AppTypography.numberDisplay
                .copyWith(fontSize: 28, color: color),
          ),
        ),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
