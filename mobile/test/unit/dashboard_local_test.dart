import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/local/banco.dart';
import 'package:gestao_risco_mobile/data/local/dao_sync.dart';
import 'package:gestao_risco_mobile/data/local/dashboard_local.dart';
import 'package:gestao_risco_mobile/data/services/dashboard_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, dynamic> _risco(
  String uuid, {
  required String categoria,
  required int setor,
  required int probRes,
  required int impRes,
  int probIne = 5,
  int impIne = 5,
}) => {
  'uuid': uuid,
  'setor': setor,
  'objetivo': 1,
  'macroprocesso': 1,
  'categoria': categoria,
  'evento': 'Evento $uuid',
  'probabilidade': probIne,
  'impacto': impIne,
  'nivel_risco': probIne * impIne,
  'prob_residual': probRes,
  'imp_residual': impRes,
  'nivel_residual': probRes * impRes,
  'ativo': true,
};

void main() {
  final dao = DaoSync.instance;

  setUpAll(() => sqfliteFfiInit());

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

  test('agrega nível, categoria, matriz e prioritários do cache', () async {
    await dao.aplicarDoServidor(
      Recurso.risco,
      _risco('r1', categoria: 'Operacional', setor: 1, probRes: 5, impRes: 5),
    ); // residual 25 -> extremo
    await dao.aplicarDoServidor(
      Recurso.risco,
      _risco('r2', categoria: 'Operacional', setor: 1, probRes: 3, impRes: 4),
    ); // residual 12 -> alto
    await dao.aplicarDoServidor(
      Recurso.risco,
      _risco('r3', categoria: 'Imagem', setor: 2, probRes: 1, impRes: 2),
    ); // residual 2 -> baixo
    await dao.aplicarDoServidor(Recurso.acao, {
      'id': 10,
      'risco': 'r1',
      'responsavel': 'Ana',
      'tipo_resposta': 'Mitigar',
      'status': 'Em andamento',
      'data_inicio': '2026-01-01',
      'ativo': true,
    });
    await dao.aplicarDoServidor(Recurso.monitoramento, {
      'id': 20,
      'risco': 'r1',
      'ativo': true,
    });

    final d = await dashboardDoCache(const FiltroDashboard());

    expect(d.totalPlanos, 3);
    expect(d.riscosPorNivel.extremo, 1);
    expect(d.riscosPorNivel.alto, 1);
    expect(d.riscosPorNivel.baixo, 1);
    expect(d.riscosCriticos, 2);

    final op = d.distribuicaoCategorias.firstWhere((c) => c.nome == 'Operacional');
    expect(op.quantidade, 2);

    expect(d.matrizResidual, hasLength(25));
    final celula55 = d.matrizResidual.firstWhere(
      (c) => c.probabilidade == 5 && c.impacto == 5,
    );
    expect(celula55.quantidade, 1);

    // 1 de 3 riscos monitorado
    expect(d.coberturaMonitoramento, closeTo(33.3, 0.1));

    // prioritário nº1 é o de maior residual, com dados da primeira ação
    expect(d.riscosPrioritarios.first.risco.uuid, 'r1');
    expect(d.riscosPrioritarios.first.responsavel, 'Ana');
    expect(d.riscosPrioritarios.first.statusTratamento, 'Em andamento');
  });

  test('filtro por setor restringe a agregação', () async {
    await dao.aplicarDoServidor(
      Recurso.risco,
      _risco('a', categoria: 'Operacional', setor: 1, probRes: 5, impRes: 5),
    );
    await dao.aplicarDoServidor(
      Recurso.risco,
      _risco('b', categoria: 'Imagem', setor: 2, probRes: 5, impRes: 5),
    );

    final d = await dashboardDoCache(const FiltroDashboard(setorId: 2));

    expect(d.totalPlanos, 1);
    expect(d.unidadesMaiorExposicao, hasLength(1));
    expect(d.unidadesMaiorExposicao.first.id, 2);
  });
}
