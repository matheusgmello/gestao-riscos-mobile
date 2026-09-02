import 'dart:async';

import '../local/dao_sync.dart';
import '../models/historico_model.dart';
import '../models/monitoramento_model.dart';
import '../models/plano_acao_model.dart';
import '../models/risco_model.dart';
import '../services/risco_service.dart';
import '../services/token_service.dart';
import '../sync/conectividade.dart';
import '../sync/motor_sync.dart';

/// Fonte única do domínio de riscos para as telas. Lê sempre do cache local
/// (sqflite) e dispara a sincronização em segundo plano. Escritas são
/// otimistas: aplicadas no cache na hora e enfileiradas para envio.
class RiscoRepositorio {
  RiscoRepositorio(TokenService tokens) : _riscos = RiscoService(tokens);

  final RiscoService _riscos;
  final _dao = DaoSync.instance;

  void _sincronizarEmFundo() {
    unawaited(MotorSync.instance.sincronizar());
  }

  // --- Leitura ---

  Future<List<Risco>> listar() async {
    var linhas = await _dao.riscos();
    if (linhas.isEmpty && Conectividade.instance.online) {
      // primeira carga: espera o pull terminar antes de mostrar a lista.
      await MotorSync.instance.sincronizar();
      linhas = await _dao.riscos();
    } else {
      _sincronizarEmFundo();
    }
    return linhas.map(Risco.fromJson).toList();
  }

  Future<Risco?> obter(String uuid) async {
    final local = await _dao.risco(uuid);
    if (local != null) return Risco.fromJson(local);
    if (Conectividade.instance.online) {
      try {
        final r = await _riscos.obter(uuid);
        return r;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<List<PlanoAcao>> acoes(String riscoUuid) async {
    final linhas = await _dao.acoesDoRisco(riscoUuid);
    return linhas.map(PlanoAcao.fromJson).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<List<Monitoramento>> monitoramentos(String riscoUuid) async {
    final linhas = await _dao.monitoramentosDoRisco(riscoUuid);
    return linhas.map(Monitoramento.fromJson).toList();
  }

  /// Histórico é sempre online (log append-only, não crítico offline).
  Future<List<HistoricoEntrada>> historico(String uuid) async {
    if (!Conectividade.instance.online) return const [];
    try {
      return await _riscos.historico(uuid);
    } catch (_) {
      return const [];
    }
  }

  /// Duplicar exige o servidor (cria uma cópia com os planos de ação).
  Future<Risco> duplicar(String uuid) async {
    final r = await _riscos.duplicar(uuid);
    _sincronizarEmFundo();
    return r;
  }

  // --- Escrita otimista ---

  int _tempId() => -DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> _comNiveis(Map<String, dynamic> p) => {
    ...p,
    'nivel_risco':
        ((p['probabilidade'] as num?) ?? 0) * ((p['impacto'] as num?) ?? 0),
    'nivel_residual':
        ((p['prob_residual'] as num?) ?? 0) *
        ((p['imp_residual'] as num?) ?? 0),
  };

  Future<void> criarRisco(Map<String, dynamic> payload) async {
    final chave = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final json = _comNiveis(payload)
      ..['uuid'] = chave
      ..['ativo'] = true;
    await _dao.salvarLocal(Recurso.risco, chave, json);
    await _dao.enfileirar(Recurso.risco, 'criar', chave, payload: payload);
    _sincronizarEmFundo();
  }

  Future<void> atualizarRisco(String uuid, Map<String, dynamic> payload) async {
    final atual = await _dao.risco(uuid);
    final base = atual?['atualizado_em'] as String?;
    final json = _comNiveis(payload)
      ..['uuid'] = uuid
      ..['ativo'] = true
      ..['atualizado_em'] = base;
    await _dao.salvarLocal(Recurso.risco, uuid, json);
    await _dao.enfileirar(
      Recurso.risco,
      'atualizar',
      uuid,
      payload: payload,
      baseAtualizadoEm: base,
    );
    _sincronizarEmFundo();
  }

  Future<void> desativarRisco(String uuid) async {
    await _dao.marcarInativoLocal(Recurso.risco, uuid);
    await _dao.enfileirar(Recurso.risco, 'excluir', uuid);
    _sincronizarEmFundo();
  }

  Future<void> criarAcao(Map<String, dynamic> payload) =>
      _criarFilho(Recurso.acao, payload);
  Future<void> atualizarAcao(int id, Map<String, dynamic> payload) =>
      _atualizarFilho(Recurso.acao, id, payload);
  Future<void> desativarAcao(int id) => _desativarFilho(Recurso.acao, id);

  Future<void> criarMonitoramento(Map<String, dynamic> payload) =>
      _criarFilho(Recurso.monitoramento, payload);
  Future<void> atualizarMonitoramento(int id, Map<String, dynamic> payload) =>
      _atualizarFilho(Recurso.monitoramento, id, payload);
  Future<void> desativarMonitoramento(int id) =>
      _desativarFilho(Recurso.monitoramento, id);

  Future<void> _criarFilho(Recurso r, Map<String, dynamic> payload) async {
    final id = _tempId();
    final json = {...payload, 'id': id, 'ativo': true};
    await _dao.salvarLocal(r, id, json);
    await _dao.enfileirar(r, 'criar', '$id', payload: payload);
    _sincronizarEmFundo();
  }

  Future<void> _atualizarFilho(
    Recurso r,
    int id,
    Map<String, dynamic> payload,
  ) async {
    final json = {...payload, 'id': id, 'ativo': true};
    await _dao.salvarLocal(r, id, json);
    await _dao.enfileirar(r, 'atualizar', '$id', payload: payload);
    _sincronizarEmFundo();
  }

  Future<void> _desativarFilho(Recurso r, int id) async {
    await _dao.marcarInativoLocal(r, id);
    await _dao.enfileirar(r, 'excluir', '$id');
    _sincronizarEmFundo();
  }
}
