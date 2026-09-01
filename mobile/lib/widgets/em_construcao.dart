import 'package:flutter/material.dart';

class EmConstrucao extends StatelessWidget {
  const EmConstrucao(this.titulo, this.detalhe, {super.key});

  final String titulo;
  final String detalhe;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48),
              const SizedBox(height: 12),
              Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(detalhe, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
