import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shop_items.dart';
import '../models/enums.dart';
import '../models/shop_item.dart';
import '../services/local_storage_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'game_provider.dart';
import 'quest_provider.dart';

class ShopState {
  const ShopState({
    this.purchasedIds = const {},
    this.equippedIds = const {},
  });

  final Set<String> purchasedIds;
  final Set<String> equippedIds;

  bool isPurchased(String id) => purchasedIds.contains(id);
  bool isEquipped(String id) => equippedIds.contains(id);

  ShopState copyWith({Set<String>? purchasedIds, Set<String>? equippedIds}) =>
      ShopState(
        purchasedIds: purchasedIds ?? this.purchasedIds,
        equippedIds: equippedIds ?? this.equippedIds,
      );
}

enum PurchaseResult { success, notEnoughCoins, levelTooLow, alreadyOwned }

/// Дүкен: сатып алу, кию — инвентарь қолданушы жазбасында сақталады.
class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier(this._ref, this._storage, this._userId)
      : super(const ShopState()) {
    _load();
  }

  final Ref _ref;
  final LocalStorageService _storage;
  final String? _userId;

  void _load() {
    if (_userId == null) return;
    final user = _storage.getUser(_userId);
    if (user == null) return;
    state = ShopState(
      purchasedIds: user.purchasedItems.toSet(),
      equippedIds: user.equippedItems.toSet(),
    );
  }

  Future<void> _persist() async {
    if (_userId == null) return;
    final user = _storage.getUser(_userId);
    if (user == null) return;
    await _storage.saveUser(user.copyWith(
      purchasedItems: state.purchasedIds.toList(),
      equippedItems: state.equippedIds.toList(),
    ));
    _ref.read(authProvider.notifier).refreshUser();
  }

  Future<PurchaseResult> purchaseItem(String itemId) async {
    final item = ShopItemsData.byId(itemId);
    if (item == null || _userId == null) return PurchaseResult.alreadyOwned;
    if (state.isPurchased(itemId)) return PurchaseResult.alreadyOwned;

    final game = _ref.read(gameProvider);
    if (game.level < item.requiredLevel) return PurchaseResult.levelTooLow;

    final paid = await _ref.read(gameProvider.notifier).spendCoins(item.price);
    if (!paid) return PurchaseResult.notEnoughCoins;

    state = state.copyWith(
      purchasedIds: {...state.purchasedIds, itemId},
    );
    await _persist();

    // Сатып алғаннан кейін бірден кию.
    await equipItem(itemId);

    await _ref.read(questProvider.notifier).track(QuestType.purchase);
    await _ref.read(achievementProvider.notifier).evaluate();
    return PurchaseResult.success;
  }

  /// Кию: бір категорияда бір ғана зат киіледі.
  Future<void> equipItem(String itemId) async {
    final item = ShopItemsData.byId(itemId);
    if (item == null || !state.isPurchased(itemId)) return;

    final equipped = {...state.equippedIds}..removeWhere((id) {
        final other = ShopItemsData.byId(id);
        return other != null && other.category == item.category;
      });
    equipped.add(itemId);
    state = state.copyWith(equippedIds: equipped);
    await _persist();
  }

  Future<void> unequipItem(String itemId) async {
    if (!state.isEquipped(itemId)) return;
    state = state.copyWith(
      equippedIds: {...state.equippedIds}..remove(itemId),
    );
    await _persist();
  }

  /// Киілген заттар (аватар слойлары үшін).
  List<ShopItem> get equippedItems => [
        for (final id in state.equippedIds)
          if (ShopItemsData.byId(id) != null) ShopItemsData.byId(id)!,
      ];
}

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  return ShopNotifier(ref, ref.watch(storageProvider), userId);
});
