import '../../core/api_error.dart';
import '../models/page_response.dart';
import '../models/plano_acao_model.dart';
import 'api_client.dart';
import 'token_service.dart';

class PlanoAcaoService {
  PlanoAcaoService(TokenService tokens) : _client = ApiClient(tokens);

  final ApiClient _client;

  /// Todas as ações de um risco (segue a paginação até o fim).
  Future<List<PlanoAcao>> listarPorRisco(String riscoUuid) =>
      comApiError(() async {
        final todos = <PlanoAcao>[];
        int page = 1;
        while (true) {
          final res = await _client.dio.get(
            '/api/riscos/acoes/',
            queryParameters: {'risco': riscoUuid, 'page': page},
          );
          final pagina = PageResponse.fromDrf(
            res.data as Map<String, dynamic>,
            PlanoAcao.fromJson,
          );
          todos.addAll(pagina.results);
          if (!pagina.hasNext) break;
          page++;
        }
        return todos;
      });

  Future<PlanoAcao> criar(Map<String, dynamic> payload) =>
      comApiError(() async {
        final res =
            await _client.dio.post('/api/riscos/acoes/', data: payload);
        return PlanoAcao.fromJson(res.data as Map<String, dynamic>);
      });

  Future<PlanoAcao> atualizar(int id, Map<String, dynamic> payload) =>
      comApiError(() async {
        final res =
            await _client.dio.patch('/api/riscos/acoes/$id/', data: payload);
        return PlanoAcao.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> desativar(int id) => comApiError(() async {
        await _client.dio.delete('/api/riscos/acoes/$id/');
      });
}
