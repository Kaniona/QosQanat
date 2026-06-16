import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';

enum AppButtonVariant { primary, secondary, gold, text }

/// «Eagle Wings» батырмасы: биіктік 56, толық дөңгелек, басқанда
/// 2px төмен жылжып, жарықтығы азаяды (handoff §3).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expanded;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final (Gradient? gradient, Color? solid, Color fg, Border? border,
        List<BoxShadow> shadow) = switch (widget.variant) {
      AppButtonVariant.primary => _disabled
          ? (null, AppColors.disabledFill, AppColors.white, null, const <BoxShadow>[])
          : (AppColors.eagleGrad, null, AppColors.white, null, AppColors.sh2),
      AppButtonVariant.secondary => (
          null,
          AppColors.white,
          AppColors.eagleBlue,
          Border.all(color: AppColors.eagleBlue, width: 2),
          const <BoxShadow>[],
        ),
      AppButtonVariant.gold => (
          AppColors.goldSoar,
          null,
          const Color(0xFF7A4A00),
          null,
          AppColors.goldGlow,
        ),
      AppButtonVariant.text => (
          null,
          Colors.transparent,
          AppColors.eagleBlue,
          null,
          const <BoxShadow>[],
        ),
    };

    final content = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: fg, size: 22),
          const SizedBox(width: AppSpacing.sp2),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: AppTypography.button.copyWith(color: fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
      onTap: _disabled
          ? null
          : () {
              AppHaptics.tap();
              widget.onPressed!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: AppSizes.buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp6),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          gradient: gradient,
          color: solid,
          border: border,
          borderRadius: AppRadius.rFull,
          boxShadow: _pressed ? AppColors.sh1 : shadow,
        ),
        foregroundDecoration: _pressed
            ? BoxDecoration(
                color: Colors.black.withValues(alpha: .04),
                borderRadius: AppRadius.rFull,
              )
            : null,
        child: Center(child: content),
      ),
    );
  }
}

/// 48×48 дөңгелек icon-батырма.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.active = false,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: active ? AppColors.eagleBlue : AppColors.eagleBlueLight,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: AppSizes.iconButton,
            height: AppSizes.iconButton,
            child: Icon(
              icon,
              size: 22,
              color: active ? AppColors.white : AppColors.eagleBlue,
            ),
          ),
        ),
      ),
    );
  }
}
