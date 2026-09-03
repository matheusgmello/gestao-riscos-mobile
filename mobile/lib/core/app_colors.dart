import 'package:flutter/material.dart';

/// Paleta do app.
///
/// Cores de marca seguem a identidade visual da UFSM (azul institucional,
/// Pantone 654). Se o hex oficial for outro, trocar [ufsmAzul] e derivados.
///
/// As cores dependentes de tema (fundo, superfície, texto, borda) existem em
/// dois conjuntos — `light*` e `dark*` — consumidos por `AppTheme`. Nas telas,
/// prefira `Theme.of(context).colorScheme.*` a estas constantes.
class AppColors {
  // --- Marca UFSM (fixas nos dois temas) ---
  static const ufsmAzul = Color(0xFF164194);
  static const ufsmAzulEscuro = Color(0xFF0E2C6B);
  static const ufsmAzulClaro = Color(0xFF5B84D6);

  /// Compat: telas antigas ainda referenciam `AppColors.primary`.
  static const primary = ufsmAzul;
  static const primaryDark = ufsmAzulEscuro;
  static const primaryLight = ufsmAzulClaro;
  static const textOnPrimary = Colors.white;

  // --- Tema claro ---
  static const lightBackground = Color(0xFFF4F6FA);
  static const lightSurface = Colors.white;
  static const lightPrimarySurface = Color(0xFFE3ECFB);
  static const lightOnPrimarySurface = ufsmAzulEscuro;
  static const lightTextPrimary = Color(0xFF15181C);
  static const lightTextSecondary = Color(0xFF43474E);
  static const lightTextMuted = Color(0xFF71757C);
  static const lightBorder = Color(0xFFD4D9E0);
  static const lightField = Color(0xFFEEF1F5);
  static const lightOutline = Color(0xFF9AA0A8);
  static const lightContainerAlt = Color(0xFFE9ECF1);

  // --- Tema escuro ---
  static const darkBackground = Color(0xFF111318);
  static const darkSurface = Color(0xFF1A1C22);
  static const darkPrimary = Color(0xFF9EC0FF);
  static const darkPrimarySurface = Color(0xFF243356);
  static const darkOnPrimarySurface = Color(0xFFD9E4FF);
  static const darkTextPrimary = Color(0xFFE3E5E9);
  static const darkTextSecondary = Color(0xFFC2C5CC);
  static const darkTextMuted = Color(0xFF8E9299);
  static const darkBorder = Color(0xFF3A3D44);
  static const darkField = Color(0xFF23262D);
  static const darkOutline = Color(0xFF60646C);
  static const darkContainerAlt = Color(0xFF262931);

  // --- Legado: só tema claro. Em código novo use Theme.of(context).colorScheme.
  @Deprecated('use colorScheme.surface') static const background = lightBackground;
  @Deprecated('use colorScheme.surface') static const surface = lightSurface;
  @Deprecated('use colorScheme.primaryContainer')
  static const primarySurface = lightPrimarySurface;
  @Deprecated('use colorScheme.onSurface') static const textPrimary = lightTextPrimary;
  @Deprecated('use colorScheme.onSurfaceVariant')
  static const textSecondary = lightTextSecondary;
  @Deprecated('use colorScheme.onSurfaceVariant')
  static const textMuted = lightTextMuted;
  @Deprecated('use colorScheme.onSurfaceVariant') static const textHint = Color(0xFF9A9DA1);
  @Deprecated('use colorScheme.outline') static const border = lightBorder;
  @Deprecated('use inputDecorationTheme') static const fieldBg = lightField;
  @Deprecated('use colorScheme.surfaceContainerHighest')
  static const grey100 = lightContainerAlt;
  @Deprecated('use colorScheme.outline') static const grey200 = lightBorder;
  @Deprecated('use colorScheme.outline') static const grey400 = lightOutline;

  static const error = Color(0xFFBA1A1A);
  static const errorSurface = Color(0xFFF9DEDC);

  // --- Faixas de nível de risco (iguais nos dois temas). Codificam dado, não
  // marca — constantes de propósito. Para texto sobre elas use
  // ThemeData.estimateBrightnessForColor (o âmbar pede texto escuro).
  static const nivelBaixo = Color(0xFF2E7D32);
  static const nivelModerado = Color(0xFFF9A825);
  static const nivelAlto = Color(0xFFEF6C00);
  static const nivelExtremo = Color(0xFFC62828);
}
