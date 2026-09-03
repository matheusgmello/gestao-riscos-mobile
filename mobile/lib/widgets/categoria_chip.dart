import 'package:flutter/material.dart';

/// Pílula da categoria do risco (Operacional, Estratégico, ...).
class CategoriaChip extends StatelessWidget {
  const CategoriaChip(this.categoria, {super.key});

  final String categoria;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cores.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        categoria,
        style: TextStyle(
          fontSize: 12,
          color: cores.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
