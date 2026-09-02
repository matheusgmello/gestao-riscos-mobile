import '../../core/api_error.dart';
import '../models/pdi_model.dart';
import 'api_client.dart';
import 'token_service.dart';

/// Estrutura do PDI — endpoints sem paginação, usados nos selects do form.
class PdiService {
  PdiService(TokenService tokens) : _client = ApiClient(tokens);

  final ApiClient _client;

  Future<List<T>> _lista<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) => comApiError(() async {
    final res = await _client.dio.get(path);
    return (res.data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  });

  Future<List<DesafioPdi>> desafios() =>
      _lista('/api/riscos/desafios/', DesafioPdi.fromJson);

  Future<List<ObjetivoPdi>> objetivos() =>
      _lista('/api/riscos/objetivos/', ObjetivoPdi.fromJson);

  Future<List<Macroprocesso>> macroprocessos() =>
      _lista('/api/riscos/macroprocessos/', Macroprocesso.fromJson);
}
