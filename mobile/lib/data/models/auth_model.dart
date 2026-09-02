import 'usuario_model.dart';

/// Payload de `POST /api/usuarios/login/`.
class LoginRequest {
  const LoginRequest({required this.siape, required this.senha});

  final String siape;
  final String senha;

  Map<String, dynamic> toJson() => {'siape': siape, 'senha': senha};
}

/// Resposta de `POST /api/usuarios/login/`: token DRF (sem expiração,
/// sem refresh) + dados do usuário.
class LoginResponse {
  const LoginResponse({required this.token, required this.usuario});

  final String token;
  final UsuarioModel usuario;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      usuario: UsuarioModel.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }
}
