import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Preferência de tema (claro/escuro/sistema). Guardada num arquivinho no
/// diretório de documentos — sobrevive ao logout (que limpa o secure storage
/// e o banco local).
class Preferencias {
  Preferencias._();

  static final tema = ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<File> _arquivo() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'tema.txt'));
  }

  static Future<void> carregar() async {
    try {
      final f = await _arquivo();
      if (!await f.exists()) return;
      tema.value = ThemeMode.values.byName((await f.readAsString()).trim());
    } catch (_) {
      // mantém o padrão (sistema)
    }
  }

  static Future<void> definirTema(ThemeMode modo) async {
    tema.value = modo;
    try {
      await (await _arquivo()).writeAsString(modo.name);
    } catch (_) {}
  }
}
