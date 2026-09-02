import '../../core/api_error.dart';
import '../models/historico_model.dart';
import '../models/page_response.dart';
import '../models/risco_model.dart';
import 'api_client.dart';
import 'token_service.dart';

enum OrdenacaoRisco {
  recentes('desc', 'Mais recentes'),
  antigos('asc', 'Mais antigos'),
  nivelMaior('nivel_desc', 'Nível residual (maior)'),
  nivelMenor('nivel_asc', 'Nível residual (menor)'),
  prazoProximo('prazo_asc', 'Prazo mais próximo'),
  prazoDistante('prazo_desc', 'Prazo mais distante');

  const OrdenacaoRisco(this.param, this.rotulo);
  final String param;
  final String rotulo;
}

class FiltroRisco {
  const FiltroRisco({
    this.busca,
    this.setorId,
    this.categoria,
    this.dataInicio,
    this.dataFim,
    this.ordenacao = OrdenacaoRisco.recentes,
    this.incluirInativos = false,
  });

  final String? busca;
  final int? setorId;
  final String? categoria;
  final String? dataInicio;
  final String? dataFim;
  final OrdenacaoRisco ordenacao;
  final bool incluirInativos;

  FiltroRisco copyWith({
    String? busca,
    int? setorId,
    String? categoria,
    String? dataInicio,
    String? dataFim,
    OrdenacaoRisco? ordenacao,
    bool? incluirInativos,
    bool limparSetor = false,
    bool limparCategoria = false,
    bool limparDatas = false,
  }) {
    return FiltroRisco(
      busca: busca ?? this.busca,
      setorId: limparSetor ? null : (setorId ?? this.setorId),
      categoria: limparCategoria ? null : (categoria ?? this.categoria),
      dataInicio: limparDatas ? null : (dataInicio ?? this.dataInicio),
      dataFim: limparDatas ? null : (dataFim ?? this.dataFim),
      ordenacao: ordenacao ?? this.ordenacao,
      incluirInativos: incluirInativos ?? this.incluirInativos,
    );
  }

  bool get temFiltroAtivo =>
      (busca?.isNotEmpty ?? false) ||
      setorId != null ||
      categoria != null ||
      dataInicio != null ||
      dataFim != null;

  Map<String, dynamic> toQuery(int page) {
    final q = <String, dynamic>{'page': page, 'ordenacao': ordenacao.param};
    if (busca != null && busca!.isNotEmpty) q['search'] = busca;
    if (setorId != null) q['setor'] = setorId;
    if (categoria != null) q['categoria'] = categoria;
    if (dataInicio != null) q['data_inicio'] = dataInicio;
    if (dataFim != null) q['data_fim'] = dataFim;
    if (incluirInativos) q['incluir_inativos'] = 'true';
    return q;
  }
}

class RiscoService {
  RiscoService(TokenService tokens) : _client = ApiClient(tokens);

  final ApiClient _client;

  Future<PageResponse<Risco>> listar({
    int page = 1,
    FiltroRisco filtro = const FiltroRisco(),
  }) => comApiError(() async {
    final res = await _client.dio.get(
      '/api/riscos/planos/',
      queryParameters: filtro.toQuery(page),
    );
    return PageResponse.fromDrf(
      res.data as Map<String, dynamic>,
      Risco.fromJson,
    );
  });

  Future<Risco> obter(String uuid) => comApiError(() async {
    final res = await _client.dio.get('/api/riscos/planos/$uuid/');
    return Risco.fromJson(res.data as Map<String, dynamic>);
  });

  Future<Risco> criar(Map<String, dynamic> payload) => comApiError(() async {
    final res = await _client.dio.post('/api/riscos/planos/', data: payload);
    return Risco.fromJson(res.data as Map<String, dynamic>);
  });

  Future<Risco> atualizar(String uuid, Map<String, dynamic> payload) =>
      comApiError(() async {
        final res = await _client.dio.patch(
          '/api/riscos/planos/$uuid/',
          data: payload,
        );
        return Risco.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> desativar(String uuid) => comApiError(() async {
    await _client.dio.delete('/api/riscos/planos/$uuid/');
  });

  Future<Risco> duplicar(String uuid) => comApiError(() async {
    final res = await _client.dio.post('/api/riscos/planos/$uuid/duplicar/');
    return Risco.fromJson(res.data as Map<String, dynamic>);
  });

  Future<List<HistoricoEntrada>> historico(String uuid) => comApiError(
    () async {
      final res = await _client.dio.get('/api/riscos/planos/$uuid/historico/');
      return (res.data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(HistoricoEntrada.fromJson)
          .toList();
    },
  );
}
