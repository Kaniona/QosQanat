import 'package:flutter/material.dart';

/// QosQanat «Eagle Wings» түс жүйесі.
/// Дереккөз: designs/qosqanat-tokens.css
abstract final class AppColors {
  // ---- Brand: Eagle Blue (негізгі) ----
  static const eagleBlue = Color(0xFF4A6CF7);
  static const eagleBlueLight = Color(0xFFEEF2FF);
  static const eagleBlueDark = Color(0xFF3451C6);

  // ---- Steppe Gold (XP / энергия) ----
  static const steppeGold = Color(0xFFF5A623);
  static const steppeGoldLight = Color(0xFFFFF4E0);
  static const steppeGoldDeep = Color(0xFFD4860A);
  static const goldBright = Color(0xFFFFD700);

  // ---- Cosmic Purple (ақыл / премиум) ----
  static const cosmicPurple = Color(0xFF7B61FF);
  static const cosmicPurpleLight = Color(0xFFF0EBFF);

  // ---- Семантикалық ----
  static const successJade = Color(0xFF00C48C);
  static const dangerCoral = Color(0xFFFF4757);
  static const warningSunset = Color(0xFFFF8C42);
  static const sunsetLight = Color(0xFFFFE9D6);

  // ---- Бейтарап ----
  static const nightInk = Color(0xFF1A1A4E);
  static const charcoal = Color(0xFF2D2D5F);
  static const slate = Color(0xFF6B7280);
  static const mist = Color(0xFF9CA3AF);
  static const cloudBorder = Color(0xFFE8ECFF);
  static const white = Color(0xFFFFFFFF);
  static const dawnBg = Color(0xFFFAFBFF);
  static const indigoDeep = Color(0xFF2D1B69);

  // ---- Пән акценттері (Оқу картасы) ----
  static const accentMath = eagleBlue;
  static const accentCS = cosmicPurple;
  static const accentCSCyan = Color(0xFF00D9FF);
  static const accentEng = steppeGold;
  static const accentEngSun = warningSunset;
  static const accentKazakh = successJade;
  static const accentPhysics = Color(0xFFFF6FA5);

  // ---- Назым акценті ----
  static const nazymRose = Color(0xFFFF6FA5);
  static const nazymRoseLight = Color(0xFFFFEDF3);

  // ---- Disabled ----
  static const disabledFill = Color(0xFFC7CEEC);

  // ---- Градиенттер ----
  /// Ascension — алтын → көк → индиго (бренд саяхаты, тік)
  static const ascension = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [steppeGold, eagleBlue, indigoDeep],
    stops: [0, .55, 1],
  );

  /// Eagle — негізгі батырмалар
  static const eagleGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [eagleBlue, cosmicPurple],
  );

  /// Gold Soar — премиум / деңгей белгісі / сыйлық алу
  static const goldSoar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [steppeGold, goldBright],
  );

  /// Cosmic Night — қараңғы беттер (drawer header, splash)
  static const cosmicNight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [nightInk, indigoDeep],
  );

  /// Оқу картасының әлем градиенті: дала → аспан → ғарыш (төменнен жоғары)
  static const mapWorld = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0xFFF5A623),
      Color(0xFFFFB84D),
      Color(0xFF4A6CF7),
      Color(0xFF7B61FF),
      Color(0xFF2D1B69),
      Color(0xFF1A1A4E),
    ],
    stops: [0, .18, .45, .68, .88, 1],
  );

  // ---- Көлеңкелер (жұмсақ, көгілдір реңкті) ----
  static const sh1 = [
    BoxShadow(color: Color(0x144A6CF7), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A1A1A4E), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const sh2 = [
    BoxShadow(color: Color(0x1A4A6CF7), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0D1A1A4E), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const sh3 = [
    BoxShadow(color: Color(0x244A6CF7), blurRadius: 28, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0F1A1A4E), blurRadius: 8, offset: Offset(0, 4)),
  ];
  static const sh4 = [
    BoxShadow(color: Color(0x2E4A6CF7), blurRadius: 48, offset: Offset(0, 20)),
    BoxShadow(color: Color(0x141A1A4E), blurRadius: 16, offset: Offset(0, 8)),
  ];
  static const goldGlow = [
    BoxShadow(color: Color(0x73F5A623), blurRadius: 20, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x4DFFD700), blurRadius: 0, spreadRadius: 1),
  ];
  static const navShadow = [
    BoxShadow(color: Color(0x1F4A6CF7), blurRadius: 28, offset: Offset(0, -8)),
  ];
  static const raisedTabShadow = [
    BoxShadow(color: Color(0x734A6CF7), blurRadius: 22, offset: Offset(0, 10)),
  ];
}
