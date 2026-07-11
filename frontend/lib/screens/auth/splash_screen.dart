import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/enums.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/quest_provider.dart';

/// Splash: 2.5с эмблема анимациясы → сеанс бар болса Home, әйтпесе Welcome.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Бірінші кадр салынып болған соң ғана — initState ішінде провайдер
    // өзгертуге болмайды (сеансы бар қолданушыда splash қатып қалатын).
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = ref.read(authProvider.notifier);
    await auth.restoreSession();
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    if (ref.read(authProvider).isAuthenticated) {
      // Streak тексерісі — күн ауысқанын осында байқаймыз.
      await ref.read(gameProvider.notifier).checkStreak();
      // Күнделікті квесттер: кіру квесті + streak прогресін синхрондау.
      final quests = ref.read(questProvider.notifier);
      await quests.track(QuestType.login);
      await quests.syncStreak(ref.read(gameProvider).currentStreak);
      // Streak жетістіктері осында ашылады (3/7/30/100 күн).
      await ref.read(achievementProvider.notifier).evaluate();
      if (mounted) context.go('/home');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.cosmicNight),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Жұмсақ алтын аура — қараңғы фонда эмблема жарқырап тұрады.
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.steppeGold.withValues(alpha: .20),
                            AppColors.steppeGold.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.cosmicNight,
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: AppColors.steppeGold.withValues(alpha: .35),
                        ),
                        boxShadow: AppColors.goldGlow,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.sp6),
                      child: SvgPicture.asset('assets/brand/eagle_emblem.svg'),
                    ),
                  ],
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(.6, .6),
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1,
                    end: 1.04,
                    duration: 1600.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: AppSpacing.sp6),
              Text(
                AppStrings.appName,
                style: AppTypography.displayLarge
                    .copyWith(color: AppColors.white),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
              const SizedBox(height: AppSpacing.sp2),
              Text(
                AppStrings.appTagline,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.steppeGold),
              ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
