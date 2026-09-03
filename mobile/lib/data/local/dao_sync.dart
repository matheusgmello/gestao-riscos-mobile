import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'banco.dart';

enum Recurso { risco, acao, monitoramento }

extension RecursoTabela on Recurso {
  String get tabela => switch (this) {
    Recurso.risco => 'cache_riscos',
    Recurso.acao => 'cache_acoes',
    Recurso.monitoramento => 'cache_monitoramentos',
  };
  String get pk => this == Recurso.risco ? 'uuid' : 'id';
  String get chaveApi => name; // 'risco' | 'acao' | 'monitoramento'
}

class ItemFila {
  ItemFila({
    required this.seq,
    required this.recurso,
    required this.operacao,
    required this.chave,
    required this.payload,
    required this.baseAtualizadoEm,
    required this.tentativas,
  });

  final int seq;
  final Recurso recurso;
  final String operacao; // 'criar' | 'atualizar' | 'excluir'
  final String chave;
  final Map<String, dynamic>? payload;
  final String? baseAtualizadoEm;
  final int tentativas;

  factory ItemFila.fromRow(Map<String, Object?> r) => ItemFila(
    seq: r['seq'] as int,
    recurso: Recurso.values.byName(r['recurso'] as String),
    operacao: r['operacao'] as String,
    chave: r['chave'] as String,
    payload: r['payload'] == null
        ? null
        : jsonDecode(r['payload'] as String) as Map<String, dynamic>,
    baseAtualizadoEm: r['base_atualizado_em'] as String?,
    tentativas: r['tentativas'] as int,
  );
}

class DaoSync {
  DaoSync._();
  static final DaoSync instance = DaoSync._();

  Future<Database> get _db => Banco.instance.db;

  // --- Leitura do cache ---

  Future<List<Map<String, dynamic>>> riscos() => _lista(Recurso.risco);
  Future<List<Map<String, dynamic>>> acoes() => _lista(Recurso.acao);
  Future<List<Map<String, dynamic>>> monitoramentos() =>
      _lista(Recurso.monitoramento);
  Future<List<Map<String, dynamic>>> acoesDoRisco(String uuid) =>
      _lista(Recurso.acao, uuid);
  Future<List<Map<String, dynamic>>> monitoramentosDoRisco(String uuid) =>
      _lista(Recurso.monitoramento, uuid);

