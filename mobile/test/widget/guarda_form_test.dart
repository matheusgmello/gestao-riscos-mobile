import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/widgets/guarda_form.dart';

// Simula um form: push de uma tela com GuardaForm, tenta voltar.
Future<void> _abrir(WidgetTester tester, {required bool sujo}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GuardaForm(
                sujo: sujo,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Form')),
                  body: const Text('conteúdo'),
                ),
              ),
            )),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('form limpo: volta direto', (tester) async {
    await _abrir(tester, sujo: false);
    expect(find.text('Form'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Form'), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('form sujo: back mostra diálogo e "Continuar editando" cancela', (tester) async {
    await _abrir(tester, sujo: true);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);

    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.text('Form'), findsOneWidget); // continuou na tela
  });

  testWidgets('form sujo: "Descartar" sai da tela', (tester) async {
    await _abrir(tester, sujo: true);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Form'), findsNothing);
  });
}
