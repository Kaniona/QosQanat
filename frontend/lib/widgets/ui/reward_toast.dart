import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Қысқа марапат хабарламасы: жоғарыдан түсіп, 2.5с кейін жоғалады.
abstract final class RewardToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.celebration_rounded,
    Color color = AppColors.successJade,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.paddingOf(context).top + AppSpacing.sp4,
        left: AppSpacing.sp6,
        right: AppSpacing.sp6,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp4,
              vertical: AppSpacing.sp3,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.rMd,
              border: Border.all(color: color, width: 1.5),
              boxShadow: AppColors.sh3,
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppSpacing.sp3),
                Expanded(
                  child: Text(
                    message,
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .slideY(begin: -1.2, duration: 350.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 200.ms)
              .then(delay: 2200.ms)
              .slideY(end: -1.2, duration: 250.ms, curve: Curves.easeIn)
              .fadeOut(duration: 250.ms),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 3100), entry.remove);
  }
}
