import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/features/riscos/risco_form_screen.dart';

import '../support/fakes.dart';

Widget _tela(RiscoFormScreen s) => MaterialApp(home: s);

void main() {
  setUp(() => prepararAmbienteDeTeste(online: false, telaAlta: true));

  testWidgets('form novo carrega e mostra os campos', (tester) async {
    await tester.pumpWidget(_tela(RiscoFormScreen(
      repo: FakeRiscoRepositorio(),
      pdi: FakePdiService(),
      unidades: FakeUnidadeService(unidades: [unidade(id: 1)]),
      tokens: tokensComUsuario(setores: [1]),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Novo risco'), findsOneWidget);
    expect(find.text('Unidade *'), findsOneWidget);
    expect(find.text('Criar risco'), findsOneWidget);
  });

  testWidgets('editar risco com residual > inerente mostra o aviso', (tester) async {
    final r = risco(prob: 2, impacto: 2, probRes: 5, impRes: 5); // 4 vs 25
    await tester.pumpWidget(_tela(RiscoFormScreen(
      risco: r,
      repo: FakeRiscoRepositorio(),
      pdi: FakePdiService(),
      unidades: FakeUnidadeService(unidades: [unidade(id: 1)]),
      tokens: tokensComUsuario(setores: [1]),
    )));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('risco residual está maior que o inerente'),
      findsOneWidget,
    );
  });

  testWidgets('sem residual > inerente, sem aviso', (tester) async {
    final r = risco(prob: 5, impacto: 5, probRes: 1, impRes: 1);
    await tester.pumpWidget(_tela(RiscoFormScreen(
      risco: r,
      repo: FakeRiscoRepositorio(),
      pdi: FakePdiService(),
      unidades: FakeUnidadeService(unidades: [unidade(id: 1)]),
      tokens: tokensComUsuario(setores: [1]),
    )));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('risco residual está maior que o inerente'),
      findsNothing,
    );
  });
}
