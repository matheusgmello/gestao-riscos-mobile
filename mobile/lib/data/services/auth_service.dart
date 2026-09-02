import 'package:dio/dio.dart';

import '../../core/api_error.dart';
import '../models/auth_model.dart';
import 'api_client.dart';
import 'token_service.dart';

class AuthService {
  AuthService(this._tokenService) : _client = ApiClient(_tokenService);

  final TokenService _tokenService;
  final ApiClient _client;

  Future<LoginResponse> login(String siape, String senha) async {
    try {
      final res = await _client.dio.post(
        '/api/usuarios/login/',
        data: LoginRequest(siape: siape, senha: senha).toJson(),
      );
      final login = LoginResponse.fromJson(res.data as Map<String, dynamic>);
      await _tokenService.saveSession(login);
      return login;
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<void> logout() => _tokenService.clear();
}
