import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/shop_items.dart';
import '../../models/enums.dart';
import '../../models/shop_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/avatar/avatar_display.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/reward_toast.dart';

/// Сиректік түсі (жиек + жарқыл).
Color rarityColor(Rarity rarity) => switch (rarity) {
      Rarity.common => AppColors.cloudBorder,
      Rarity.rare => AppColors.eagleBlue,
      Rarity.epic => AppColors.cosmicPurple,
      Rarity.legendary => AppColors.steppeGold,
    };

/// Дүкен: аватар сахнасы + категория табтары + 2 бағаналы тор.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  ShopCategory _category = ShopCategory.top;

  static const _categories = [
    (ShopCategory.top, AppStrings.catTop),
    (ShopCategory.bottom, AppStrings.catBottom),
    (ShopCategory.hat, AppStrings.catHat),
    (ShopCategory.accessory, AppStrings.catAccessory),
    (ShopCategory.pet, AppStrings.catPet),
  ];

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final shop = ref.watch(shopProvider);
    final user = ref.watch(currentUserProvider);
    final animationsOn =
        ref.watch(settingsProvider.select((s) => s.animationsOn));
    final items = ShopItemsData.byCategory(_category);
    final equipped = ref.read(shopProvider.notifier).equippedItems;

    return Column(
      children: [
        // ---- Header: атау + монета балансы ----
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sp5,
            AppSpacing.sp4,
            AppSpacing.sp5,
            AppSpacing.sp2,
          ),
          child: Row(
            children: [
              Text(AppStrings.shopTitle, style: AppTypography.h1),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp3,
                  vertical: AppSpacing.sp2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.steppeGoldLight,
                  borderRadius: AppRadius.rFull,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        size: 20, color: AppColors.steppeGoldDeep),
                    const SizedBox(width: AppSpacing.sp1),
                    Text(
                      Formatters.number(game.coins),
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.steppeGoldDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ---- Аватар сахнасы (киілген заттармен) ----
        Container(
          height: 190,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
          decoration: BoxDecoration(
            gradient: AppColors.cosmicNight,
            borderRadius: AppRadius.rLg,
            boxShadow: AppColors.sh2,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 14,
                child: Container(
                  width: 140,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.steppeGold.withValues(alpha: .18),
                    borderRadius: AppRadius.rFull,
                  ),
                ),
              ),
              AvatarDisplay(
                assistant: user?.assistantType ?? AssistantType.bektur,
                size: 140,
                equipped: equipped,
                animationsOn: animationsOn,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms),
        const SizedBox(height: AppSpacing.sp3),

        // ---- Категория табтары ----
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sp2),
            itemBuilder: (context, index) {
              final (category, label) = _categories[index];
              final active = category == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sp4),
                  decoration: BoxDecoration(
                    gradient: active ? AppColors.eagleGrad : null,
                    color: active ? null : AppColors.white,
                    borderRadius: AppRadius.rFull,
                    border: active
                        ? null
                        : Border.all(color: AppColors.cloudBorder, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.white : AppColors.slate,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sp3),

        // ---- Заттар торы ----
        Expanded(
          child: GridView.builder(
            key: ValueKey(_category),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp5,
              0,
              AppSpacing.sp5,
              AppSpacing.sp12,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sp3,
              crossAxisSpacing: AppSpacing.sp3,
              childAspectRatio: .82,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ShopItemCard(
                item: item,
                purchased: shop.isPurchased(item.id),
                equipped: shop.isEquipped(item.id),
                locked: game.level < item.requiredLevel,
                onTap: () => _showItemSheet(item),
              )
                  .animate()
                  .fadeIn(delay: (40 * (index % 8)).ms, duration: 300.ms)
                  .slideY(begin: .06);
            },
          ),
        ),
      ],
    );
  }

  void _showItemSheet(ShopItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final shop = ref.watch(shopProvider);
          final game = ref.watch(gameProvider);
          return _ItemSheet(
            item: item,
            purchased: shop.isPurchased(item.id),
            equipped: shop.isEquipped(item.id),
            locked: game.level < item.requiredLevel,
            onBuy: () async {
              Navigator.pop(sheetContext);
              await _purchase(item);
            },
            onEquip: () async {
              Navigator.pop(sheetContext);
              await ref.read(shopProvider.notifier).equipItem(item.id);
              if (mounted) {
                RewardToast.show(
                  this.context,
                  message: '${item.name} — ${AppStrings.equipped}',
                  icon: Icons.checkroom_rounded,
                );
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _purchase(ShopItem item) async {
    final result = await ref.read(shopProvider.notifier).purchaseItem(item.id);
    if (!mounted) return;
    switch (result) {
      case PurchaseResult.success:
        RewardToast.show(
          context,
          message: '${item.name} — ${AppStrings.boughtToast}',
          icon: Icons.shopping_bag_rounded,
        );
      case PurchaseResult.notEnoughCoins:
        RewardToast.show(
          context,
          message: AppStrings.notEnoughCoins,
          icon: Icons.money_off_rounded,
          color: AppColors.dangerCoral,
        );
      case PurchaseResult.levelTooLow:
        RewardToast.show(
          context,
          message: '🔒 ${item.requiredLevel} ${AppStrings.levelRequired}',
          icon: Icons.lock_rounded,
          color: AppColors.warningSunset,
        );
      case PurchaseResult.alreadyOwned:
        break;
    }
  }
}

/// Тор картасы: зат қаралымы + аты + бағасы/күйі + сиректік жиегі.
class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.purchased,
    required this.equipped,
    required this.locked,
    required this.onTap,
  });

  final ShopItem item;
  final bool purchased;
  final bool equipped;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = rarityColor(item.rarity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp3),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.rLg,
          border: Border.all(
            color: equipped ? AppColors.successJade : accent,
            width: item.rarity == Rarity.common && !equipped ? 1.5 : 2,
          ),
          boxShadow:
              item.rarity == Rarity.legendary ? AppColors.goldGlow : AppColors.sh1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Қаралым + бейдждер ----
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: .14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        locked ? Icons.lock_rounded : item.icon,
                        size: 34,
                        color: locked ? AppColors.mist : item.color,
                      ),
                    ),
                  ),
                  if (item.isNew && !purchased)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _MiniBadge(
                        text: AppStrings.itemNew,
                        color: AppColors.dangerCoral,
                      ),
                    ),
                  if (equipped)
                    const Positioned(
                      top: 0,
                      left: 0,
                      child: Icon(Icons.check_circle_rounded,
                          size: 20, color: AppColors.successJade),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sp2),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.nightInk,
              ),
            ),
            const SizedBox(height: AppSpacing.sp1),
            _statusLine(),
          ],
        ),
      ),
    );
  }

  Widget _statusLine() {
    if (equipped) {
      return Text(
        AppStrings.equipped,
        style: AppTypography.caption.copyWith(color: AppColors.successJade),
      );
    }
    if (purchased) {
      return Text(
        AppStrings.purchased,
        style: AppTypography.caption.copyWith(color: AppColors.eagleBlue),
      );
    }
    if (locked) {
      return Text(
        '🔒 ${item.requiredLevel}-деңгей',
        style: AppTypography.caption.copyWith(color: AppColors.mist),
      );
    }
    return Text(
      '💰 ${Formatters.number(item.price)}',
      style: AppTypography.caption.copyWith(color: AppColors.steppeGoldDeep),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp2, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        text,
        style: AppTypography.caption
            .copyWith(color: AppColors.white, fontSize: 9, letterSpacing: .5),
      ),
    );
  }
}

