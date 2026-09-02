import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/models/dashboard_model.dart';
import 'package:gestao_risco_mobile/data/services/dashboard_service.dart';

void main() {
  test('Dashboard.fromJson mapeia o payload de _build_analytics', () {
    final d = Dashboard.fromJson({
      'total_planos': 9,
      'riscos_criticos': 4,
      'riscos_por_nivel': {
        'extremo': 1,
        'alto': 3,
        'moderado': 4,
        'baixo': 1,
      },
      'status_tratamentos': {
        'em_andamento': 4,
        'concluidas': 1,
        'atrasadas': 0,
        'nao_iniciadas': 4,
      },
      'acoes_atrasadas': 1,
      'riscos_sem_acao': 0,
      'riscos_monitorados': 2,
      'cobertura_monitoramento': 22.2,
      'objetivos_cobertos': 9,
      'desafios_cobertos': 4,
      'taxa_mitigacao': 100.0,
      'riscos_melhorados': 9,
      'distribuicao_categorias': [
        {'nome': 'Operacional', 'quantidade': 3},
        {'nome': 'Imagem', 'quantidade': 2},
      ],
      'unidades_maior_exposicao': [
        {
          'id': 11,
          'nome': 'CT',
          'pontos': 20,
          'quantidade_riscos': 1,
          'criticos': 1,
        },
      ],
      'matriz_residual': [
        {'probabilidade': 4, 'impacto': 5, 'quantidade': 1, 'score': 20},
      ],
      'riscos_prioritarios': [
        {
          'uuid': 'abc',
          'setor': 1,
          'objetivo': 2,
          'macroprocesso': 3,
          'categoria': 'Operacional',
          'evento': 'e',
          'causa': 'c',
          'consequencia': 'q',
          'controles_atuais': 'ca',
          'eficacia_controle': 'Fraco',
          'probabilidade': 4,
          'impacto': 5,
          'nivel_risco': 20,
          'prob_residual': 2,
          'imp_residual': 3,
          'nivel_residual': 6,
          'responsavel': 'Fulano',
          'tipo_resposta': 'Mitigar',
          'status_tratamento': 'Em andamento',
        },
      ],
    });

    expect(d.totalPlanos, 9);
    expect(d.riscosPorNivel.total, 9);
    expect(d.coberturaMonitoramento, 22.2);
    expect(d.distribuicaoCategorias.first.nome, 'Operacional');
    expect(d.matrizResidual.single.quantidade, 1);
    expect(d.riscosPrioritarios.single.responsavel, 'Fulano');
    expect(d.riscosPrioritarios.single.risco.uuid, 'abc');
  });

  test('FiltroDashboard.toQuery só inclui o que está setado', () {
    expect(const FiltroDashboard().toQuery(), isEmpty);
    final q = const FiltroDashboard(setorId: 5, busca: 'x').toQuery();
    expect(q, {'setor': 5, 'search': 'x'});
  });
}
