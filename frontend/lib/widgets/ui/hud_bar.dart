import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import 'oyu_ornament.dart';
import 'user_photo.dart';

/// Жоғарғы HUD: деңгей белгісі → ақыл pill → монета pill → профиль суреті.
/// Астында ою-өрнек штрих белдеуі (handoff §4).
class HudBar extends ConsumerWidget {
  const HudBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final user = ref.watch(currentUserProvider);

    return Container(
      color: AppColors.dawnBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp4,
              vertical: AppSpacing.sp3,
            ),
            child: Row(
              children: [
                _LevelBadge(level: game.level),
                const SizedBox(width: AppSpacing.sp3),
                _HudPill(
                  icon: Icons.star_rounded,
                  text: Formatters.number(game.akylPoints),
                  background: AppColors.cosmicPurpleLight,
                  foreground: AppColors.cosmicPurple,
                  semanticLabel: 'Ақыл ұпайы',
                ),
                const SizedBox(width: AppSpacing.sp2),
                _HudPill(
                  icon: Icons.monetization_on_rounded,
                  text: Formatters.number(game.coins),
                  background: AppColors.steppeGoldLight,
                  foreground: AppColors.steppeGoldDeep,
                  semanticLabel: 'Монета',
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Профиль',
                  child: GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: UserPhoto(
                      photoPath: user?.profilePhotoPath,
                      size: AppSizes.hudAvatar,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const OyuDashBand(),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.hudLevelBadge,
      height: AppSizes.hudLevelBadge,
      decoration: const BoxDecoration(
        gradient: AppColors.goldSoar,
        shape: BoxShape.circle,
        boxShadow: AppColors.goldGlow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$level',
            style: AppTypography.numberDisplay.copyWith(
              fontSize: 19,
              color: AppColors.white,
              height: 1,
            ),
          ),
          Text(
            'LVL',
            style: AppTypography.caption.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
    required this.semanticLabel,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticLabel: $text',
      child: Container(
        height: AppSizes.hudPillHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.rFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.sp1),
            Text(
              text,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