/// Заттың bottom sheet қаралымы: үлкен icon, сипаттама, сатып алу/кию.
class _ItemSheet extends StatelessWidget {
  const _ItemSheet({
    required this.item,
    required this.purchased,
    required this.equipped,
    required this.locked,
    required this.onBuy,
    required this.onEquip,
  });

  final ShopItem item;
  final bool purchased;
  final bool equipped;
  final bool locked;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  static const _rarityLabels = {
    Rarity.common: 'Қарапайым',
    Rarity.rare: 'Сирек',
    Rarity.epic: 'Эпикалық',
    Rarity.legendary: 'Аңызға айналған',
  };

  @override
  Widget build(BuildContext context) {
    final accent = rarityColor(item.rarity);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sp6,
        0,
        AppSpacing.sp6,
        AppSpacing.sp6 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 3),
              ),
              child: Icon(item.icon, size: 56, color: item.color),
            ),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Row(
            children: [
              Expanded(child: Text(item.name, style: AppTypography.h2)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp3,
                  vertical: AppSpacing.sp1,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .15),
                  borderRadius: AppRadius.rFull,
                ),
                child: Text(
                  _rarityLabels[item.rarity]!,
                  style: AppTypography.caption.copyWith(
                    color: item.rarity == Rarity.common
                        ? AppColors.slate
                        : accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp2),
          Text(
            locked
                ? '🔒 Бұл затқа ${item.requiredLevel}-деңгей қажет. Оқуды жалғастыр!'
                : 'Аватарыңды безендіріп, досыңа стиль көрсет!',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sp6),
          if (equipped)
            AppButton(
              label: AppStrings.equipped,
              variant: AppButtonVariant.secondary,
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(context),
            )
          else if (purchased)
            AppButton(
              label: AppStrings.tryOn,
              icon: Icons.checkroom_rounded,
              onPressed: onEquip,
            )
          else
            AppButton(
              label: locked
                  ? '🔒 ${item.requiredLevel} ${AppStrings.levelRequired}'
                  : '${AppStrings.buy} · 💰 ${Formatters.number(item.price)}',
              variant: AppButtonVariant.gold,
              onPressed: locked ? null : onBuy,
            ),
        ],
      ),
    );
  }
}
