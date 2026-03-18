import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Premium light palette
  static const primary = Color(0xFF047857);           // deep warm emerald
  static const primaryLight = Color(0xFF10B981);      // gradient end
  static const primaryDark = Color(0xFF065F46);       // gradient start / pressed
  static const primaryPale = Color(0xFFD1FAE5);

  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFFAF9F6);        // warm cream
  static const cardBg = Color(0xFFFFFFFF);

  // Text — high contrast
  static const darkText = Color(0xFF0F172A);           // near-black
  static const midText = Color(0xFF475569);
  static const lightText = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2E8F0);

  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);

  // Legacy
  static const darkBlue = darkText;
  static const gold = primary;
  static const cream = background;
  static const white = Color(0xFFFFFFFF);

  // Vivid accents
  static const blue50 = Color(0xFFEFF6FF);
  static const blue600 = Color(0xFF2563EB);
  static const green50 = Color(0xFFD1FAE5);
  static const green600 = Color(0xFF10B981);
  static const orange50 = Color(0xFFFFF7ED);
  static const orange600 = Color(0xFFF97316);
  static const red50 = Color(0xFFFEE2E2);
  static const red600 = Color(0xFFEF4444);
  static const purple50 = Color(0xFFF3E8FF);
  static const purple600 = Color(0xFF8B5CF6);
  static const yellow50 = Color(0xFFFEF9C3);
  static const yellow600 = Color(0xFFF59E0B);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: '.SF Pro Text',
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkText,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: AppColors.darkText,
        displayColor: AppColors.darkText,
        fontFamily: '.SF Pro Text',
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          fontFamily: '.SF Pro Display',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontFamily: '.SF Pro Text', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(fontFamily: '.SF Pro Text', color: AppColors.lightText),
        labelStyle: const TextStyle(fontFamily: '.SF Pro Text', color: AppColors.midText),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: AppColors.surface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
