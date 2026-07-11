import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material 3 тақырыбы — «Eagle Wings» токендерінен құрастырылған.
/// Жарық және қараңғы (dark mode) нұсқалары бір құрастырушыдан шығады.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Бейтарап (режимге тәуелді) түстер — жаһандық күйді өзгертпей,
    // ашық/қараңғы константалардан тікелей таңдаймыз.
    final surface = isDark ? AppColors.surfaceDark : AppColors.white;
    final bg = isDark ? AppColors.bgDark : AppColors.dawnBg;
    final ink = isDark ? AppColors.inkDark : AppColors.nightInk;
    final border = isDark ? AppColors.borderDark : AppColors.cloudBorder;
    final muted = isDark ? AppColors.mutedDark : AppColors.mist;
    final disabled = isDark ? AppColors.disabledDark : AppColors.disabledFill;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.eagleBlue,
        brightness: brightness,
        primary: AppColors.eagleBlue,
        secondary: AppColors.steppeGold,
        tertiary: AppColors.cosmicPurple,
        error: AppColors.dangerCoral,
        surface: surface,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: bg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.h3.copyWith(color: ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          backgroundColor: AppColors.eagleBlue,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: disabled,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rFull),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          foregroundColor: AppColors.eagleBlue,
          side: const BorderSide(color: AppColors.eagleBlue, width: 2),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rFull),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.eagleBlue,
          textStyle: AppTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: AppTypography.body.copyWith(color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4,
          vertical: AppSpacing.sp4,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: const BorderSide(color: AppColors.eagleBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide:
              const BorderSide(color: AppColors.dangerCoral, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide:
              const BorderSide(color: AppColors.dangerCoral, width: 1.5),
        ),
        errorStyle:
            AppTypography.caption.copyWith(color: AppColors.dangerCoral),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: AppTypography.body.copyWith(color: surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
        titleTextStyle: AppTypography.h2.copyWith(color: ink),
        contentTextStyle: AppTypography.body.copyWith(color: ink),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: true,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.eagleBlue
              : border,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.eagleBlue,
        linearTrackColor: border,
      ),
    );
  }
}
