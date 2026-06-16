import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/enums.dart';
import 'avatar_base.dart';

/// Серік таңдау карталары: Бектұр (көк) / Назым (раушан).
/// Таңдалғанда акцент жиек + check белгісі + жарқыл.
class AvatarSelector extends StatelessWidget {
  const AvatarSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AssistantType? selected;
  final ValueChanged<AssistantType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AssistantCard(
            type: AssistantType.bektur,
            name: AppStrings.bekturName,
            description: AppStrings.bekturDesc,
            accent: AppColors.eagleBlue,
            background: AppColors.eagleBlueLight,
            selected: selected == AssistantType.bektur,
            onTap: () => onSelect(AssistantType.bektur),
          ),
        ),
        const SizedBox(width: AppSpacing.sp4),
        Expanded(
          child: _AssistantCard(
            type: AssistantType.nazym,
            name: AppStrings.nazymName,
            description: AppStrings.nazymDesc,
            accent: AppColors.nazymRose,
            background: AppColors.nazymRoseLight,
            selected: selected == AssistantType.nazym,
            onTap: () => onSelect(AssistantType.nazym),
          ),
        ),
      ],
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({
    required this.type,
    required this.name,
    required this.description,
    required this.accent,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  final AssistantType type;
  final String name;
  final String description;
  final Color accent;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.sp4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.rLg,
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: .35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppColors.sh1,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                AvatarBase(assistant: type, size: 110),
                const SizedBox(height: AppSpacing.sp3),
                Text(name, style: AppTypography.h3),
                const SizedBox(height: AppSpacing.sp1),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
              ],
            ),
            if (selected)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.sh2,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 18, color: AppColors.white),
                ).animate().scale(
                      duration: 250.ms,
                      curve: Curves.elasticOut,
                    ),
              ),
          ],
        ),
      ),
    );
    return card;
  }
}
