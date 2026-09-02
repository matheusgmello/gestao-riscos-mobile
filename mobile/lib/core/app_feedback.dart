import 'package:flutter/material.dart';

import 'app_colors.dart';

void mostrarErro(BuildContext context, Object erro) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$erro'),
      backgroundColor: AppColors.error,
    ));
}

void mostrarOk(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Diálogo de confirmação sim/não. Retorna `true` se confirmado.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String confirmar = 'Confirmar',
  bool destrutivo = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: destrutivo
              ? TextButton.styleFrom(foregroundColor: AppColors.error)
              : null,
          child: Text(confirmar),
        ),
      ],
    ),
  );
  return r ?? false;
}
