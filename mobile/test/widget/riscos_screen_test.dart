import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/core/api_error.dart';
import 'package:gestao_risco_mobile/features/riscos/riscos_screen.dart';
import 'package:gestao_risco_mobile/widgets/estado.dart';

import '../support/fakes.dart';

Widget _tela(RiscosScreen s) => MaterialApp(home: s);

void main() {
  setUp(() => prepararAmbienteDeTeste(online: false));

  testWidgets('erro ao carregar mostra EstadoErro com mensagem tratada + Retry', (tester) async {
    final repo = FakeRiscoRepositorio(erroAoListar: ApiError('Sem conexão.'));
    await tester.pumpWidget(_tela(RiscosScreen(
      repo: repo,
      unidades: FakeUnidadeService(),
      pdi: FakePdiService(),
    )));
    await tester.pumpAndSettle();

    expect(find.byType(EstadoErro), findsOneWidget);
    expect(find.text('Sem conexão.'), findsOneWidget);
    expect(find.textContaining('ApiError'), findsNothing);

    // Retry chama listar de novo
    final antes = repo.chamadasListar;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(repo.chamadasListar, greaterThan(antes));
  });

  testWidgets('lista vazia mostra CTA "Criar o primeiro risco"', (tester) async {
    await tester.pumpWidget(_tela(RiscosScreen(
      repo: FakeRiscoRepositorio(lista: const []),
      unidades: FakeUnidadeService(),
      pdi: FakePdiService(),
      tokens: tokensComUsuario(setores: [1]),
    )));
    await tester.pumpAndSettle();

    expect(find.byType(EstadoVazio), findsOneWidget);
    expect(find.text('Criar o primeiro risco'), findsOneWidget);
  });

  testWidgets('gestor sem setor: lista vazia sem CTA de criar', (tester) async {
    await tester.pumpWidget(_tela(RiscosScreen(
      repo: FakeRiscoRepositorio(lista: const []),
      unidades: FakeUnidadeService(),
      pdi: FakePdiService(),
      tokens: tokensComUsuario(setores: const []),
    )));
    await tester.pumpAndSettle();

    expect(find.byType(EstadoVazio), findsOneWidget);
    expect(find.text('Criar o primeiro risco'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('lista renderiza cards e o badge de pendente', (tester) async {
    await tester.pumpWidget(_tela(RiscosScreen(
      repo: FakeRiscoRepositorio(lista: [
        risco(uuid: 'a', categoria: 'Operacional'),
        risco(uuid: 'b', categoria: 'Imagem', pendente: true),
      ]),
      unidades: FakeUnidadeService(),
      pdi: FakePdiService(),
      tokens: tokensComUsuario(setores: [1]),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Evento a'), findsOneWidget);
    expect(find.text('Evento b'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget); // só o pendente
  });
}
