import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/local/banco.dart';
import 'package:gestao_risco_mobile/data/local/dao_sync.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final dao = DaoSync.instance;

  setUpAll(() => sqfliteFfiInit());

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (d, _) => Banco.criarSchema(d),
      ),
    );
    Banco.testDb = db;
  });

  tearDown(() async {
    await Banco.testDb?.close();
    Banco.testDb = null;
  });

  test('aplicarDoServidor faz upsert e expõe meta', () async {
    await dao.aplicarDoServidor(Recurso.risco, {
      'uuid': 'r1',
      'evento': 'E',
      'atualizado_em': '2026-01-01T00:00:00Z',
      'ativo': true,
    });
    final rows = await dao.riscos();
    expect(rows, hasLength(1));
    expect(rows.first['pendente_sync'], isFalse);
    expect(rows.first['ativo'], isTrue);
    expect(await dao.cursor(Recurso.risco), '2026-01-01T00:00:00Z');
  });

  test('aplicarDoServidor não sobrescreve registro pendente', () async {
    await dao.salvarLocal(Recurso.risco, 'r1', {
      'uuid': 'r1',
      'evento': 'local',
    });
    await dao.aplicarDoServidor(Recurso.risco, {
      'uuid': 'r1',
      'evento': 'servidor',
    });
    final r = await dao.risco('r1');
    expect(r!['evento'], 'local');
  });

  test('fila colapsa criar + atualizar num único criar', () async {
    await dao.salvarLocal(Recurso.acao, -1, {'id': -1, 'descricao_acao': 'a'});
    await dao.enfileirar(
      Recurso.acao,
      'criar',
      '-1',
      payload: {'descricao_acao': 'a'},
    );
    await dao.enfileirar(
      Recurso.acao,
      'atualizar',
      '-1',
      payload: {'descricao_acao': 'b'},
    );
    final fila = await dao.fila();
    expect(fila, hasLength(1));
    expect(fila.first.operacao, 'criar');
    expect(fila.first.payload!['descricao_acao'], 'b');
  });

  test('excluir um item recém-criado offline zera a fila', () async {
    await dao.enfileirar(
      Recurso.acao,
      'criar',
      '-1',
      payload: {'descricao_acao': 'a'},
    );
    await dao.enfileirar(Recurso.acao, 'excluir', '-1');
    expect(await dao.fila(), isEmpty);
  });

  test('contarPendentes reflete a fila', () async {
    await dao.enfileirar(Recurso.risco, 'atualizar', 'r1', payload: {'x': 1});
    await dao.enfileirar(Recurso.risco, 'atualizar', 'r2', payload: {'x': 2});
    expect(await dao.contarPendentes(), 2);
  });

  test('remapearRisco troca chave local pelo uuid real', () async {
    await dao.salvarLocal(Recurso.risco, 'local-1', {
      'uuid': 'local-1',
      'evento': 'E',
    });
    await dao.salvarLocal(Recurso.acao, -9, {
      'id': -9,
      'risco': 'local-1',
      'descricao_acao': 'a',
    });
    await dao.enfileirar(
      Recurso.acao,
      'criar',
      '-9',
      payload: {'risco': 'local-1', 'descricao_acao': 'a'},
    );

    await dao.remapearRisco('local-1', 'REAL');

    expect(await dao.risco('local-1'), isNull);
    final remapeado = await dao.risco('REAL');
    expect(remapeado, isNotNull);
    // o uuid dentro do JSON e o flag pendente também acompanham o remap
    expect(remapeado!['uuid'], 'REAL');
    expect(remapeado['pendente_sync'], isFalse);
    final acoes = await dao.acoesDoRisco('REAL');
    expect(acoes, hasLength(1));
    final fila = await dao.fila();
    expect(fila.first.payload!['risco'], 'REAL');
    // redirecionamento p/ telas abertas com a chave temporária
    expect(await dao.uuidRemapeado('local-1'), 'REAL');
  });

  test('_comMeta injeta o uuid da linha quando falta no JSON', () async {
    // simula linha remapeada por versão antiga (JSON sem uuid)
    final db = Banco.testDb!;
    await db.insert('cache_riscos', {
      'uuid': 'REAL',
      'risco_uuid': 'REAL',
      'json': '{"evento":"E"}',
      'ativo': 1,
      'pendente': 0,
    });
    final r = await dao.risco('REAL');
    expect(r!['uuid'], 'REAL');
  });
}
