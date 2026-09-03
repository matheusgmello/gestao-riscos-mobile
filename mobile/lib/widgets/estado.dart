import 'package:flutter/material.dart';

import '../core/api_error.dart';

/// Estados de tela compartilhados (vazio / erro / carregando). Uma única
/// aparência para os três em todas as listas.

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.detalhe,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String? detalhe;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return ListView(
      // ListView (não Center) para manter o pull-to-refresh funcionando.
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 96),
        Icon(icone, size: 56, color: cores.outline),
        const SizedBox(height: 12),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (detalhe != null) ...[
          const SizedBox(height: 4),
          Text(
            detalhe!,
            textAlign: TextAlign.center,
            style: TextStyle(color: cores.onSurfaceVariant),
          ),
        ],
        if (acao != null) ...[
          const SizedBox(height: 20),
          Center(child: acao),
        ],
      ],
    );
  }
}

class EstadoErro extends StatelessWidget {
  const EstadoErro({super.key, required this.erro, this.onTentar});

  final Object erro;
  final VoidCallback? onTentar;

  @override
  Widget build(BuildContext context) {
    return EstadoVazio(
      icone: Icons.cloud_off,
      titulo: 'Não foi possível carregar',
      detalhe: mensagemDeErro(erro),
      acao: onTentar == null
          ? null
          : FilledButton.tonalIcon(
              onPressed: onTentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
    );
  }
}

/// Placeholder de lista enquanto carrega — retângulos no lugar dos cards.
class SkeletonLista extends StatelessWidget {
  const SkeletonLista({super.key, this.itens = 6, this.altura = 96});

  final int itens;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: itens,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => Container(
        height: altura,
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
