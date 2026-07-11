import 'package:flutter/material.dart';

/// Семантикалық белгіше көзі — бүкіл қосымшада бір валюта/ұпай тілі.
///
/// Эмодзи (💰 ⚡ 🔥 🏆) орнына дөңгелетілген Material белгішелері: платформа
/// аралық бірдей көрінеді, түс токендерімен басқарылады әрі айқын (skill §4
/// «no-emoji-icons»). HUD-тағы белгішелермен үйлеседі.
abstract final class AppIcons {
  /// Монета (coins) — HUD-пен бірдей.
  static const IconData coin = Icons.monetization_on_rounded;

  /// XP / тәжірибе.
  static const IconData xp = Icons.bolt_rounded;

  /// Ақыл ұпайы — HUD-пен бірдей.
  static const IconData akyl = Icons.star_rounded;

  /// Streak / күнделікті серия.
  static const IconData streak = Icons.local_fire_department_rounded;

  /// Жүлде / рейтинг.
  static const IconData trophy = Icons.emoji_events_rounded;
}
