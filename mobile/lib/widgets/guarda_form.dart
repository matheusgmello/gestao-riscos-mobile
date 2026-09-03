import 'package:flutter/material.dart';

/// Envolve um form: se [sujo], o back do Android / seta da AppBar pedem
/// confirmação antes de descartar as alterações.
class GuardaForm extends StatelessWidget {
  const GuardaForm({super.key, required this.sujo, required this.child});

  final bool sujo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !sujo,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirmarDescarte(context) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}

Future<bool> confirmarDescarte(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Descartar alterações?'),
      content: const Text('As mudanças não salvas serão perdidas.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Continuar editando'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
  return r ?? false;
}
