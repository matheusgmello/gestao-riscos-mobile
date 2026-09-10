import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/local/banco.dart';
import 'package:gestao_risco_mobile/data/local/dao_sync.dart';
import 'package:gestao_risco_mobile/data/sync/conectividade.dart';
import 'package:gestao_risco_mobile/data/sync/motor_sync.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Push do MotorSync: como cada código de status trata a fila.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dao = DaoSync.instance;

  late Dio dio;
  late DioAdapter adapter;

  setUpAll(() => sqfliteFfiInit());

  setUp(() async {
    Banco.testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (d, _) => Banco.criarSchema(d),
      ),
    );
    Conectividade.definirParaTeste(online: true);
    dio = Dio(BaseOptions(baseUrl: 'http://x'));
    adapter = DioAdapter(dio: dio);
    MotorSync.definirParaTeste(dio);
    // pull (_baixar) — sempre vazio nestes testes
    for (final r in ['planos', 'acoes', 'monitoramentos']) {
      adapter.onGet(
        '/api/riscos/$r/',
        (s) => s.reply(200, {'results': [], 'next': null}),
      );
    }
  });

  tearDown(() async {
    await Banco.testDb?.close();
    Banco.testDb = null;
  });

  Future<void> acaoPendente({String chave = '-1'}) async {
    await dao.salvarLocal(Recurso.acao, int.parse(chave), {
      'id': int.parse(chave),
      'risco': 'r1',
      'descricao_acao': 'a',
    });
    await dao.enfileirar(
      Recurso.acao,
      'atualizar',
      chave,
      payload: {'descricao_acao': 'b'},
    );
  }

  test('409 no PATCH: conta conflito, servidor vence, fila esvazia', () async {
    await acaoPendente(chave: '5');
    adapter.onPatch(
      '/api/riscos/acoes/5/',
      (s) => s.reply(409, {
        'erro': 'conflito',
        'atual': {'id': 5, 'risco': 'r1', 'descricao_acao': 'do servidor'},
      }),
      data: Matchers.any,
    );

    ResumoSync? resumo;
    MotorSync.instance.resumo.listen((r) => resumo = r);
    await MotorSync.instance.sincronizar();

    expect(await dao.fila(), isEmpty);
    expect(resumo?.conflitos, 1);
    final acao = await dao.risco('r1'); // não existe risco, mas a ação sim
    expect(acao, isNull);
    final acoes = await dao.acoesDoRisco('r1');
    expect(acoes.single['descricao_acao'], 'do servidor');
  });

  test('404 no PATCH: descarta o item da fila sem erro', () async {
    await acaoPendente(chave: '7');
    adapter.onPatch(
      '/api/riscos/acoes/7/',
      (s) => s.reply(404, {'erro': 'sumiu'}),
      data: Matchers.any,
    );

    await MotorSync.instance.sincronizar();
    expect(await dao.fila(), isEmpty);
  });

  test('400 no PATCH: erro de validação — remove o item e segue', () async {
    await acaoPendente(chave: '8');
    adapter.onPatch(
      '/api/riscos/acoes/8/',
      (s) => s.reply(400, {'descricao_acao': ['inválida']}),
      data: Matchers.any,
    );

    await MotorSync.instance.sincronizar();
    expect(await dao.fila(), isEmpty);
  });

  test('500 no PATCH: para o push, item continua na fila', () async {
    await acaoPendente(chave: '9');
    adapter.onPatch(
      '/api/riscos/acoes/9/',
      (s) => s.reply(500, {'erro': 'server'}),
      data: Matchers.any,
    );

    await MotorSync.instance.sincronizar();
    expect(await dao.fila(), hasLength(1)); // não descartou
  });

  test('monitoramento com foto local: envia multipart e apaga o arquivo', () async {
    final arquivo = File(
      '${Directory.systemTemp.path}/evid_${DateTime.now().microsecondsSinceEpoch}.png',
    )..writeAsBytesSync([137, 80, 78, 71]);

    await dao.salvarLocal(Recurso.monitoramento, -3, {
      'id': -3,
      'risco': 'r1',
      'resultados': 'R',
      'foto_local_path': arquivo.path,
    });
    await dao.enfileirar(
      Recurso.monitoramento,
      'criar',
      '-3',
      payload: {'risco': 'r1', 'resultados': 'R'},
    );

    Object? corpoRecebido;
    dio.interceptors.insert(
      0,
      InterceptorsWrapper(onRequest: (o, h) {
        if (o.path.endsWith('/monitoramentos/') && o.method == 'POST') {
          corpoRecebido = o.data;
        }
        h.next(o);
      }),
    );
    adapter.onPost(
      '/api/riscos/monitoramentos/',
      (s) => s.reply(201, {'id': 50, 'risco': 'r1', 'resultados': 'R',
          'foto': 'http://x/media/monitoramentos/evid.png'}),
      data: Matchers.any,
    );

    await MotorSync.instance.sincronizar();

    // enviou como multipart, esvaziou a fila e apagou o arquivo local
    expect(corpoRecebido, isA<FormData>());
    expect(await dao.fila(), isEmpty);
    expect(arquivo.existsSync(), isFalse);
    final mons = await dao.monitoramentosDoRisco('r1');
    expect(mons.single['foto'], contains('media/monitoramentos'));
  });
}
