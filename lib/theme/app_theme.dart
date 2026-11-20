import 'package:flutter/material.dart';

/// The orange look from the Prelim shop.
class AppColors {
  static const orange = Color(0xFFFFA21A);
  static const deepOrange = Color(0xFFFF6B35);
  static const charcoal = Color(0xFF222831);
}

ThemeData buildShopTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: brightness,
      ).copyWith(
        primary: AppColors.orange,
        secondary: AppColors.deepOrange,
        surface: isDark ? const Color(0xFF1D2026) : Colors.white,
        onPrimary: Colors.white,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );

  return base.copyWith(
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF111318)
        : const Color(0xFFF0F2F5),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF171A20) : Colors.white,
      foregroundColor: isDark ? Colors.white : AppColors.charcoal,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        // Start from the theme's button text so the font family is kept.
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
