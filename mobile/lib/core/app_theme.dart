import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => _build(
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ufsmAzul,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightPrimarySurface,
      onPrimaryContainer: AppColors.lightOnPrimarySurface,
      secondary: AppColors.ufsmAzulClaro,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextMuted,
      outline: AppColors.lightOutline,
      surfaceContainerHighest: AppColors.lightContainerAlt,
    ),
    background: AppColors.lightBackground,
    field: AppColors.lightField,
    border: AppColors.lightBorder,
    cardBorder: AppColors.lightContainerAlt,
  );

  static ThemeData get dark => _build(
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.ufsmAzulEscuro,
      primaryContainer: AppColors.darkPrimarySurface,
      onPrimaryContainer: AppColors.darkOnPrimarySurface,
      secondary: AppColors.darkPrimary,
      onSecondary: AppColors.ufsmAzulEscuro,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextMuted,
      outline: AppColors.darkOutline,
      surfaceContainerHighest: AppColors.darkContainerAlt,
    ),
    background: AppColors.darkBackground,
    field: AppColors.darkField,
    border: AppColors.darkBorder,
    cardBorder: AppColors.darkBorder,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color field,
    required Color border,
    required Color cardBorder,
  }) {
    final onPrimaryAppBar = scheme.brightness == Brightness.light
        ? Colors.white
        : scheme.onSurface;
    final appBarBg = scheme.brightness == Brightness.light
        ? AppColors.ufsmAzul
        : scheme.surface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: onPrimaryAppBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onPrimaryAppBar,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        alignLabelWithHint: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
