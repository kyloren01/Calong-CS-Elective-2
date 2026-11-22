import 'package:flutter/material.dart';

/// The brand: warm orange on clean neutrals, with Plus Jakarta Sans.
class AppColors {
  const AppColors._();

  /// For accents and artwork.
  static const orange = Color(0xFFFFA21A);

  /// For buttons and prices. White text on it is easy to read.
  static const burntOrange = Color(0xFFC2410C);

  static const charcoal = Color(0xFF222831);
}

ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.burntOrange,
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFFFFB066) : AppColors.burntOrange,
        onPrimary: dark ? const Color(0xFF3B1500) : Colors.white,
        primaryContainer: dark
            ? const Color(0xFF5A260C)
            : const Color(0xFFFFE4D4),
        onPrimaryContainer: dark
            ? const Color(0xFFFFDCC7)
            : const Color(0xFF5A1D05),
        secondary: AppColors.orange,
        onSecondary: AppColors.charcoal,
        secondaryContainer: dark
            ? const Color(0xFF4A3309)
            : const Color(0xFFFFEDCF),
        onSecondaryContainer: dark
            ? const Color(0xFFFFE0AE)
            : const Color(0xFF4A2F00),
        tertiary: dark ? const Color(0xFF7BD8C7) : const Color(0xFF0F766E),
        onTertiary: dark ? const Color(0xFF003731) : Colors.white,
        tertiaryContainer: dark
            ? const Color(0xFF0B4A43)
            : const Color(0xFFD3F5EE),
        onTertiaryContainer: dark
            ? const Color(0xFFBFF0E6)
            : const Color(0xFF0A4841),
        surface: dark ? const Color(0xFF1B1E24) : Colors.white,
        onSurface: dark ? const Color(0xFFECEEF2) : AppColors.charcoal,
        onSurfaceVariant: dark
            ? const Color(0xFFB4BAC4)
            : const Color(0xFF5B6470),
        outline: dark ? const Color(0xFF5A616D) : const Color(0xFFB9BFC9),
        outlineVariant: dark
            ? const Color(0xFF33383F)
            : const Color(0xFFE1E4E9),
        surfaceContainerLowest: dark ? const Color(0xFF111318) : Colors.white,
        surfaceContainerLow: dark
            ? const Color(0xFF1B1E24)
            : const Color(0xFFFAFAFB),
        surfaceContainer: dark
            ? const Color(0xFF1B1E24)
            : const Color(0xFFFFFFFF),
        surfaceContainerHigh: dark
            ? const Color(0xFF23272E)
            : const Color(0xFFFFFFFF),
        surfaceContainerHighest: dark
            ? const Color(0xFF2C3139)
            : const Color(0xFFEDEFF2),
        surfaceTint: Colors.transparent,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Plus Jakarta Sans',
  );

  TextStyle? weight(TextStyle? style, FontWeight value, [double? spacing]) =>
      style?.copyWith(fontWeight: value, letterSpacing: spacing);

  // The plain theme has colors and the font but no text sizes yet.
  final text = Typography.englishLike2021.merge(base.textTheme);
  final textTheme = text.copyWith(
    headlineMedium: weight(text.headlineMedium, FontWeight.w800, -0.6),
    headlineSmall: weight(text.headlineSmall, FontWeight.w800, -0.4),
    titleLarge: weight(text.titleLarge, FontWeight.w800, -0.3),
    titleMedium: weight(text.titleMedium, FontWeight.w700, 0),
    titleSmall: weight(text.titleSmall, FontWeight.w700, 0),
    labelLarge: weight(text.labelLarge, FontWeight.w700, 0.1),
    labelMedium: weight(text.labelMedium, FontWeight.w600, 0.1),
    labelSmall: weight(text.labelSmall, FontWeight.w600, 0.1),
  );

  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF111318)
        : const Color(0xFFF4F5F7),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontSize: 20,
      ),
      shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: rounded,
        minimumSize: const Size(64, 44),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: rounded,
        minimumSize: const Size(64, 44),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: rounded),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: inputBorder(scheme.outline),
      enabledBorder: inputBorder(scheme.outline),
      focusedBorder: inputBorder(scheme.primary, 2),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error, 2),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surface,
      selectedColor: scheme.primary,
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      showCheckmark: false,
      labelStyle: textTheme.labelLarge,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelType: NavigationRailLabelType.all,
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: scheme.onSurface,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: rounded,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
  );
}
