import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'app_feedback.dart';

/// Gera o arquivo de exportação (com feedback de progresso) e abre o
/// share sheet do sistema.
Future<void> exportarECompartilhar(
  BuildContext context,
  Future<File> Function() gerar,
) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Gerando arquivo...'),
      duration: Duration(seconds: 30),
    ),
  );

  File arquivo;
  try {
    arquivo = await gerar();
  } catch (e) {
    messenger.hideCurrentSnackBar();
    if (context.mounted) mostrarErro(context, e);
    return;
  }
  messenger.hideCurrentSnackBar();

  try {
    await SharePlus.instance.share(ShareParams(files: [XFile(arquivo.path)]));
  } catch (e) {
    if (context.mounted) {
      mostrarErro(context, 'Arquivo salvo, mas o compartilhamento falhou: $e');
    }
  }
}
