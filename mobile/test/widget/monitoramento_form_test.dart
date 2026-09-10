import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/models/monitoramento_model.dart';
import 'package:gestao_risco_mobile/features/monitoramentos/monitoramento_form_screen.dart';

import '../support/fakes.dart';

void main() {
  setUp(() => prepararAmbienteDeTeste(telaAlta: true));

  testWidgets('"Tirar foto" mostra o preview e o botão Remover', (tester) async {
    final png = File(
      '${Directory.systemTemp.path}/wtest_${DateTime.now().microsecondsSinceEpoch}.png',
    )..writeAsBytesSync(_png1x1);
    addTearDown(() => png.existsSync() ? png.deleteSync() : null);

    await tester.pumpWidget(MaterialApp(
      home: MonitoramentoFormScreen(
        riscoUuid: 'r1',
        repo: FakeRiscoRepositorio(),
        capturarFoto: () async => png.path,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tirar foto'), findsOneWidget);
    expect(find.text('Remover'), findsNothing);

    await tester.tap(find.text('Tirar foto'));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
    expect(find.text('Remover'), findsOneWidget);
    expect(find.text('Trocar foto'), findsOneWidget);
  });

  testWidgets('monitoramento com foto do servidor mostra o preview de rede',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MonitoramentoFormScreen(
        riscoUuid: 'r1',
        repo: FakeRiscoRepositorio(),
        monitoramento: const Monitoramento(
          id: 1,
          riscoUuid: 'r1',
          resultados: 'a',
          acoesFuturas: 'b',
          analiseCritica: 'c',
          foto: 'http://x/media/monitoramentos/e.png',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Trocar foto'), findsOneWidget);
  });
}

const _png1x1 = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
