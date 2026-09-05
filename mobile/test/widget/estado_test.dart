import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/core/api_error.dart';
import 'package:gestao_risco_mobile/widgets/estado.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('EstadoVazio mostra título, detalhe e ação', (tester) async {
    var tocou = false;
    await tester.pumpWidget(_wrap(EstadoVazio(
      icone: Icons.inbox,
      titulo: 'Nada aqui',
      detalhe: 'Crie o primeiro item.',
      acao: FilledButton(onPressed: () => tocou = true, child: const Text('Criar')),
    )));

    expect(find.text('Nada aqui'), findsOneWidget);
    expect(find.text('Crie o primeiro item.'), findsOneWidget);
    await tester.tap(find.text('Criar'));
    expect(tocou, isTrue);
  });

  testWidgets('EstadoErro usa mensagemDeErro (nunca o erro cru) e chama onTentar', (tester) async {
    var tentou = 0;
    await tester.pumpWidget(_wrap(EstadoErro(
      erro: Exception('Risco não encontrado no cache.'),
      onTentar: () => tentou++,
    )));

    // sem "Exception:" na tela
    expect(find.text('Risco não encontrado no cache.'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);

    await tester.tap(find.text('Tentar de novo'));
    expect(tentou, 1);
  });

  testWidgets('EstadoErro sem onTentar não mostra botão', (tester) async {
    await tester.pumpWidget(_wrap(EstadoErro(erro: ApiError('x'))));
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('SkeletonLista renderiza N placeholders', (tester) async {
    await tester.pumpWidget(_wrap(const SkeletonLista(itens: 3)));
    expect(find.byType(Container), findsNWidgets(3));
  });
}
