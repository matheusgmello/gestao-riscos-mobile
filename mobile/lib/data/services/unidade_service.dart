import '../../core/api_error.dart';
import '../local/cache_lista.dart';
import '../models/page_response.dart';
import '../models/unidade_model.dart';
import 'api_client.dart';
import 'token_service.dart';

class ListaAdminUnidades {
  const ListaAdminUnidades({
    required this.pagina,
    required this.centros,
    required this.tipos,
  });

  final PageResponse<UnidadeModel> pagina;
  final List<String> centros;
  final List<String> tipos;
}

class UnidadeService {
  UnidadeService(TokenService tokens) : _client = ApiClient(tokens);

  final ApiClient _client;

  /// `GET /api/usuarios/setores/` — público, sem paginação. Cache-through
  /// para o select de unidade funcionar offline.
  Future<List<UnidadeModel>> listar() => listaComCache(
    chave: 'unidades',
    fromJson: UnidadeModel.fromJson,
    buscar: () => comApiError(() async {
      final res = await _client.dio.get('/api/usuarios/setores/');
      return (res.data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    }),
  );

  /// `GET /api/usuarios/setores/admin/` — superusuário; busca + filtros.
  Future<ListaAdminUnidades> listarAdmin({
    int page = 1,
    String? busca,
    String? centro,
    String? tipo,
  }) => comApiError(() async {
    final res = await _client.dio.get(
      '/api/usuarios/setores/admin/',
      queryParameters: {
        'page': page,
        if (busca != null && busca.isNotEmpty) 'search': busca,
        if (centro != null && centro.isNotEmpty) 'centro': centro,
        if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
      },
    );
    final data = res.data as Map<String, dynamic>;
    return ListaAdminUnidades(
      pagina: PageResponse.fromDrfAdmin(data, UnidadeModel.fromJson),
      centros: (data['centros'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      tipos: (data['tipos'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  });

  Future<void> criar(Map<String, dynamic> payload) => comApiError(() async {
    await _client.dio.post('/api/usuarios/setores/', data: payload);
  });

  Future<void> editar(int id, Map<String, dynamic> payload) =>
      comApiError(() async {
        await _client.dio.patch('/api/usuarios/setores/$id/', data: payload);
      });

  /// `POST /api/usuarios/setores/{id}/desativar/` — alterna ativo/inativo.
  Future<void> alternarAtivo(int id) => comApiError(() async {
    await _client.dio.post('/api/usuarios/setores/$id/desativar/');
  });
}
