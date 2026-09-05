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
    final e = ApiError.fromDio(
      _erro(400, {'erro': 'SIAPE ou senha inválidos.'}),
    );
    expect(e.message, 'SIAPE ou senha inválidos.');
    expect(e.statusCode, 400);
  });

  test('extrai primeiro erro de campo do DRF', () {
    final e = ApiError.fromDio(
      _erro(400, {
        'senha': ['A senha deve ter pelo menos 8 caracteres.'],
        'email': ['Já existe usuário com este e-mail.'],
      }),
    );
    expect(e.message, 'A senha deve ter pelo menos 8 caracteres.');
    expect(e.fields, isNotNull);
    expect(e.fields!.keys, containsAll(['senha', 'email']));
  });

  test('cai em mensagem por status quando o corpo não ajuda', () {
    final e = ApiError.fromDio(_erro(403, null));
    expect(e.message, 'Você não tem permissão para esta ação.');
  });

  group('mensagemDeErro', () {
    test('ApiError devolve a própria message', () {
      expect(mensagemDeErro(ApiError('x falhou')), 'x falhou');
    });

    test('DioException de conexão vira cópia amigável', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );
      expect(mensagemDeErro(e), 'Não foi possível conectar ao servidor.');
    });

    test('DioException de timeout vira cópia amigável', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      );
      expect(mensagemDeErro(e), contains('Tempo de conexão'));
    });

    test('tira o prefixo "Exception: "', () {
      expect(
        mensagemDeErro(Exception('Risco não encontrado no cache.')),
        'Risco não encontrado no cache.',
      );
    });

    test('objeto qualquer cai no toString', () {
      expect(mensagemDeErro('erro solto'), 'erro solto');
    });
  });
}
