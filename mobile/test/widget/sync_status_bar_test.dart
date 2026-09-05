import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/sync/conectividade.dart';
import 'package:gestao_risco_mobile/widgets/sync_status_bar.dart';

import '../support/fakes.dart';

Widget _tela() => const MaterialApp(home: Scaffold(body: SyncStatusBar()));

void main() {
  testWidgets('online e sem pendências: barra some', (tester) async {
    prepararAmbienteDeTeste(online: true);
    await tester.pumpWidget(_tela());
    await tester.pump();
    expect(find.byType(SizedBox), findsWidgets); // SizedBox.shrink
    expect(find.textContaining('Offline'), findsNothing);
    expect(find.textContaining('Sincronizando'), findsNothing);
  });

  testWidgets('offline: mostra "mostrando dados salvos"', (tester) async {
    prepararAmbienteDeTeste(online: false);
    await tester.pumpWidget(_tela());
    await tester.pump();
    expect(find.text('Offline · mostrando dados salvos'), findsOneWidget);
  });

  testWidgets('reage a ficar offline em tempo real', (tester) async {
    prepararAmbienteDeTeste(online: true);
    await tester.pumpWidget(_tela());
    await tester.pump();
    expect(find.textContaining('Offline'), findsNothing);

    Conectividade.instance.emitirParaTeste(online: false);
    await tester.pump(); // entrega o evento do stream
    await tester.pump(); // rebuild
    expect(find.textContaining('Offline'), findsOneWidget);
  });
}
