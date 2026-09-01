import 'package:dio/dio.dart';

import '../../core/env.dart';
import 'token_service.dart';

/// Dio configurado com a base da API e o token DRF no header.
/// Em `401` a sessão é limpa; a próxima navegação cai no `redirect` do
/// go_router e volta para o login. Não há refresh.
class ApiClient {
  ApiClient(this._tokenService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Token $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenService.clear();
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  final TokenService _tokenService;

  Dio get dio => _dio;
}
