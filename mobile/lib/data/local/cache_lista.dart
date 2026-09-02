import 'dart:convert';

import 'banco.dart';

/// Busca uma lista da API e a guarda no cache estático. Se a rede falhar e
/// houver cache, devolve o cache — para os selects dos formulários (unidades,
/// PDI) funcionarem offline.
Future<List<T>> listaComCache<T>({
  required String chave,
  required Future<List<Map<String, dynamic>>> Function() buscar,
  required T Function(Map<String, dynamic>) fromJson,
}) async {
  try {
    final raw = await buscar();
    await Banco.instance.guardarEstatico(chave, jsonEncode(raw));
    return raw.map(fromJson).toList();
  } catch (e) {
    final cache = await Banco.instance.lerEstatico(chave);
    if (cache == null) rethrow;
    return (jsonDecode(cache) as List)
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }
}
