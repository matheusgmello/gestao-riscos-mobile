import '../../core/api_error.dart';
import '../models/monitoramento_model.dart';
import '../models/page_response.dart';
import 'api_client.dart';
import 'token_service.dart';

class MonitoramentoService {
  MonitoramentoService(TokenService tokens) : _client = ApiClient(tokens);

  final ApiClient _client;

  Future<List<Monitoramento>> listarPorRisco(String riscoUuid) =>
      comApiError(() async {
        final todos = <Monitoramento>[];
        int page = 1;
        while (true) {
          final res = await _client.dio.get(
            '/api/riscos/monitoramentos/',
            queryParameters: {'risco': riscoUuid, 'page': page},
          );
          final pagina = PageResponse.fromDrf(
            res.data as Map<String, dynamic>,
            Monitoramento.fromJson,
          );
          todos.addAll(pagina.results);
          if (!pagina.hasNext) break;
          page++;
        }
        return todos;
      });

  Future<Monitoramento> criar(Map<String, dynamic> payload) =>
      comApiError(() async {
        final res = await _client.dio.post(
          '/api/riscos/monitoramentos/',
          data: payload,
        );
        return Monitoramento.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Monitoramento> atualizar(int id, Map<String, dynamic> payload) =>
      comApiError(() async {
        final res = await _client.dio.patch(
          '/api/riscos/monitoramentos/$id/',
          data: payload,
        );
        return Monitoramento.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> desativar(int id) => comApiError(() async {
    await _client.dio.delete('/api/riscos/monitoramentos/$id/');
  });
}
