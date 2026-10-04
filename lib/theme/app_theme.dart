import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Same brand colors as the mobile app (mech_app) so the admin panel
/// feels like part of the same product — adapted for a light,
/// data-dense desktop layout (admin panels are read constantly, so
/// dark mode isn't worth the extra maintenance here).
class AppColors {
  AppColors._();

  static const primary = Color(0xFF145C5C);
  static const primaryStrong = Color(0xFF0E4747);
  static const onPrimary = Color(0xFFF5F4EF);

  static const accent = Color(0xFFFF9F1C);
  static const onAccent = Color(0xFF1A1200);

  static const danger = Color(0xFFE14B3B);
  static const success = Color(0xFF2E9B5C);
  static const warning = Color(0xFFFF9F1C);

  static const bg = Color(0xFFF5F4EF);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEDEBE2);
  static const border = Color(0x1A141E1C);
  static const borderStrong = Color(0x2E141E1C);

  static const text = Color(0xFF161A19);
  static const textSecondary = Color(0xFF5B6764);
  static const textMuted = Color(0xFF8B968F);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final textTheme = GoogleFonts.interTextTheme();
    final displayFont = GoogleFonts.spaceGroteskTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.accent,
        onSecondary: AppColors.onAccent,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.danger,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: displayFont.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        headlineMedium: displayFont.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        titleLarge: displayFont.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        titleMedium: displayFont.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: AppColors.text),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      dividerColor: AppColors.border,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
