import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => _build(_schemeLight, Brightness.light);
  static ThemeData get dark => _build(_schemeDark, Brightness.dark);

  /// Deriva a paleta inteira (containers, tons, superfícies) do azul UFSM e
  /// só sobrescreve os papéis que a identidade fixa.
  static final _schemeLight =
      ColorScheme.fromSeed(
        seedColor: AppColors.ufsmAzul,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.ufsmAzul,
        onPrimary: Colors.white,
        primaryContainer: AppColors.lightPrimarySurface,
        onPrimaryContainer: AppColors.lightOnPrimarySurface,
        secondaryContainer: AppColors.lightPrimarySurface,
        onSecondaryContainer: AppColors.lightOnPrimarySurface,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextMuted,
        outline: AppColors.lightOutline,
        surfaceContainerHighest: AppColors.lightContainerAlt,
        error: AppColors.error,
        onError: Colors.white,
      );

  static final _schemeDark =
      ColorScheme.fromSeed(
        seedColor: AppColors.ufsmAzul,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.ufsmAzulEscuro,
        primaryContainer: AppColors.darkPrimarySurface,
        onPrimaryContainer: AppColors.darkOnPrimarySurface,
        secondaryContainer: AppColors.darkPrimarySurface,
        onSecondaryContainer: AppColors.darkOnPrimarySurface,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextMuted,
        outline: AppColors.darkOutline,
        surfaceContainerHighest: AppColors.darkContainerAlt,
      );

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final claro = brightness == Brightness.light;
    final appBarBg = claro ? AppColors.ufsmAzul : scheme.surfaceContainer;
    final appBarFg = claro ? Colors.white : scheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: claro
          ? AppColors.lightBackground
          : AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: claro ? 0 : 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: appBarFg,
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
        fillColor: claro ? AppColors.lightField : AppColors.darkField,
        alignLabelWithHint: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
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
          side: BorderSide(
            color: claro ? AppColors.lightContainerAlt : AppColors.darkBorder,
          ),
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
