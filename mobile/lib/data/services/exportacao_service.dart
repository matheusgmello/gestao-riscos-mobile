import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/api_error.dart';
import 'api_client.dart';
import 'risco_service.dart';
import 'token_service.dart';

/// Extrai `filename` de um header `Content-Disposition`.
String? nomeDoContentDisposition(String? header) {
  if (header == null) return null;
  final m = RegExp('filename="?([^";]+)"?').firstMatch(header);
  return m?.group(1)?.trim();
}

/// Baixa um arquivo de exportação da API e grava num arquivo temporário.
class ExportacaoService {
  ExportacaoService(TokenService tokens) : _client = ApiClient(tokens);

  final ApiClient _client;

  Future<File> _baixar(
    String path, {
    Map<String, dynamic>? query,
    required String nomePadrao,
  }) => comApiError(() async {
    final res = await _client.dio.get<List<int>>(
      path,
      queryParameters: query,
      options: Options(responseType: ResponseType.bytes),
    );
    final nome =
        nomeDoContentDisposition(res.headers.value('content-disposition')) ??
        nomePadrao;
    final dir = await getTemporaryDirectory();
    final arquivo = File('${dir.path}/$nome');
    await arquivo.writeAsBytes(res.data ?? const []);
    return arquivo;
  });

  Future<File> listaExcel(FiltroRisco filtro) => _baixar(
    '/api/riscos/planos/exportar-excel/',
    query: filtro.toQuery(1)..remove('page'),
    nomePadrao: 'riscos.xlsx',
  );

  Future<File> relatorioPdf(FiltroRisco filtro) => _baixar(
    '/api/riscos/planos/exportar-relatorio/',
    query: filtro.toQuery(1)..remove('page'),
    nomePadrao: 'relatorio-gerencial.pdf',
  );

  Future<File> riscoExcel(String uuid) => _baixar(
    '/api/riscos/planos/$uuid/exportar-excel/',
    nomePadrao: 'risco-$uuid.xlsx',
  );

  Future<File> riscoPdf(String uuid) => _baixar(
    '/api/riscos/planos/$uuid/exportar-pdf/',
    nomePadrao: 'risco-$uuid.pdf',
  );
}
