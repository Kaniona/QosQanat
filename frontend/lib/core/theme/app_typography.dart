import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Nunito типографиясы (қазақ кириллицасын толық қолдайды).
/// Токендер: handoff README §1 кестесінен.
abstract final class AppTypography {
  static TextStyle _nunito(
    double size,
    FontWeight weight, {
    Color color = AppColors.nightInk,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// 40 / 900 — hero, қош келдің экраны
  static TextStyle get displayHuge =>
      _nunito(40, FontWeight.w900, letterSpacing: -0.8);

  /// 32 / 900 — үлкен тақырыптар
  static TextStyle get displayLarge =>
      _nunito(32, FontWeight.w900, letterSpacing: -0.64);

  /// 36 / 900 — деңгей / монета / ақыл сандары
  static TextStyle get numberDisplay =>
      _nunito(36, FontWeight.w900, letterSpacing: -0.72);

  /// 28 / 800 — экран тақырыптары
  static TextStyle get h1 => _nunito(28, FontWeight.w800, letterSpacing: -0.28);

  /// 24 / 800 — секция тақырыптары
  static TextStyle get h2 => _nunito(24, FontWeight.w800, letterSpacing: -0.24);

  /// 20 / 700 — карта тақырыптары
  static TextStyle get h3 => _nunito(20, FontWeight.w700);

  /// 18 / 600 — жетекші мәтін
  static TextStyle get bodyLarge => _nunito(18, FontWeight.w600, height: 1.5);

  /// 16 / 600 — әдепкі мәтін
  static TextStyle get body => _nunito(16, FontWeight.w600, height: 1.5);

  /// 14 / 600 — қосалқы мәтін
  static TextStyle get bodySmall =>
      _nunito(14, FontWeight.w600, color: AppColors.slate, height: 1.45);

  /// 12 / 700 — мета / даталар
  static TextStyle get caption =>
      _nunito(12, FontWeight.w700, color: AppColors.slate);

  /// 11 / 800 — таб жазулары
  static TextStyle get tabLabel => _nunito(11, FontWeight.w800);

  /// 16 / 800 — батырма мәтіні
  static TextStyle get button =>
      _nunito(16, FontWeight.w800, color: AppColors.white);
}
