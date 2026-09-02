import 'package:flutter/material.dart';

import '../core/nivel_risco.dart';
import '../data/models/dashboard_model.dart';

/// Matriz de risco residual 5×5. Linhas = impacto (5 no topo → 1),
/// colunas = probabilidade (1 → 5). Cor da célula pela faixa do score.
class MatrizRisco extends StatelessWidget {
  const MatrizRisco({super.key, required this.celulas});

  final List<CelulaMatriz> celulas;

  int _qtd(int prob, int imp) {
    for (final c in celulas) {
      if (c.probabilidade == prob && c.impacto == imp) return c.quantidade;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const impactos = [5, 4, 3, 2, 1];
    const probs = [1, 2, 3, 4, 5];
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Impacto (linhas) × Probabilidade (colunas)',
            style: labelStyle,
          ),
        ),
        const SizedBox(height: 6),
        for (final imp in impactos)
          Row(
            children: [
              SizedBox(
                width: 16,
                child: Text(
                  '$imp',
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ),
              for (final prob in probs)
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: _Celula(
                        quantidade: _qtd(prob, imp),
                        score: prob * imp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        Row(
          children: [
            const SizedBox(width: 16),
            for (final prob in probs)
              Expanded(
                child: Text(
                  '$prob',
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Celula extends StatelessWidget {
  const _Celula({required this.quantidade, required this.score});

  final int quantidade;
  final int score;

  @override
  Widget build(BuildContext context) {
    final cor = FaixaNivel.of(score).cor;
    final ativa = quantidade > 0;
    return Container(
      decoration: BoxDecoration(
        color: cor.withValues(alpha: ativa ? 0.92 : 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withValues(alpha: ativa ? 0.92 : 0.32)),
      ),
      alignment: Alignment.center,
      child: Text(
        ativa ? '$quantidade' : '',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
