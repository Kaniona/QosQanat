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

  // ============================================================
  //  Жарық ↔ Қараңғы (dark mode) семантикалық токендері
  //  Бренд түстері (eagleBlue, steppeGold, …) екі режимде де тұрақты.
  //  Тек бейтарап беттер мен мәтін реңктері ауысады.
  //  [brightness] қосымша түбірінде орнатылады (main.dart).
  // ============================================================
  static Brightness brightness = Brightness.light;
  static bool get _dark => brightness == Brightness.dark;

  // Премиум қараңғы палитра (таза қара емес — индиго реңкті).
  static const bgDark = Color(0xFF14151E); // scaffold фоны
  static const surfaceDark = Color(0xFF1E2034); // карта/парақ
  static const inkDark = Color(0xFFECEDF7); // негізгі мәтін
  static const inkSoftDark = Color(0xFFB7BAD0); // қосымша мәтін
  static const mutedDark = Color(0xFF7B8099); // hint мәтін
  static const borderDark = Color(0xFF2C2E46); // шекара/бөлгіш
  static const disabledDark = Color(0xFF3A3D55);
  static const tintBlueDark = Color(0xFF23284D);
  static const tintPurpleDark = Color(0xFF29234F);
  static const tintGoldDark = Color(0xFF3A2F18);
  static const tintSunsetDark = Color(0xFF3A2A1B);
  static const tintRoseDark = Color(0xFF3A2331);
  static const tintJadeDark = Color(0xFF12352B);
  static const tintCoralDark = Color(0xFF3A2026);

  /// Бет фоны (scaffold).
  static Color get bg => _dark ? bgDark : dawnBg;

  /// Карта/парақ/енгізу беті.
  static Color get surface => _dark ? surfaceDark : white;

  /// Негізгі мәтін мен белгішелер.
  static Color get ink => _dark ? inkDark : nightInk;

  /// Қосымша (екінші дәрежелі) мәтін.
  static Color get inkSoft => _dark ? inkSoftDark : slate;

  /// Бәсең мәтін / hint.
  static Color get muted => _dark ? mutedDark : mist;

  /// Шекара мен бөлгіштер.
  static Color get border => _dark ? borderDark : cloudBorder;

  /// Өшірілген элемент толтыруы.
  static Color get disabled => _dark ? disabledDark : disabledFill;

  /// Түрлі-түсті чип/pill фондары (ашық реңктер).
  static Color get tintBlue => _dark ? tintBlueDark : eagleBlueLight;
  static Color get tintPurple => _dark ? tintPurpleDark : cosmicPurpleLight;
  static Color get tintGold => _dark ? tintGoldDark : steppeGoldLight;
  static Color get tintSunset => _dark ? tintSunsetDark : sunsetLight;
  static Color get tintRose => _dark ? tintRoseDark : nazymRoseLight;

  /// Дұрыс/қате жауап тінттері (жасыл/қызыл) — режимге сезімтал.
  /// Жарықта нәзік пастель, қараңғыда терең реңк — мәтін екеуінде де оқылады.
  static Color get tintJade => _dark ? tintJadeDark : const Color(0xFFE0FAF2);
  static Color get tintCoral => _dark ? tintCoralDark : const Color(0xFFFFEBEE);

  /// Алтын тінт үстіндегі мәтін: жарықта қою алтын, қараңғыда ашық алтын.
  static Color get onTintGold => _dark ? steppeGold : steppeGoldDeep;

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

  // ============================================================
  //  Премиум hero градиенттері (түрлі-түсті бас карталар)
  //  Ақ мәтінмен қолдануға арналған — балаға жарқын, ересекке сапалы.
  // ============================================================

  /// Қыран hero — көк → күлгін бай (басты бет, профиль бас картасы).
  static const heroEagle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C7BFF), Color(0xFF4A6CF7), Color(0xFF7B61FF)],
    stops: [0, .52, 1],
  );

  /// Алтын hero — XP / деңгей / марапат бас картасы.
  static const heroGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC24B), Color(0xFFF5A623), Color(0xFFE6890C)],
    stops: [0, .5, 1],
  );

  /// Назым hero — қызғылт → күлгін (Назым серігі).
  static const heroRose = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8FB8), Color(0xFFFF6FA5), Color(0xFF9B5CFF)],
    stops: [0, .5, 1],
  );

  /// Жасыл hero — жетістік / streak.
  static const heroJade = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2BD9A6), Color(0xFF00C48C), Color(0xFF00A87A)],
    stops: [0, .5, 1],
  );

  /// Жұмсақ таңғы фон градиенті (scaffold астына нәзік жылы реңк).
  static LinearGradient get dawnVeil => _dark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF181A26), bgDark],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1F4FF), dawnBg],
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

  /// Премиум карта көлеңкесі — үлкен, бәсең, режимге сезімтал.
  /// Жарықта көгілдір реңкті жұмсақ, қараңғыда таза қара тереңдік.
  static List<BoxShadow> get cardShadow => _dark
      ? const [
          // Қараңғыда: тереңдік үшін таза қара, екі қабат.
          BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 12)),
          BoxShadow(color: Color(0x26000000), blurRadius: 3, offset: Offset(0, 1)),
        ]
      : const [
          // Жарықта: clay тереңдігі — жанасу + орта + кең көгілдір аура.
          BoxShadow(color: Color(0x0A1A1A4E), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x121A1A4E), blurRadius: 16, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x0F4A6CF7), blurRadius: 38, offset: Offset(0, 18)),
        ];

  /// Кез келген түстің жұмсақ түрлі-түсті жарқылы (hero/батырма астына).
  static List<BoxShadow> glow(
    Color color, {
    double opacity = .35,
    double blur = 26,
    double y = 12,
    double spread = 0,
  }) =>
      [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: blur,
          offset: Offset(0, y),
          spreadRadius: spread,
        ),
      ];
}
