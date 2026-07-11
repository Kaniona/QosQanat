import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Кішкентай алтын ою-алмаз акценті — ұлттық сәйкестік белгісі.
/// Секция тақырыптары мен бөлгіштерде қолданылады.
class OyuDiamond extends StatelessWidget {
  const OyuDiamond({super.key, this.size = 10, this.gradient});

  final double size;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.goldSoar,
          borderRadius: BorderRadius.circular(size * .22),
        ),
      ),
    );
  }
}

/// Секция тақырыбы: алтын ою-алмаз + қалың атау + (қаласа) оң жақ виджеті.
/// Бүкіл қосымшада біртұтас иерархия береді.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.bottomPadding = AppSpacing.sp3,
  });

  final String title;
  final Widget? trailing;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          const OyuDiamond(),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Text(
              title,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sp2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Біртұтас премиум карта: үлкен дөңгелек бұрыш (28), жұмсақ қабатты
/// көлеңке, режимге сезімтал бет. Бүкіл қосымшаның негізгі контейнері.
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.sp4),
    this.onTap,
    this.gradient,
    this.color,
    this.radius = AppRadius.xl,
    this.border,
    this.shadow,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final double radius;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    final decoration = BoxDecoration(
      gradient: gradient,
      color: gradient == null ? (color ?? AppColors.surface) : null,
      borderRadius: br,
      border: border,
      boxShadow: shadow ?? AppColors.cardShadow,
    );

    final container = Container(
      padding: padding,
      decoration: decoration,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: child,
    );

    if (onTap == null) return container;

    // Басуға келетін карта — clay серпімді «squish» + жеңіл haptic.
    // (ripple орнына — premium gamified тілінде squish басты түрту белгісі.)
    return Pressable(
      onTap: onTap,
      borderRadius: br,
      child: container,
    );
  }
}
