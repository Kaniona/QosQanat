import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/shop_item.dart';

/// Дүкен каталогы (50+ зат). Финалды арт келгенше әр зат
/// icon + түс плейсхолдерімен көрсетіледі.
abstract final class ShopItemsData {
  static ShopItem? byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<ShopItem> byCategory(ShopCategory category) =>
      all.where((i) => i.category == category).toList();

  static const List<ShopItem> all = [
    // ---- Жоғарғы киім ----
    ShopItem(id: 'top_tshirt_blue', name: 'Көк футболка', price: 100, category: ShopCategory.top, icon: Icons.checkroom_rounded, color: Color(0xFF4A6CF7)),
    ShopItem(id: 'top_tshirt_gold', name: 'Алтын футболка', price: 150, category: ShopCategory.top, icon: Icons.checkroom_rounded, color: Color(0xFFF5A623)),
    ShopItem(id: 'top_hoodie_purple', name: 'Күлгін худи', price: 250, category: ShopCategory.top, rarity: Rarity.rare, icon: Icons.checkroom_rounded, color: Color(0xFF7B61FF)),
    ShopItem(id: 'top_hoodie_jade', name: 'Жасыл худи', price: 250, category: ShopCategory.top, rarity: Rarity.rare, icon: Icons.checkroom_rounded, color: Color(0xFF00C48C)),
    ShopItem(id: 'top_shirt_school', name: 'Мектеп жейдесі', price: 120, category: ShopCategory.top, icon: Icons.checkroom_rounded, color: Color(0xFFEEF2FF)),
    ShopItem(id: 'top_jacket_leather', name: 'Былғары куртка', price: 500, category: ShopCategory.top, rarity: Rarity.epic, requiredLevel: 8, icon: Icons.checkroom_rounded, color: Color(0xFF2D2D5F)),
    ShopItem(id: 'top_chapan', name: 'Ұлттық шапан', price: 800, category: ShopCategory.top, rarity: Rarity.epic, requiredLevel: 10, icon: Icons.checkroom_rounded, color: Color(0xFFD4860A), isNew: true),
    ShopItem(id: 'top_armor_gold', name: 'Алтын сауыт', price: 1500, category: ShopCategory.top, rarity: Rarity.legendary, requiredLevel: 20, icon: Icons.shield_rounded, color: Color(0xFFFFD700)),
    ShopItem(id: 'top_sweater_winter', name: 'Қысқы жемпір', price: 180, category: ShopCategory.top, icon: Icons.checkroom_rounded, color: Color(0xFFFF8C42)),
    ShopItem(id: 'top_vest_sport', name: 'Спорт жилеті', price: 220, category: ShopCategory.top, rarity: Rarity.rare, icon: Icons.checkroom_rounded, color: Color(0xFFFF4757)),
    ShopItem(id: 'top_cosmonaut', name: 'Ғарышкер костюмі', price: 1200, category: ShopCategory.top, rarity: Rarity.legendary, requiredLevel: 15, icon: Icons.rocket_launch_rounded, color: Color(0xFF2D1B69), isNew: true),

    // ---- Төменгі киім ----
    ShopItem(id: 'bottom_jeans', name: 'Джинсы', price: 100, category: ShopCategory.bottom, icon: Icons.straighten_rounded, color: Color(0xFF3451C6)),
    ShopItem(id: 'bottom_shorts_sport', name: 'Спорт шортысы', price: 80, category: ShopCategory.bottom, icon: Icons.straighten_rounded, color: Color(0xFF6B7280)),
    ShopItem(id: 'bottom_pants_school', name: 'Мектеп шалбары', price: 110, category: ShopCategory.bottom, icon: Icons.straighten_rounded, color: Color(0xFF1A1A4E)),
    ShopItem(id: 'bottom_pants_gold', name: 'Алтын шалбар', price: 400, category: ShopCategory.bottom, rarity: Rarity.epic, requiredLevel: 8, icon: Icons.straighten_rounded, color: Color(0xFFF5A623)),
    ShopItem(id: 'bottom_pants_cosmic', name: 'Ғарыш шалбары', price: 600, category: ShopCategory.bottom, rarity: Rarity.epic, requiredLevel: 12, icon: Icons.straighten_rounded, color: Color(0xFF7B61FF)),
    ShopItem(id: 'bottom_skirt_tradition', name: 'Ұлттық белдемше', price: 350, category: ShopCategory.bottom, rarity: Rarity.rare, icon: Icons.straighten_rounded, color: Color(0xFFFF6FA5)),
    ShopItem(id: 'bottom_pants_ninja', name: 'Ниндзя шалбары', price: 900, category: ShopCategory.bottom, rarity: Rarity.legendary, requiredLevel: 18, icon: Icons.straighten_rounded, color: Color(0xFF2D2D5F), isNew: true),
    ShopItem(id: 'bottom_shorts_summer', name: 'Жазғы шорты', price: 90, category: ShopCategory.bottom, icon: Icons.straighten_rounded, color: Color(0xFF00D9FF)),

    // ---- Бас киім ----
    ShopItem(id: 'hat_cap_blue', name: 'Көк кепка', price: 80, category: ShopCategory.hat, icon: Icons.sports_baseball_rounded, color: Color(0xFF4A6CF7)),
    ShopItem(id: 'hat_cap_red', name: 'Қызыл кепка', price: 80, category: ShopCategory.hat, icon: Icons.sports_baseball_rounded, color: Color(0xFFFF4757)),
    ShopItem(id: 'hat_takiya', name: 'Тақия', price: 200, category: ShopCategory.hat, rarity: Rarity.rare, icon: Icons.brightness_5_rounded, color: Color(0xFFD4860A), isNew: true),
    ShopItem(id: 'hat_borik', name: 'Бөрік', price: 450, category: ShopCategory.hat, rarity: Rarity.epic, requiredLevel: 7, icon: Icons.ac_unit_rounded, color: Color(0xFF8B5A2B)),
    ShopItem(id: 'hat_crown_gold', name: 'Алтын тәж', price: 2000, category: ShopCategory.hat, rarity: Rarity.legendary, requiredLevel: 25, icon: Icons.workspace_premium_rounded, color: Color(0xFFFFD700)),
    ShopItem(id: 'hat_beanie_winter', name: 'Қысқы бөкебай', price: 100, category: ShopCategory.hat, icon: Icons.ac_unit_rounded, color: Color(0xFF00C48C)),
    ShopItem(id: 'hat_graduate', name: 'Бітіруші қалпағы', price: 300, category: ShopCategory.hat, rarity: Rarity.rare, requiredLevel: 5, icon: Icons.school_rounded, color: Color(0xFF1A1A4E)),
    ShopItem(id: 'hat_helmet_space', name: 'Ғарыш дулығасы', price: 1000, category: ShopCategory.hat, rarity: Rarity.legendary, requiredLevel: 15, icon: Icons.sports_motorsports_rounded, color: Color(0xFF7B61FF)),
    ShopItem(id: 'hat_wizard', name: 'Сиқыршы қалпағы', price: 700, category: ShopCategory.hat, rarity: Rarity.epic, requiredLevel: 10, icon: Icons.auto_fix_high_rounded, color: Color(0xFF2D1B69)),

    // ---- Аксессуар ----
    ShopItem(id: 'acc_glasses_sun', name: 'Күн көзілдірігі', price: 120, category: ShopCategory.accessory, icon: Icons.visibility_rounded, color: Color(0xFF1A1A4E)),
    ShopItem(id: 'acc_glasses_smart', name: 'Ақылды көзілдірік', price: 350, category: ShopCategory.accessory, rarity: Rarity.rare, icon: Icons.visibility_rounded, color: Color(0xFF00D9FF)),
    ShopItem(id: 'acc_backpack', name: 'Рюкзак', price: 150, category: ShopCategory.accessory, icon: Icons.backpack_rounded, color: Color(0xFF4A6CF7)),
    ShopItem(id: 'acc_scarf_gold', name: 'Алтын мойынорағыш', price: 250, category: ShopCategory.accessory, rarity: Rarity.rare, icon: Icons.gesture_rounded, color: Color(0xFFF5A623)),
    ShopItem(id: 'acc_watch', name: 'Қол сағаты', price: 300, category: ShopCategory.accessory, rarity: Rarity.rare, requiredLevel: 5, icon: Icons.watch_rounded, color: Color(0xFF6B7280)),
    ShopItem(id: 'acc_medal_eagle', name: 'Бүркіт медальоны', price: 600, category: ShopCategory.accessory, rarity: Rarity.epic, requiredLevel: 10, icon: Icons.military_tech_rounded, color: Color(0xFFFFD700), isNew: true),
    ShopItem(id: 'acc_cape_hero', name: 'Батыр желбегейі', price: 1100, category: ShopCategory.accessory, rarity: Rarity.legendary, requiredLevel: 18, icon: Icons.flag_rounded, color: Color(0xFFFF4757)),
    ShopItem(id: 'acc_headphones', name: 'Құлаққап', price: 200, category: ShopCategory.accessory, icon: Icons.headphones_rounded, color: Color(0xFF7B61FF)),
    ShopItem(id: 'acc_dombyra', name: 'Домбыра', price: 900, category: ShopCategory.accessory, rarity: Rarity.epic, requiredLevel: 12, icon: Icons.music_note_rounded, color: Color(0xFFD4860A), isNew: true),
    ShopItem(id: 'acc_shield_oyu', name: 'Ою-өрнекті қалқан', price: 1300, category: ShopCategory.accessory, rarity: Rarity.legendary, requiredLevel: 20, icon: Icons.shield_rounded, color: Color(0xFF2D1B69)),

    // ---- Питомец ----
    ShopItem(id: 'pet_cat', name: 'Мысық', price: 300, category: ShopCategory.pet, icon: Icons.pets_rounded, color: Color(0xFFFF8C42)),
    ShopItem(id: 'pet_dog', name: 'Күшік', price: 300, category: ShopCategory.pet, icon: Icons.pets_rounded, color: Color(0xFF8B5A2B)),
    ShopItem(id: 'pet_rabbit', name: 'Қоян', price: 250, category: ShopCategory.pet, icon: Icons.cruelty_free_rounded, color: Color(0xFF9CA3AF)),
    ShopItem(id: 'pet_owl', name: 'Үкі', price: 500, category: ShopCategory.pet, rarity: Rarity.rare, requiredLevel: 5, icon: Icons.nights_stay_rounded, color: Color(0xFF6B7280)),
    ShopItem(id: 'pet_fox', name: 'Түлкі', price: 550, category: ShopCategory.pet, rarity: Rarity.rare, requiredLevel: 6, icon: Icons.pets_rounded, color: Color(0xFFFF8C42), isNew: true),
    ShopItem(id: 'pet_eagle', name: 'Бүркіт', price: 1000, category: ShopCategory.pet, rarity: Rarity.epic, requiredLevel: 10, icon: Icons.flutter_dash_rounded, color: Color(0xFFD4860A), isNew: true),
    ShopItem(id: 'pet_wolf', name: 'Қасқыр', price: 1200, category: ShopCategory.pet, rarity: Rarity.epic, requiredLevel: 12, icon: Icons.pets_rounded, color: Color(0xFF2D2D5F)),
    ShopItem(id: 'pet_snow_leopard', name: 'Ақ барыс', price: 2500, category: ShopCategory.pet, rarity: Rarity.legendary, requiredLevel: 20, icon: Icons.pets_rounded, color: Color(0xFFEEF2FF), isNew: true),
    ShopItem(id: 'pet_dragon', name: 'Айдаһар', price: 3000, category: ShopCategory.pet, rarity: Rarity.legendary, requiredLevel: 25, icon: Icons.local_fire_department_rounded, color: Color(0xFF7B61FF), isNew: true),
    ShopItem(id: 'pet_hamster', name: 'Атжалман', price: 150, category: ShopCategory.pet, icon: Icons.cruelty_free_rounded, color: Color(0xFFF5A623)),
    ShopItem(id: 'pet_parrot', name: 'Тоты құс', price: 400, category: ShopCategory.pet, rarity: Rarity.rare, icon: Icons.flutter_dash_rounded, color: Color(0xFF00C48C)),
    ShopItem(id: 'pet_turtle', name: 'Тасбақа', price: 200, category: ShopCategory.pet, icon: Icons.cruelty_free_rounded, color: Color(0xFF00C48C)),
  ];
}
