import 'dart:convert';
import 'dart:ui' show Size;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/models/dashboard_model.dart';
import 'package:gestao_risco_mobile/data/models/historico_model.dart';
import 'package:gestao_risco_mobile/data/models/monitoramento_model.dart';
import 'package:gestao_risco_mobile/data/models/pdi_model.dart';
import 'package:gestao_risco_mobile/data/models/plano_acao_model.dart';
import 'package:gestao_risco_mobile/data/models/risco_model.dart';
import 'package:gestao_risco_mobile/data/models/unidade_model.dart';
import 'package:gestao_risco_mobile/data/repositorios/risco_repositorio.dart';
import 'package:gestao_risco_mobile/data/services/dashboard_service.dart';
import 'package:gestao_risco_mobile/data/services/pdi_service.dart';
import 'package:gestao_risco_mobile/data/services/token_service.dart';
import 'package:gestao_risco_mobile/data/services/unidade_service.dart';
import 'package:gestao_risco_mobile/data/sync/conectividade.dart';

/// Prepara o ambiente de teste de widget: dotenv, secure storage e
/// conectividade sem tocar em plataforma.
void prepararAmbienteDeTeste({bool online = true, bool telaAlta = false}) {
  final b = TestWidgetsFlutterBinding.ensureInitialized();
  if (!dotenv.isInitialized) {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://10.0.2.2:8000');
  }
  FlutterSecureStorage.setMockInitialValues({});
  Conectividade.definirParaTeste(online: online);
  if (telaAlta) {
    // superfície bem alta: todo o conteúdo de um ListView cabe sem scroll
    b.platformDispatcher.views.first.physicalSize = const Size(1200, 6000);
    b.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(() {
      b.platformDispatcher.views.first.resetPhysicalSize();
      b.platformDispatcher.views.first.resetDevicePixelRatio();
    });
  }
}

/// TokenService com uma sessão fake no secure storage mockado.
/// `setores` vazio = gestor sem setor (não pode criar risco).
TokenService tokensComUsuario({
  List<int> setores = const [1],
  bool admin = false,
  String cargo = 'gestor',
}) {
  FlutterSecureStorage.setMockInitialValues({
    'token': 't',
    'usuario': jsonEncode({
      'uuid': 'u-1',
      'id': 1,
      'siape': '123',
      'nome': 'Fulano',
      'email': 'f@ufsm.br',
      'is_superuser': admin,
      'ativo': true,
      'cargo': cargo,
      'sem_equipe_desde': null,
      'setores': [
        for (final id in setores)
          {
            'id': id,
            'nome': 'Setor $id',
            'sigla': 'S$id',
            'sigla_centro': 'C',
            'nome_centro': 'Centro',
            'tipo_unidade': 'Departamento',
            'fonte_oficial': true,
            'ativo': true,
            'label_curto': 'S$id',
            'label_completo': 'Setor $id',
          },
      ],
    }),
  });
  return TokenService();
}

Risco risco({
  String uuid = 'r1',
  int setor = 1,
  String categoria = 'Operacional',
  int prob = 2,
  int impacto = 2,
  int probRes = 1,
  int impRes = 1,
  bool pendente = false,
}) => Risco.fromJson({
  'uuid': uuid,
  'setor': setor,
  'objetivo': 1,
  'macroprocesso': 1,
  'categoria': categoria,
  'evento': 'Evento $uuid',
  'causa': 'c',
  'consequencia': 'q',
  'controles_atuais': 'x',
  'eficacia_controle': 'Fraco',
  'probabilidade': prob,
  'impacto': impacto,
  'nivel_risco': prob * impacto,
  'prob_residual': probRes,
  'imp_residual': impRes,
  'nivel_residual': probRes * impRes,
  'ativo': true,
  'pendente_sync': pendente,
});

class FakeRiscoRepositorio extends Fake implements RiscoRepositorio {
  FakeRiscoRepositorio({this.lista = const [], this.erroAoListar, this.detalhe});

  List<Risco> lista;
  Object? erroAoListar;
  Risco? detalhe;
  int chamadasListar = 0;

  @override
  Future<List<Risco>> listar() async {
    chamadasListar++;
    if (erroAoListar != null) throw erroAoListar!;
    return lista;
  }

  @override
  Future<Risco?> obter(String uuid) async => detalhe;

  @override
  Future<List<PlanoAcao>> acoes(String riscoUuid) async => const [];

  @override
  Future<List<Monitoramento>> monitoramentos(String riscoUuid) async => const [];

  @override
  Future<List<HistoricoEntrada>> historico(String uuid) async => const [];
}

class FakeUnidadeService extends Fake implements UnidadeService {
  FakeUnidadeService({this.unidades = const []});
  List<UnidadeModel> unidades;
  @override
  Future<List<UnidadeModel>> listar() async => unidades;
}

class FakePdiService extends Fake implements PdiService {
  @override
  Future<List<ObjetivoPdi>> objetivos() async => const [];
  @override
  Future<List<Macroprocesso>> macroprocessos() async => const [];
  @override
  Future<List<DesafioPdi>> desafios() async => const [];
}

class FakeDashboardService extends Fake implements DashboardService {
  FakeDashboardService({this.dados, this.erro});
  Dashboard? dados;
  Object? erro;
  @override
  Future<Dashboard> carregar([
    FiltroDashboard filtro = const FiltroDashboard(),
  ]) async {
    if (erro != null) throw erro!;
    return dados ?? dashboardVazio();
  }
}

Dashboard dashboardVazio() => Dashboard.fromJson(const {
  'total_planos': 0,
  'riscos_criticos': 0,
  'riscos_por_nivel': {'extremo': 0, 'alto': 0, 'moderado': 0, 'baixo': 0},
  'cobertura_monitoramento': 0,
  'taxa_mitigacao': 0,
  'distribuicao_categorias': [],
  'unidades_maior_exposicao': [],
  'matriz_residual': [],
  'riscos_prioritarios': [],
});

UnidadeModel unidade({int id = 1, String nome = 'CT'}) => UnidadeModel.fromJson({
  'id': id,
  'nome': nome,
  'sigla': nome,
  'sigla_centro': nome,
  'nome_centro': nome,
  'tipo_unidade': 'Departamento',
});
