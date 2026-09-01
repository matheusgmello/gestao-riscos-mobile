import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/core/api_error.dart';

DioException _erro(int status, dynamic body) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: status, data: body),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  test('extrai {"erro": ...}', () {
    final e = ApiError.fromDio(_erro(400, {'erro': 'SIAPE ou senha inválidos.'}));
    expect(e.message, 'SIAPE ou senha inválidos.');
    expect(e.statusCode, 400);
  });

  test('extrai primeiro erro de campo do DRF', () {
    final e = ApiError.fromDio(_erro(400, {
      'senha': ['A senha deve ter pelo menos 8 caracteres.'],
      'email': ['Já existe usuário com este e-mail.'],
    }));
    expect(e.message, 'A senha deve ter pelo menos 8 caracteres.');
    expect(e.fields, isNotNull);
    expect(e.fields!.keys, containsAll(['senha', 'email']));
  });

  test('cai em mensagem por status quando o corpo não ajuda', () {
    final e = ApiError.fromDio(_erro(403, null));
    expect(e.message, 'Você não tem permissão para esta ação.');
  });
}
