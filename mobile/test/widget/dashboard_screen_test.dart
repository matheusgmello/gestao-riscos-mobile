import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/core/api_error.dart';
import 'package:gestao_risco_mobile/data/models/dashboard_model.dart';
import 'package:gestao_risco_mobile/features/dashboard/dashboard_screen.dart';
import 'package:gestao_risco_mobile/widgets/estado.dart';

import '../support/fakes.dart';

Widget _tela(DashboardScreen s) => MaterialApp(home: s);

void main() {
  setUp(() => prepararAmbienteDeTeste(online: false, telaAlta: true));

  testWidgets('erro vira EstadoErro com Retry', (tester) async {
    await tester.pumpWidget(_tela(DashboardScreen(
      service: FakeDashboardService(erro: ApiError('Falhou.')),
      unidades: FakeUnidadeService(),
      tokens: tokensComUsuario(),
    )));
    await tester.pumpAndSettle();

    expect(find.byType(EstadoErro), findsOneWidget);
    expect(find.text('Falhou.'), findsOneWidget);
  });

  testWidgets('renderiza KPIs e seções a partir do serviço', (tester) async {
    final dados = Dashboard.fromJson(const {
      'total_planos': 9,
      'riscos_criticos': 4,
      'riscos_por_nivel': {'extremo': 1, 'alto': 3, 'moderado': 4, 'baixo': 1},
      'cobertura_monitoramento': 22.0,
      'taxa_mitigacao': 100.0,
      'distribuicao_categorias': [
        {'nome': 'Operacional', 'quantidade': 3},
        {'nome': 'Imagem', 'quantidade': 2},
      ],
      'unidades_maior_exposicao': [],
      'matriz_residual': [],
      'riscos_prioritarios': [],
    });
    await tester.pumpWidget(_tela(DashboardScreen(
      service: FakeDashboardService(dados: dados),
      unidades: FakeUnidadeService(),
      tokens: tokensComUsuario(),
    )));
    await tester.pumpAndSettle();

    expect(find.text('9'), findsOneWidget); // total de riscos
    expect(find.text('Total de riscos'), findsOneWidget);
    expect(find.text('Riscos por nível'), findsOneWidget);
    expect(find.text('Distribuição por categoria'), findsOneWidget);
    expect(find.text('Operacional'), findsOneWidget); // gráfico virou lista
  });
}
