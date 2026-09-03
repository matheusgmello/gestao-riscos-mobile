import 'package:flutter/material.dart';

import '../core/nivel_risco.dart';

class NivelBadge extends StatelessWidget {
  const NivelBadge(this.nivel, {super.key, this.compacto = false});

  final int nivel;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final faixa = FaixaNivel.of(nivel);
    // O âmbar do nível "Moderado" não tem contraste com branco.
    final corTexto =
        ThemeData.estimateBrightnessForColor(faixa.cor) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8 : 10,
        vertical: compacto ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: faixa.cor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        compacto ? '$nivel' : '${faixa.rotulo} · $nivel',
        style: TextStyle(
          color: corTexto,
          fontWeight: FontWeight.w600,
          fontSize: compacto ? 12 : 13,
        ),
      ),
    );
  }
}
