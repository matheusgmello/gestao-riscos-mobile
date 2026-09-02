import '../../core/api_error.dart';
import 'api_client.dart';
import 'token_service.dart';

/// Fluxo de recuperação de senha — endpoints públicos.
/// O código tem 6 dígitos e expira em 1 minuto.
class RecuperacaoService {
  RecuperacaoService(TokenService tokens) : _client = ApiClient(tokens);

  final ApiClient _client;

  Future<void> enviarCodigo(String email) => comApiError(() async {
    await _client.dio.post(
      '/api/usuarios/recuperar-senha/enviar/',
      data: {'email': email},
    );
  });

  Future<void> validarCodigo(String email, String codigo) =>
      comApiError(() async {
        await _client.dio.post(
          '/api/usuarios/recuperar-senha/validar/',
          data: {'email': email, 'codigo': codigo},
        );
      });

  Future<void> redefinir({
    required String email,
    required String codigo,
    required String novaSenha,
    required String confirmacaoSenha,
  }) => comApiError(() async {
    await _client.dio.post(
      '/api/usuarios/recuperar-senha/redefinir/',
      data: {
        'email': email,
        'codigo': codigo,
        'nova_senha': novaSenha,
        'confirmacao_senha': confirmacaoSenha,
      },
    );
  });
}
