import 'package:dio/dio.dart';

import '../../core/api_error.dart';
import '../local/dashboard_local.dart';
import '../models/dashboard_model.dart';
import '../sync/conectividade.dart';
import 'api_client.dart';
import 'token_service.dart';

class FiltroDashboard {
  const FiltroDashboard({
    this.setorId,
    this.dataInicio,
    this.dataFim,
    this.busca,
  });

  final int? setorId;
  final String? dataInicio;
  final String? dataFim;
  final String? busca;

  bool get ativo =>
      setorId != null ||
      dataInicio != null ||
      dataFim != null ||
      (busca?.isNotEmpty ?? false);

  Map<String, dynamic> toQuery() {
    final q = <String, dynamic>{};
    if (setorId != null) q['setor'] = setorId;
    if (dataInicio != null) q['data_inicio'] = dataInicio;
    if (dataFim != null) q['data_fim'] = dataFim;
    if (busca != null && busca!.isNotEmpty) q['search'] = busca;
    return q;
  }

  FiltroDashboard copyWith({
    int? setorId,
    String? dataInicio,
    String? dataFim,
    String? busca,
    bool limparSetor = false,
    bool limparDatas = false,
  }) => FiltroDashboard(
    setorId: limparSetor ? null : (setorId ?? this.setorId),
    dataInicio: limparDatas ? null : (dataInicio ?? this.dataInicio),
    dataFim: limparDatas ? null : (dataFim ?? this.dataFim),
    busca: busca ?? this.busca,
  );
}

class DashboardService {
  DashboardService(TokenService tokens) : _client = ApiClient(tokens);

  final ApiClient _client;

  /// Busca a analítica no servidor. Offline (ou sem rede) reconstrói o mesmo
  /// payload a partir do cache local — ver [dashboardDoCache].
  Future<Dashboard> carregar([
    FiltroDashboard filtro = const FiltroDashboard(),
  ]) async {
    try {
      final res = await _client.dio.get(
        '/api/riscos/planos/dashboard/',
        queryParameters: filtro.toQuery(),
      );
      return Dashboard.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (Conectividade.instance.online) throw ApiError.fromDio(e);
      return dashboardDoCache(filtro);
    }
  }
}
