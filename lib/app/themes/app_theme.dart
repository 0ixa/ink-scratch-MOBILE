import 'package:flutter/material.dart';
import 'app_colors.dart';

/// InkScratch Theme — dark-first, mirrors the CSS design system in globals.css.
/// Uses Syne as the body font (closest available match; add via google_fonts).
class AppTheme {
  AppTheme._();

  // ── Input decoration shared between both themes ──────────────────────────
  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color labelColor,
    required Color hintColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      labelStyle: TextStyle(color: labelColor, fontSize: 15),
      hintStyle: TextStyle(color: hintColor, fontSize: 15),
      errorStyle: const TextStyle(color: AppColors.red, fontSize: 13),
      prefixIconColor: AppColors.orange,
      suffixIconColor: AppColors.orange,
    );
  }

  // ── DARK THEME (default) ─────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    canvasColor: AppColors.bgDark,
    cardColor: AppColors.bgCardDark,
    dividerColor: AppColors.borderDark,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.orange,
      secondary: AppColors.red,
      surface: AppColors.bgCardDark,
      error: AppColors.red,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      outline: AppColors.borderDark,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.textPrimaryDark,
      centerTitle: false,
    ),

    textTheme: const TextTheme(
      // Display — used for big titles like "WELCOME BACK"
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimaryDark,
        letterSpacing: 2,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimaryDark,
        letterSpacing: 1.5,
      ),
      // Headlines
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimaryDark,
        letterSpacing: 0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      // Body
      bodyLarge: TextStyle(fontSize: 15, color: AppColors.textPrimaryDark),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.textMutedDark,
        letterSpacing: 0.5,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryDark,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: AppColors.borderDark),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.orange,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),

    inputDecorationTheme: _inputTheme(
      fill: AppColors.bgInputDark,
      border: AppColors.borderDark,
      labelColor: AppColors.textSecondaryDark,
      hintColor: AppColors.textMutedDark,
    ),

    cardTheme: CardThemeData(
      color: AppColors.bgCardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderCardDark),
      ),
      margin: EdgeInsets.zero,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.orange,
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.orange;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: AppColors.borderDark, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgCardDark,
      contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  // ── LIGHT THEME ──────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgLight,
    canvasColor: AppColors.bgLight,
    cardColor: AppColors.bgCardLight,
    dividerColor: AppColors.borderLight,

    colorScheme: const ColorScheme.light(
      primary: AppColors.orange,
      secondary: AppColors.red,
      surface: AppColors.bgCardLight,
      error: AppColors.red,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      outline: AppColors.borderLight,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.textPrimaryLight,
      centerTitle: false,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimaryLight,
        letterSpacing: 2,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimaryLight,
        letterSpacing: 1.5,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimaryLight,
        letterSpacing: 0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: AppColors.textPrimaryLight),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.textMutedLight,
        letterSpacing: 0.5,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryLight,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: AppColors.borderLight),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.orange,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),

    inputDecorationTheme: _inputTheme(
      fill: AppColors.bgInputLight,
      border: AppColors.borderLight,
      labelColor: AppColors.textSecondaryLight,
      hintColor: AppColors.textMutedLight,
    ),

    cardTheme: CardThemeData(
      color: AppColors.bgCardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderCardLight),
      ),
      margin: EdgeInsets.zero,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.orange,
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.orange;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: AppColors.borderLight, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgCardLight,
      contentTextStyle: const TextStyle(color: AppColors.textPrimaryLight),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
