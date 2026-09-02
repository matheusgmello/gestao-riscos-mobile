import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../local/dao_sync.dart';
import '../services/api_client.dart';
import '../services/token_service.dart';
import 'conectividade.dart';

enum EstadoSync { ocioso, sincronizando, erro }

class ResumoSync {
  const ResumoSync({this.pendentes = 0, this.conflitos = 0, this.ultimoErro});
  final int pendentes;
  final int conflitos;
  final String? ultimoErro;
}

/// Empurra a fila de mutações e puxa as novidades do servidor.
/// Roda em primeiro plano: ao abrir o app, quando a conexão volta e no
/// pull-to-refresh. Sem isolate / WorkManager.
class MotorSync {
  MotorSync._() {
    Conectividade.instance.aoVoltar.listen((_) => sincronizar());
  }
  static final MotorSync instance = MotorSync._();

  final _dao = DaoSync.instance;
  final Dio _dio = ApiClient(TokenService()).dio;

  final _estado = StreamController<EstadoSync>.broadcast();
  final _resumo = StreamController<ResumoSync>.broadcast();
  Stream<EstadoSync> get estado => _estado.stream;
  Stream<ResumoSync> get resumo => _resumo.stream;

  bool _rodando = false;
  int _conflitosSessao = 0;

  static const _paths = {
    Recurso.risco: '/api/riscos/planos/',
    Recurso.acao: '/api/riscos/acoes/',
    Recurso.monitoramento: '/api/riscos/monitoramentos/',
  };

  Future<void> _emitirResumo({String? erro}) async {
    _resumo.add(
      ResumoSync(
        pendentes: await _dao.contarPendentes(),
        conflitos: _conflitosSessao,
        ultimoErro: erro,
      ),
    );
  }

  Future<void> sincronizar() async {
    if (_rodando || !Conectividade.instance.online) return;
    _rodando = true;
    _estado.add(EstadoSync.sincronizando);
    try {
      await _enviar();
      await _baixar();
      _estado.add(EstadoSync.ocioso);
      await _emitirResumo();
    } catch (e, st) {
      debugPrint('MotorSync erro: $e\n$st');
      _estado.add(EstadoSync.erro);
      await _emitirResumo(erro: '$e');
    } finally {
      _rodando = false;
    }
  }

  // --- Pull ---

  Future<void> _baixar() async {
    for (final r in Recurso.values) {
      final cursor = await _dao.cursor(r);
      var url = _paths[r]!;
      final params = <String, dynamic>{'modificado_apos': ?cursor};
      while (true) {
        final res = await _dio.get(url, queryParameters: params);
        final data = res.data as Map<String, dynamic>;
        for (final item in (data['results'] as List<dynamic>)) {
          await _dao.aplicarDoServidor(r, item as Map<String, dynamic>);
        }
        final next = data['next'] as String?;
        if (next == null) break;
        url = next;
        params.clear();
      }
    }
  }

  // --- Push ---

  Future<void> _enviar() async {
    for (final item in await _dao.fila()) {
      final path = _paths[item.recurso]!;
      try {
        switch (item.operacao) {
          case 'criar':
            final res = await _dio.post(path, data: item.payload);
            final corpo = res.data as Map<String, dynamic>;
            if (item.recurso == Recurso.risco) {
              await _dao.remapearRisco(item.chave, corpo['uuid'] as String);
              await _dao.aplicarDoServidor(Recurso.risco, corpo);
            } else {
              await _dao.removerLocal(item.recurso, int.parse(item.chave));
              await _dao.aplicarDoServidor(item.recurso, corpo);
            }
          case 'atualizar':
            final body = {
              ...?item.payload,
              if (item.baseAtualizadoEm != null)
                'atualizado_em': item.baseAtualizadoEm,
            };
            try {
              final res = await _dio.patch('$path${item.chave}/', data: body);
              await _forcarDoServidor(
                item.recurso,
                res.data as Map<String, dynamic>,
              );
            } on DioException catch (e) {
              if (e.response?.statusCode == 409) {
                _conflitosSessao++;
                final atual =
                    (e.response!.data as Map<String, dynamic>)['atual']
                        as Map<String, dynamic>?;
                if (atual != null) {
                  await _forcarDoServidor(item.recurso, atual);
                }
              } else {
                rethrow;
              }
            }
          case 'excluir':
            await _dio.delete('$path${item.chave}/');
            await _dao.removerLocal(
              item.recurso,
              item.recurso == Recurso.risco
                  ? item.chave
                  : int.parse(item.chave),
            );
        }
        await _dao.removerItemFila(item.seq);
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 404) {
          // já não existe no servidor — descarta a operação
          await _dao.removerItemFila(item.seq);
          continue;
        }
        if (code != null && code < 500) {
          // erro de validação: não adianta repetir, remove e segue
          await _dao.incrementarTentativa(item.seq);
          await _dao.removerItemFila(item.seq);
          continue;
        }
        rethrow; // rede / 5xx: para o push, tenta de novo depois
      }
    }
  }

  /// Sobrescreve o cache com a versão do servidor, limpando o flag pendente.
  Future<void> _forcarDoServidor(Recurso r, Map<String, dynamic> json) async {
    await _dao.removerLocal(r, r == Recurso.risco ? json['uuid'] : json['id']);
    await _dao.aplicarDoServidor(r, json);
  }
}
