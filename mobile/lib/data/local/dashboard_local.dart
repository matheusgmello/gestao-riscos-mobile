import '../models/dashboard_model.dart';
import '../models/risco_model.dart';
import '../services/dashboard_service.dart';
import 'dao_sync.dart';

/// Ordem canônica das categorias — espelha `CATEGORY_ORDER` do backend.
const _ordemCategorias = [
  'Operacional',
  'Estratégico',
  'Integridade',
  'Imagem',
  'Financeiro',
];

/// Reconstrói o payload de `/planos/dashboard/` a partir do cache local, para
/// o dashboard funcionar offline. Espelha `RiscoViewSet._build_analytics` do
/// backend — só as partes que a tela consome.
Future<Dashboard> dashboardDoCache(FiltroDashboard filtro) async {
  final dao = DaoSync.instance;
  final riscosJson = await dao.riscos();
  final acoesJson = await dao.acoes();
  final monitJson = await dao.monitoramentos();

  final riscos = riscosJson
      .where((j) => j['ativo'] as bool? ?? true)
      .map((j) => (json: j, r: Risco.fromJson(j)))
      .where((e) => filtro.setorId == null || e.r.setorId == filtro.setorId)
      .toList();
  final total = riscos.length;
  final uuids = {for (final e in riscos) e.r.uuid};

  final categorias = {for (final c in _ordemCategorias) c: 0};
  final porNivel = {'extremo': 0, 'alto': 0, 'moderado': 0, 'baixo': 0};
  final matriz = <({int p, int i}), int>{};
  final ranking = <int, Map<String, dynamic>>{};
  var melhorados = 0;

  for (final e in riscos) {
    final r = e.r;
    categorias[r.categoria] = (categorias[r.categoria] ?? 0) + 1;

    final n = r.nivelResidual;
    final faixa = n >= 20
        ? 'extremo'
        : n >= 12
        ? 'alto'
        : n >= 4
        ? 'moderado'
        : 'baixo';
    porNivel[faixa] = porNivel[faixa]! + 1;

    if (r.nivelResidual < r.nivelRisco) melhorados++;

    final chave = (p: r.probResidual, i: r.impResidual);
    matriz[chave] = (matriz[chave] ?? 0) + 1;

    final u = ranking.putIfAbsent(
      r.setorId,
      () => {
        'id': r.setorId,
        'nome': r.setorRotulo,
        'pontos': 0,
        'quantidade_riscos': 0,
        'criticos': 0,
      },
    );
    u['pontos'] = (u['pontos'] as int) + r.nivelResidual;
    u['quantidade_riscos'] = (u['quantidade_riscos'] as int) + 1;
    if (r.nivelResidual >= 12) u['criticos'] = (u['criticos'] as int) + 1;
  }

  // primeira ação de cada risco: menor data_inicio, depois menor id
  final acoes = acoesJson.where((j) => j['ativo'] as bool? ?? true).toList()
    ..sort((a, b) {
      final d = (a['data_inicio'] as String? ?? '').compareTo(
        b['data_inicio'] as String? ?? '',
      );
      return d != 0
          ? d
          : ((a['id'] as num?) ?? 0).toInt().compareTo(
              ((b['id'] as num?) ?? 0).toInt(),
            );
    });
  final primeiraAcao = <String, Map<String, dynamic>>{};
  for (final a in acoes) {
    primeiraAcao.putIfAbsent(a['risco'] as String? ?? '', () => a);
  }

  final comMonitoramento = monitJson
      .where((j) => j['ativo'] as bool? ?? true)
      .map((j) => j['risco'] as String? ?? '')
      .where(uuids.contains)
      .toSet();

  final cobertura = total == 0 ? 0.0 : comMonitoramento.length / total * 100;
  final taxa = total == 0 ? 0.0 : melhorados / total * 100;

  final ordenados = [...riscos]..sort((a, b) {
    final n = b.r.nivelResidual.compareTo(a.r.nivelResidual);
    return n != 0 ? n : b.r.nivelRisco.compareTo(a.r.nivelRisco);
  });
  final prioritarios = ordenados.take(5).map((e) {
    final a = primeiraAcao[e.r.uuid];
    return {
      ...e.json,
      'responsavel': a?['responsavel'],
      'tipo_resposta': a?['tipo_resposta'],
      'status_tratamento': a?['status'],
    };
  }).toList();

  final unidades = ranking.values.toList()
    ..sort((a, b) {
      final p = (b['pontos'] as int).compareTo(a['pontos'] as int);
      if (p != 0) return p;
      final q = (b['quantidade_riscos'] as int).compareTo(
        a['quantidade_riscos'] as int,
      );
      return q != 0 ? q : (a['nome'] as String).compareTo(b['nome'] as String);
    });

  return Dashboard.fromJson({
    'total_planos': total,
    'riscos_criticos': porNivel['alto']! + porNivel['extremo']!,
    'riscos_por_nivel': porNivel,
    'cobertura_monitoramento': cobertura,
    'taxa_mitigacao': taxa,
    'riscos_melhorados': melhorados,
    'distribuicao_categorias': [
      for (final c in _ordemCategorias)
        {'nome': c, 'quantidade': categorias[c] ?? 0},
    ],
    'unidades_maior_exposicao': unidades.take(5).toList(),
    'matriz_residual': [
      for (final i in [5, 4, 3, 2, 1])
        for (final p in [1, 2, 3, 4, 5])
          {
            'probabilidade': p,
            'impacto': i,
            'quantidade': matriz[(p: p, i: i)] ?? 0,
            'score': p * i,
          },
    ],
    'riscos_prioritarios': prioritarios,
  });
}
