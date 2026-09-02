import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Faixas de nível (produto probabilidade x impacto), iguais às usadas nos
/// analytics do backend.
enum FaixaNivel {
  baixo('Baixo', AppColors.nivelBaixo),
  moderado('Moderado', AppColors.nivelModerado),
  alto('Alto', AppColors.nivelAlto),
  extremo('Extremo', AppColors.nivelExtremo);

  const FaixaNivel(this.rotulo, this.cor);
  final String rotulo;
  final Color cor;

  static FaixaNivel of(int nivel) {
    if (nivel >= 20) return FaixaNivel.extremo;
    if (nivel >= 12) return FaixaNivel.alto;
    if (nivel >= 4) return FaixaNivel.moderado;
    return FaixaNivel.baixo;
  }
}
