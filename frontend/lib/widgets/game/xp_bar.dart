import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// XP прогресс жолағы: деңгей ішіндегі ілгерілеу.
class XpBar extends StatelessWidget {
  const XpBar({
    super.key,
    required this.progress,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    this.height = 10,
  });

  /// 0..1 аралығындағы үлес.
  final double progress;
  final int xpIntoLevel;
  final int xpForNextLevel;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.rFull,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(color: AppColors.cloudBorder),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  widthFactor: progress.clamp(0, 1),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.eagleGrad,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sp1),
        Text(
          '⚡ $xpIntoLevel / $xpForNextLevel XP',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}
