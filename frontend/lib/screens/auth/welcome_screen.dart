import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui/ambient_backdrop.dart';
import '../../widgets/ui/app_button.dart';

/// Қош келдің экраны: тірі ambient фон + жарқыраған бренд эмблемасы (қалқиды) +
/// «Бастау» / «Аккаунтым бар →» + таныстыру (карусель) + презентация (демо).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _enterDemo(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(authProvider.notifier).loginAsDemo();
    if (ok && context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Премиум тереңдік: бренд түсті жүзбелі блобтар (reduced-motion-ды құрметтейді).
          const AmbientBackdrop(
            colors: [
              AppColors.eagleBlue,
              AppColors.cosmicPurple,
              AppColors.steppeGold,
            ],
            opacity: .14,
          ),
          SafeArea(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  const Spacer(),
                  const _HeroEmblem(),
                  const SizedBox(height: AppSpacing.sp8),
                  Text(
                    AppStrings.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.displayLarge.copyWith(fontSize: 30),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: .2),
                  const SizedBox(height: AppSpacing.sp4),
                  Text(
                    AppStrings.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.inkSoft),
                  ).animate().fadeIn(delay: 350.ms).slideY(begin: .2),
                  const SizedBox(height: AppSpacing.sp4),
                  // Жобаны 30 секундта таныстыратын карусель (қазылар/қонақтар үшін).
                  TextButton.icon(
                    onPressed: () => context.push('/intro'),
                    icon: const Icon(Icons.play_circle_outline_rounded,
                        size: 20),
                    label: const Text(AppStrings.introCta),
                  ).animate().fadeIn(delay: 450.ms),
                  const Spacer(),
                  AppButton(
                    label: AppStrings.startBtn,
                    onPressed: () => context.push('/register'),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: .3),
                  const SizedBox(height: AppSpacing.sp3),
                  AppButton(
                    label: AppStrings.haveAccount,
                    variant: AppButtonVariant.text,
                    onPressed: () => context.push('/login'),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: AppSpacing.sp2),
                  // Презентация режимі — бір түрткімен дайын демо-аккаунтқа кіру.
                  _DemoEntry(onTap: () => _enterDemo(context, ref))
                      .animate()
                      .fadeIn(delay: 700.ms),
                  const SizedBox(height: AppSpacing.sp4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Бренд эмблемасы: артында жұмсақ аура жарқылы + көлемді градиент төсбелгі,
/// баяу қалқып тұрады (тірі әсер). Кіргенде серіппелі масштаб.
class _HeroEmblem extends StatelessWidget {
  const _HeroEmblem();

  @override
  Widget build(BuildContext context) {
    final emblem = SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Жұмсақ аура — эмблема фоннан бөлектеніп, жарқырап тұрады.
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.eagleBlue.withValues(alpha: .22),
                  AppColors.eagleBlue.withValues(alpha: 0),
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
              boxShadow: AppColors.goldGlow,
            ),
            padding: const EdgeInsets.all(AppSpacing.sp6),
            child: SvgPicture.asset('assets/brand/eagle_emblem.svg'),
          ),
        ],
      ),
    );

    // Кіру: серіппелі масштаб. Сосын: баяу қалқу (тірі әсер).
    return emblem
        .animate()
        .scale(
          begin: const Offset(.7, .7),
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -5, end: 5, duration: 2800.ms, curve: Curves.easeInOut);
  }
}

/// Стендте презентация ашатын нәзік чип-батырма.
class _DemoEntry extends StatelessWidget {
  const _DemoEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rFull,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp4, vertical: AppSpacing.sp2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.slideshow_rounded,
                size: 18, color: AppColors.steppeGold),
            const SizedBox(width: AppSpacing.sp2),
            Text(
              AppStrings.demoModeBtn,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
