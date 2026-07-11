import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'oyu_ornament.dart';

/// 5 табты төменгі навигация: ортасы (Оқу) −32px көтерілген дөңгелек
/// (handoff §4). Stock BottomNavigationBar емес — custom Stack.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    (Icons.home_rounded, AppStrings.tabHome),
    (Icons.emoji_events_rounded, AppStrings.tabRating),
    (Icons.menu_book_rounded, AppStrings.tabLearn),
    (Icons.shopping_bag_rounded, AppStrings.tabShop),
    (Icons.person_rounded, AppStrings.tabProfile),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: AppSizes.bottomNavHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Бар негізі
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                boxShadow: AppColors.navShadow,
              ),
              child: Column(
                children: [
                  const ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    child: OyuDashBand(opacity: .45),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: Row(
                        children: [
                          for (var i = 0; i < _tabs.length; i++)
                            Expanded(
                              child: i == 2
                                  ? const SizedBox.shrink()
                                  : _TabItem(
                                      icon: _tabs[i].$1,
                                      label: _tabs[i].$2,
                                      active: currentIndex == i,
                                      onTap: () => onTap(i),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Көтерілген орта таб (Оқу)
          Positioned(
            top: -32,
            left: 0,
            right: 0,
            child: Center(
              child: _RaisedTab(
                icon: _tabs[2].$1,
                label: _tabs[2].$2,
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.steppeGoldDeep : AppColors.muted;
    // haptic: false — таб ауысуының haptic-і router деңгейінде беріледі.
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.88,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.18 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: AppSpacing.sp1),
            Text(label, style: AppTypography.tabLabel.copyWith(color: color)),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 5 : 0,
              height: active ? 5 : 0,
              decoration: const BoxDecoration(
                color: AppColors.steppeGold,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaisedTab extends StatelessWidget {
  const _RaisedTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.92,
      semanticLabel: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: AppSizes.raisedTab,
            height: AppSizes.raisedTab,
            decoration: BoxDecoration(
              gradient: active ? AppColors.goldSoar : AppColors.eagleGrad,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 4),
              boxShadow:
                  active ? AppColors.goldGlow : AppColors.raisedTabShadow,
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: AppColors.white, size: 26),
          ),
          const SizedBox(height: AppSpacing.sp1),
          Text(
            label,
            style: AppTypography.tabLabel.copyWith(
              color: active ? AppColors.steppeGoldDeep : AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
