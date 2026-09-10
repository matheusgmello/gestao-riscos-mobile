import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Abre a câmera e copia a foto para um arquivo permanente no diretório de
/// documentos do app — sobrevive a fechar o app antes de sincronizar.
/// Devolve o caminho do arquivo, ou `null` se o usuário cancelou.
Future<String?> tirarFotoEvidencia({
  Future<XFile?> Function()? camera,
  Future<Directory> Function()? diretorio,
}) async {
  final tirar = camera ??
      () => ImagePicker().pickImage(
            source: ImageSource.camera,
            maxWidth: 1600,
            imageQuality: 70,
          );
  final foto = await tirar();
  if (foto == null) return null;

  final dir = await (diretorio ?? getApplicationDocumentsDirectory)();
  final ext = p.extension(foto.path).isEmpty ? '.jpg' : p.extension(foto.path);
  final destino = p.join(
    dir.path,
    'evidencias',
    '${DateTime.now().millisecondsSinceEpoch}$ext',
  );
  await Directory(p.dirname(destino)).create(recursive: true);
  await File(foto.path).copy(destino);
  return destino;
}
