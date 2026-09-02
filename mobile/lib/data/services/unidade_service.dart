import '../../core/api_error.dart';
import '../models/unidade_model.dart';
import 'api_client.dart';
import 'token_service.dart';

class UnidadeService {
  UnidadeService(TokenService tokens) : _client = ApiClient(tokens);

  final ApiClient _client;

  /// `GET /api/usuarios/setores/` — público, sem paginação.
  Future<List<UnidadeModel>> listar() => comApiError(() async {
        final res = await _client.dio.get('/api/usuarios/setores/');
        return (res.data as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(UnidadeModel.fromJson)
            .toList();
      });
}
