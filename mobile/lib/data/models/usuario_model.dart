import '../../core/role.dart';
import 'unidade_model.dart';

/// Resposta de `GET /api/usuarios/me/` e do bloco `usuario` do login.
class UsuarioModel {
  const UsuarioModel({
    required this.uuid,
    required this.id,
    required this.siape,
    required this.nome,
    this.email,
    this.setores = const [],
    this.isSuperuser = false,
    this.ativo = true,
    this.cargo = 'gestor',
    this.semEquipeDesde,
  });

  final String uuid;
  final int id;
  final String siape;
  final String nome;
  final String? email;
  final List<UnidadeModel> setores;
  final bool isSuperuser;
  final bool ativo;
  final String cargo;
  final DateTime? semEquipeDesde;

  Role get role => Role.from(cargo: cargo, isSuperuser: isSuperuser);
  List<int> get setoresIds => setores.map((s) => s.id).toList();

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      uuid: json['uuid'] as String? ?? '',
      id: (json['id'] as num?)?.toInt() ?? 0,
      siape: json['siape'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      email: json['email'] as String?,
      setores: (json['setores'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UnidadeModel.fromJson)
          .toList(),
      isSuperuser: json['is_superuser'] as bool? ?? false,
      ativo: json['ativo'] as bool? ?? true,
      cargo: json['cargo'] as String? ?? 'gestor',
      semEquipeDesde: json['sem_equipe_desde'] == null
          ? null
          : DateTime.tryParse(json['sem_equipe_desde'] as String),
    );
  }
}
