import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

/// Деңгей көтерілу модалы: конфетти + серіппелі деңгей белгісі + сыйлық.
class LevelUpModal extends StatefulWidget {
  const LevelUpModal({super.key, required this.newLevel});

  final int newLevel;

  /// Модалды көрсету (барьер арқылы жабылмайды).
  static Future<void> show(BuildContext context, int newLevel) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.nightInk.withValues(alpha: .55),
      builder: (_) => LevelUpModal(newLevel: newLevel),
    );
  }

  @override
  State<LevelUpModal> createState() => _LevelUpModalState();
}

class _LevelUpModalState extends State<LevelUpModal> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2))
      ..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sp8),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp6,
              AppSpacing.sp12,
              AppSpacing.sp6,
              AppSpacing.sp6,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.rXl,
              boxShadow: AppColors.sh4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.levelUp, style: AppTypography.h1),
                const SizedBox(height: AppSpacing.sp2),
                Text(
                  AppStrings.levelUpBody(widget.newLevel),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sp6),
                AppButton(
                  label: AppStrings.continueBtn,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          )
              .animate()
              .scale(
                begin: const Offset(.8, .8),
                duration: 400.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 200.ms),
          // Деңгей белгісі (жоғарыда қалқып тұрады)
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              gradient: AppColors.goldSoar,
              shape: BoxShape.circle,
              boxShadow: AppColors.goldGlow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.newLevel}',
                  style: AppTypography.numberDisplay.copyWith(
                    color: AppColors.white,
                    height: 1,
                  ),
                ),
                Text(
                  'LVL',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ).animate().scale(
                begin: const Offset(0, 0),
                delay: 150.ms,
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
          Positioned(
            top: 0,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              maxBlastForce: 18,
              minBlastForce: 6,
              gravity: .25,
              colors: const [
                AppColors.steppeGold,
                AppColors.goldBright,
                AppColors.eagleBlue,
                AppColors.cosmicPurple,
                AppColors.successJade,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
