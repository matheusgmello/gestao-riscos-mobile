import '../../core/api_error.dart';
import '../models/usuario_model.dart';
import 'api_client.dart';
import 'token_service.dart';

/// Gestão de membros de uma unidade. Requer cargo `gestor_adm` ou superusuário.
class EquipeService {
  EquipeService(TokenService tokens) : _client = ApiClient(tokens);

  final ApiClient _client;

  Future<List<UsuarioModel>> membros(int setorId) => comApiError(() async {
    final res = await _client.dio.get(
      '/api/usuarios/setores/$setorId/membros/',
    );
    return (res.data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(UsuarioModel.fromJson)
        .toList();
  });

  Future<void> adicionar(int setorId, String siape) => comApiError(() async {
    await _client.dio.post(
      '/api/usuarios/setores/$setorId/adicionar_membro/',
      data: {'siape': siape},
    );
  });

  Future<void> remover(int setorId, int usuarioId) => comApiError(() async {
    await _client.dio.post(
      '/api/usuarios/setores/$setorId/remover_membro/',
      data: {'usuario_id': usuarioId},
    );
  });
}