  Future<Map<String, dynamic>?> risco(String uuid) async {
    final d = await _db;
    final rows = await d.query(
      'cache_riscos',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (rows.isEmpty) return null;
    return _comMeta(rows.first);
  }

  Future<List<Map<String, dynamic>>> _lista(
    Recurso r, [
    String? riscoUuid,
  ]) async {
    final d = await _db;
    final rows = await d.query(
      r.tabela,
      where: riscoUuid == null ? null : 'risco_uuid = ?',
      whereArgs: riscoUuid == null ? null : [riscoUuid],
    );
    return rows.map(_comMeta).toList();
  }

  Map<String, dynamic> _comMeta(Map<String, Object?> row) {
    final json = jsonDecode(row['json'] as String) as Map<String, dynamic>;
    // Autocura: o remapeamento pós-sync troca a chave da linha mas pode não
    // ter reescrito o id dentro do JSON.
    if (row['uuid'] != null) json['uuid'] ??= row['uuid'];
    if (row['id'] != null) json['id'] ??= row['id'];
    json['pendente_sync'] = (row['pendente'] as int? ?? 0) == 1;
    json['ativo'] = (row['ativo'] as int? ?? 1) == 1;
    return json;
  }

  Future<String?> cursor(Recurso r) async {
    final d = await _db;
    final res = await d.rawQuery(
      'SELECT MAX(atualizado_em) AS c FROM ${r.tabela} WHERE pendente = 0',
    );
    return res.first['c'] as String?;
  }

  Future<int> contarPendentes() async {
    final d = await _db;
    final res = await d.rawQuery('SELECT COUNT(*) AS n FROM fila_sync');
    return (res.first['n'] as int?) ?? 0;
  }

  // --- Escrita vinda do servidor (pull) ---

  Future<void> aplicarDoServidor(Recurso r, Map<String, dynamic> json) async {
    final d = await _db;
    final pk = json[r.pk];
    // Não sobrescreve um registro com alteração local pendente.
    final pendentes = await d.query(
      r.tabela,
      where: '${r.pk} = ? AND pendente = 1',
      whereArgs: [pk],
    );
    if (pendentes.isNotEmpty) return;
    await d.insert(r.tabela, {
      r.pk: pk,
      'risco_uuid': r == Recurso.risco ? json['uuid'] : json['risco'],
      'json': jsonEncode(json),
      'atualizado_em': json['atualizado_em'],
      'ativo': (json['ativo'] as bool? ?? true) ? 1 : 0,
      'pendente': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Escrita local otimista + fila ---

  Future<void> salvarLocal(
    Recurso r,
    Object chave,
    Map<String, dynamic> json, {
    bool ativo = true,
  }) async {
    final d = await _db;
    await d.insert(r.tabela, {
      r.pk: chave,
      'risco_uuid': r == Recurso.risco ? chave : json['risco'],
      'json': jsonEncode(json),
      'atualizado_em': json['atualizado_em'],
      'ativo': ativo ? 1 : 0,
      'pendente': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> marcarInativoLocal(Recurso r, Object chave) async {
    final d = await _db;
    await d.update(
      r.tabela,
      {'ativo': 0, 'pendente': 1},
      where: '${r.pk} = ?',
      whereArgs: [chave],
    );
  }

  Future<void> removerLocal(Recurso r, Object chave) async {
    final d = await _db;
    await d.delete(r.tabela, where: '${r.pk} = ?', whereArgs: [chave]);
  }

  /// Enfileira uma mutação, colapsando com o que já estiver pendente para a
  /// mesma chave (evita fila inconsistente após várias edições offline).
  Future<void> enfileirar(
    Recurso r,
    String operacao,
    String chave, {
    Map<String, dynamic>? payload,
    String? baseAtualizadoEm,
  }) async {
    final d = await _db;
    final existentes = await d.query(
      'fila_sync',
      where: 'recurso = ? AND chave = ?',
      whereArgs: [r.name, chave],
      orderBy: 'seq',
    );

    if (operacao == 'excluir') {
      final temCriar = existentes.any((e) => e['operacao'] == 'criar');
      await d.delete(
        'fila_sync',
        where: 'recurso = ? AND chave = ?',
        whereArgs: [r.name, chave],
      );
      if (!temCriar) {
        await _inserirFila(d, r, 'excluir', chave, null, baseAtualizadoEm);
      }
      return;
    }

    if (operacao == 'atualizar') {
      final criar = existentes.where((e) => e['operacao'] == 'criar').toList();
      if (criar.isNotEmpty) {
        await d.update(
          'fila_sync',
          {'payload': jsonEncode(payload)},
          where: 'seq = ?',
          whereArgs: [criar.first['seq']],
        );
        return;
      }
      final atualizar = existentes
          .where((e) => e['operacao'] == 'atualizar')
          .toList();
      if (atualizar.isNotEmpty) {
        await d.update(
          'fila_sync',
          {'payload': jsonEncode(payload)},
          where: 'seq = ?',
          whereArgs: [atualizar.first['seq']],
        );
        return;
      }
    }

    await _inserirFila(d, r, operacao, chave, payload, baseAtualizadoEm);
  }

  Future<void> _inserirFila(
    Database d,
    Recurso r,
    String operacao,
    String chave,
    Map<String, dynamic>? payload,
    String? base,
  ) => d.insert('fila_sync', {
    'recurso': r.name,
    'operacao': operacao,
    'chave': chave,
    'payload': payload == null ? null : jsonEncode(payload),
    'base_atualizado_em': base,
  });

  Future<List<ItemFila>> fila() async {
    final d = await _db;
    final rows = await d.query('fila_sync', orderBy: 'seq');
    return rows.map(ItemFila.fromRow).toList();
  }

  Future<void> removerItemFila(int seq) async {
    final d = await _db;
    await d.delete('fila_sync', where: 'seq = ?', whereArgs: [seq]);
  }

  Future<void> incrementarTentativa(int seq) async {
    final d = await _db;
    await d.rawUpdate(
      'UPDATE fila_sync SET tentativas = tentativas + 1 WHERE seq = ?',
      [seq],
    );
  }

  /// Depois que um `criar` de risco sincroniza, troca a chave temporária pelo
  /// UUID real em todas as tabelas e itens de fila.
  Future<void> remapearRisco(String local, String real) async {
    final d = await _db;
    await d.transaction((t) async {
      final atual = await t.query(
        'cache_riscos',
        where: 'uuid = ?',
        whereArgs: [local],
      );
      final json = atual.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(atual.first['json'] as String) as Map<String, dynamic>;
      json['uuid'] = real;
      // já sincronizado — deixa o aplicarDoServidor seguinte sobrescrever.
      await t.update(
        'cache_riscos',
        {'uuid': real, 'risco_uuid': real, 'json': jsonEncode(json), 'pendente': 0},
        where: 'uuid = ?',
        whereArgs: [local],
      );
      for (final tab in ['cache_acoes', 'cache_monitoramentos']) {
        final linhas = await t.query(
          tab,
          where: 'risco_uuid = ?',
          whereArgs: [local],
        );
        for (final l in linhas) {
          final json = jsonDecode(l['json'] as String) as Map<String, dynamic>;
          json['risco'] = real;
          await t.update(
            tab,
            {'risco_uuid': real, 'json': jsonEncode(json)},
            where: '${l.containsKey('id') ? 'id' : 'rowid'} = ?',
            whereArgs: [l['id']],
          );
        }
      }
      final itens = await t.query('fila_sync');
      for (final i in itens) {
        var mudou = false;
        final novo = <String, Object?>{};
        if (i['recurso'] == 'risco' && i['chave'] == local) {
          novo['chave'] = real;
          mudou = true;
        }
        if (i['payload'] != null) {
          final pl = jsonDecode(i['payload'] as String) as Map<String, dynamic>;
          if (pl['risco'] == local) {
            pl['risco'] = real;
            novo['payload'] = jsonEncode(pl);
            mudou = true;
          }
        }
        if (mudou) {
          await t.update(
            'fila_sync',
            novo,
            where: 'seq = ?',
            whereArgs: [i['seq']],
          );
        }
      }
    });
  }
}
