import 'package:flutter/material.dart';

/// Paleta base do app. Ajustar quando a identidade visual do sistema web
/// UFSM for definida.
class AppColors {
  static const primary = Color(0xFF1B4B73);
  static const primaryDark = Color(0xFF123650);
  static const primaryLight = Color(0xFF3A6E9C);
  static const primarySurface = Color(0xFFE8F0F7);
  static const textOnPrimary = Colors.white;

  static const background = Color(0xFFF5F6F8);
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF1A1C1E);
  static const textSecondary = Color(0xFF44474A);
  static const textMuted = Color(0xFF74777B);
  static const textHint = Color(0xFF9A9DA1);

  static const border = Color(0xFFD6D9DD);
  static const fieldBg = Color(0xFFF0F2F4);

  static const grey100 = Color(0xFFECEEF0);
  static const grey200 = Color(0xFFD6D9DD);
  static const grey400 = Color(0xFF9A9DA1);

  static const error = Color(0xFFB3261E);
  static const errorSurface = Color(0xFFF9DEDC);

  // Faixas de nível de risco (produto probabilidade x impacto).
  static const nivelBaixo = Color(0xFF2E7D32);
  static const nivelModerado = Color(0xFFF9A825);
  static const nivelAlto = Color(0xFFEF6C00);
  static const nivelExtremo = Color(0xFFC62828);
}
