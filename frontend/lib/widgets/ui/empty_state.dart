import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Премиум «бос күй»: жұмсақ реңкті дөңгелек белгіше + тақырып + сипаттама
/// (қажет болса әрекет). Жалаң мәтінді экрандардың орнына барлық жерде осы.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? accent;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.eagleBlue;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sp8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: .16),
                    color.withValues(alpha: .06),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: AppColors.glow(color, opacity: .18, blur: 28, y: 10),
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: AppSpacing.sp5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(color: AppColors.ink),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sp2),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.sp6),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
