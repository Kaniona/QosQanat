import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/ui/app_button.dart';

/// Қош келдің экраны: эмблема + «Бастау» / «Аккаунтым бар →».
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const Spacer(),
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
              ).animate().scale(
                    begin: const Offset(.7, .7),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
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
                style: AppTypography.bodyLarge.copyWith(color: AppColors.slate),
              ).animate().fadeIn(delay: 350.ms).slideY(begin: .2),
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
              const SizedBox(height: AppSpacing.sp4),
            ],
          ),
        ),
      ),
    );
  }
}
