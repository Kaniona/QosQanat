import 'package:flutter/material.dart';

/// Аралық токендері (4-48 px сеткасы).
abstract final class AppSpacing {
  static const double sp1 = 4;
  static const double sp2 = 8;
  static const double sp3 = 12;
  static const double sp4 = 16;
  static const double sp5 = 20;
  static const double sp6 = 24;
  static const double sp8 = 32;
  static const double sp10 = 40;
  static const double sp12 = 48;

  /// Экранның стандартты шеткі өрісі.
  static const EdgeInsets screenPadding = EdgeInsets.all(sp6);
  static const EdgeInsets cardPadding = EdgeInsets.all(sp4);
}

/// Бұрыш радиустары (12 — 999).
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;

  static final BorderRadius rSm = BorderRadius.circular(sm);
  static final BorderRadius rMd = BorderRadius.circular(md);
  static final BorderRadius rLg = BorderRadius.circular(lg);
  static final BorderRadius rXl = BorderRadius.circular(xl);
  static final BorderRadius rFull = BorderRadius.circular(full);
}

/// Компоненттердің бекітілген өлшемдері.
abstract final class AppSizes {
  static const double buttonHeight = 56;
  static const double inputHeight = 56;
  static const double iconButton = 48;
  static const double bottomNavHeight = 96;
  static const double raisedTab = 60;
  static const double hudLevelBadge = 48;
  static const double hudPillHeight = 38;
  static const double hudAvatar = 44;
  static const double nodeSize = 52;
  static const double bossNodeSize = 62;
  static const double otpBox = 64;
}
