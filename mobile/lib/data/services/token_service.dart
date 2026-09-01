import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_model.dart';
import '../models/usuario_model.dart';

/// Sessão persistida. O backend usa `TokenAuthentication` do DRF: o token
/// não expira e não há refresh — basta guardá-lo e enviá-lo no header.
class TokenService {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'token';
  static const _keyUsuario = 'usuario';

  Future<void> saveSession(LoginResponse res) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: res.token),
      _storage.write(key: _keyUsuario, value: jsonEncode(res.usuario.toStorageJson())),
    ]);
  }

  Future<void> updateUsuario(UsuarioModel usuario) =>
      _storage.write(key: _keyUsuario, value: jsonEncode(usuario.toStorageJson()));

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<bool> hasToken() async {
    final t = await _storage.read(key: _keyToken);
    return t != null && t.isNotEmpty;
  }

  Future<UsuarioModel?> getUsuario() async {
    final raw = await _storage.read(key: _keyUsuario);
    if (raw == null || raw.isEmpty) return null;
    return UsuarioModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() => _storage.deleteAll();
}

extension _UsuarioStorage on UsuarioModel {
  /// Guarda só o necessário para reconstruir o [UsuarioModel] (mesmas chaves
  /// do JSON da API, para reusar `UsuarioModel.fromJson`).
  Map<String, dynamic> toStorageJson() => {
        'uuid': uuid,
        'id': id,
        'siape': siape,
        'nome': nome,
        'email': email,
        'is_superuser': isSuperuser,
        'ativo': ativo,
        'cargo': cargo,
        'sem_equipe_desde': semEquipeDesde?.toIso8601String(),
        'setores': setores
            .map((s) => {
                  'id': s.id,
                  'nome': s.nome,
                  'sigla': s.sigla,
                  'sigla_centro': s.siglaCentro,
                  'nome_centro': s.nomeCentro,
                  'tipo_unidade': s.tipoUnidade,
                  'fonte_oficial': s.fonteOficial,
                  'ativo': s.ativo,
                  'label_curto': s.labelCurto,
                  'label_completo': s.labelCompleto,
                })
            .toList(),
      };
}
