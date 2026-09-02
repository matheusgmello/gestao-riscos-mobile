import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/services/exportacao_service.dart';

void main() {
  test('nomeDoContentDisposition extrai filename', () {
    expect(
      nomeDoContentDisposition('attachment; filename="planos-risco.xlsx"'),
      'planos-risco.xlsx',
    );
    expect(
      nomeDoContentDisposition('attachment; filename=relatorio.pdf'),
      'relatorio.pdf',
    );
    expect(nomeDoContentDisposition(null), isNull);
    expect(nomeDoContentDisposition('inline'), isNull);
  });
}
