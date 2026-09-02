import 'package:dio/dio.dart';

import '../../core/api_error.dart';
import '../models/usuario_model.dart';
import 'api_client.dart';
import 'token_service.dart';

class UsuarioService {
  UsuarioService(this._tokenService) : _client = ApiClient(_tokenService);

  final TokenService _tokenService;
  final ApiClient _client;

  /// `GET /api/usuarios/me/` — também atualiza a sessão em cache.
  Future<UsuarioModel> me() async {
    try {
      final res = await _client.dio.get('/api/usuarios/me/');
      final usuario = UsuarioModel.fromJson(res.data as Map<String, dynamic>);
      await _tokenService.updateUsuario(usuario);
      return usuario;
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  /// `PATCH /api/usuarios/me/` — e-mail e/ou troca de senha.
  Future<UsuarioModel> atualizarPerfil({
    String? email,
    String? senhaAtual,
    String? novaSenha,
    String? confirmacaoSenha,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (novaSenha != null && novaSenha.isNotEmpty) {
      body['senha_atual'] = senhaAtual;
      body['nova_senha'] = novaSenha;
      body['confirmacao_senha'] = confirmacaoSenha;
    }
    try {
      await _client.dio.patch('/api/usuarios/me/', data: body);
      return await me();
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }
}
