import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/widgets/nivel_badge.dart';

Widget _wrap(Widget c) => MaterialApp(home: Scaffold(body: Center(child: c)));

Color _corDoTexto(WidgetTester t, String texto) {
  final w = t.widget<Text>(find.text(texto));
  return w.style!.color!;
}

void main() {
  // Regressão do audit de tema: branco sobre o âmbar do "Moderado" falhava
  // contraste. O badge escolhe a cor do texto pelo brilho da faixa.
  testWidgets('badge "Moderado" (âmbar) usa texto escuro', (tester) async {
    await tester.pumpWidget(_wrap(const NivelBadge(6))); // 4..11 -> moderado
    expect(_corDoTexto(tester, 'Moderado · 6'), Colors.black87);
  });

  testWidgets('badge "Extremo" (vermelho) usa texto claro', (tester) async {
    await tester.pumpWidget(_wrap(const NivelBadge(25)));
    expect(_corDoTexto(tester, 'Extremo · 25'), Colors.white);
  });

  testWidgets('badge "Baixo" (verde) usa texto claro', (tester) async {
    await tester.pumpWidget(_wrap(const NivelBadge(2)));
    expect(_corDoTexto(tester, 'Baixo · 2'), Colors.white);
  });

  testWidgets('compacto mostra só o número', (tester) async {
    await tester.pumpWidget(_wrap(const NivelBadge(6, compacto: true)));
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Moderado · 6'), findsNothing);
  });
}
