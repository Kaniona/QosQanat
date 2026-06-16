import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material 3 тақырыбы — «Eagle Wings» токендерінен құрастырылған.
abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.eagleBlue,
        primary: AppColors.eagleBlue,
        secondary: AppColors.steppeGold,
        tertiary: AppColors.cosmicPurple,
        error: AppColors.dangerCoral,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.dawnBg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.nightInk,
        displayColor: AppColors.nightInk,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dawnBg,
        foregroundColor: AppColors.nightInk,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.h3,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          backgroundColor: AppColors.eagleBlue,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.disabledFill,
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
        fillColor: AppColors.white,
        hintStyle: AppTypography.body.copyWith(color: AppColors.mist),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4,
          vertical: AppSpacing.sp4,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide:
              const BorderSide(color: AppColors.cloudBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide:
              const BorderSide(color: AppColors.cloudBorder, width: 1.5),
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
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cloudBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.nightInk,
        contentTextStyle:
            AppTypography.body.copyWith(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
        titleTextStyle: AppTypography.h2,
        contentTextStyle: AppTypography.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: true,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.mist,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.eagleBlue
              : AppColors.cloudBorder,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.eagleBlue,
        linearTrackColor: AppColors.cloudBorder,
      ),
    );
  }
}
