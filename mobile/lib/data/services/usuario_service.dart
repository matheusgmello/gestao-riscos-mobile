import 'package:dio/dio.dart';

import '../../core/api_error.dart';
import '../models/page_response.dart';
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

  // --- Gestão administrativa (superusuário) ---

  /// `GET /api/usuarios/gestores/` — lista todos, com busca e paginação.
  Future<PageResponse<UsuarioModel>> listarGestores({
    int page = 1,
    String? busca,
  }) => comApiError(() async {
    final res = await _client.dio.get(
      '/api/usuarios/gestores/',
      queryParameters: {
        'page': page,
        if (busca != null && busca.isNotEmpty) 'search': busca,
      },
    );
    return PageResponse.fromDrfAdmin(
      res.data as Map<String, dynamic>,
      UsuarioModel.fromJson,
    );
  });

  /// `POST /api/usuarios/registro/`
  Future<void> registrar({
    required String siape,
    required String nome,
    required String email,
    required String senha,
    required List<int> setoresIds,
    required String cargo,
  }) => comApiError(() async {
    await _client.dio.post(
      '/api/usuarios/registro/',
      data: {
        'siape': siape,
        'nome': nome,
        'email': email,
        'senha': senha,
        'id_setores': setoresIds,
        'cargo': cargo,
      },
    );
  });

  /// `PATCH /api/usuarios/gestores/{uuid}/`
  Future<void> editarGestor(
    String uuid, {
    String? nome,
    String? email,
    String? cargo,
    List<int>? setoresIds,
  }) => comApiError(() async {
    await _client.dio.patch(
      '/api/usuarios/gestores/$uuid/',
      data: {
        'nome': ?nome,
        'email': ?email,
        'cargo': ?cargo,
        'id_setores': ?setoresIds,
      },
    );
  });

  /// `DELETE /api/usuarios/gestores/{uuid}/` — soft delete.
  Future<void> desativarGestor(String uuid) => comApiError(() async {
    await _client.dio.delete('/api/usuarios/gestores/$uuid/');
  });

  /// `POST /api/usuarios/gestores/{uuid}/reativar/`
  Future<void> reativarGestor(String uuid) => comApiError(() async {
    await _client.dio.post('/api/usuarios/gestores/$uuid/reativar/');
  });
}
