import 'package:flutter/material.dart';

import 'enums.dart';

/// Дүкен заты (киім / бас киім / аксессуар / питомец).
class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.rarity = Rarity.common,
    this.requiredLevel = 1,
    this.icon = Icons.checkroom_rounded,
    this.color = const Color(0xFF4A6CF7),
    this.isNew = false,
  });

  final String id;
  final String name;
  final int price;
  final ShopCategory category;
  final Rarity rarity;

  /// Сатып алу үшін қажетті деңгей.
  final int requiredLevel;

  /// Зат алдын ала қаралымы (финалды арт келгенше icon-плейсхолдер).
  final IconData icon;
  final Color color;
  final bool isNew;
}
