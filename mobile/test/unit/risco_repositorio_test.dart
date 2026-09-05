import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/local/banco.dart';
import 'package:gestao_risco_mobile/data/local/dao_sync.dart';
import 'package:gestao_risco_mobile/data/repositorios/risco_repositorio.dart';
import 'package:gestao_risco_mobile/data/services/token_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, dynamic> _risco(String uuid) => {
      'uuid': uuid,
      'setor': 1,
      'objetivo': 1,
      'macroprocesso': 1,
      'categoria': 'Operacional',
      'evento': 'E $uuid',
      'probabilidade': 2,
      'impacto': 2,
      'nivel_risco': 4,
      'prob_residual': 1,
      'imp_residual': 1,
      'nivel_residual': 1,
      'ativo': true,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dao = DaoSync.instance;

  setUpAll(() {
    sqfliteFfiInit();
    dotenv.loadFromString(envString: 'API_BASE_URL=http://10.0.2.2:8000');
  });
  setUp(() async {
    Banco.testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (d, _) => Banco.criarSchema(d),
      ),
    );
  });
  tearDown(() async {
    await Banco.testDb?.close();
    Banco.testDb = null;
  });

  // Regressão do loop de sincronização (commit 581ccc3):
  // listar() é leitura pura do cache — não dispara rede nem sync.
  test('listar() devolve o cache sem tocar na rede', () async {
    await dao.aplicarDoServidor(Recurso.risco, _risco('r1'));
    await dao.aplicarDoServidor(Recurso.risco, _risco('r2'));

    final repo = RiscoRepositorio(TokenService());
    final lista = await repo.listar();

    expect(lista.map((r) => r.uuid), containsAll(['r1', 'r2']));
  });

  test('listar() chamado várias vezes é idempotente e rápido', () async {
    await dao.aplicarDoServidor(Recurso.risco, _risco('r1'));
    final repo = RiscoRepositorio(TokenService());

    for (var i = 0; i < 5; i++) {
      expect((await repo.listar()).single.uuid, 'r1');
    }
  });

  // Regressão c588034: detalhe aberto com chave temporária resolve pelo
  // redirecionamento gravado no remap.
  test('obter() resolve a chave temporária após o remap', () async {
    await dao.salvarLocal(Recurso.risco, 'local-9', {
      ..._risco('local-9'),
    });
    await dao.remapearRisco('local-9', 'REAL-9');
    await dao.aplicarDoServidor(Recurso.risco, _risco('REAL-9'));

    final repo = RiscoRepositorio(TokenService());
    final r = await repo.obter('local-9');
    expect(r, isNotNull);
    expect(r!.uuid, 'REAL-9');
  });
}
