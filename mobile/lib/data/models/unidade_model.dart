/// `Setor` no backend (tabela `setores`); alias público `UnidadeOrganizacional`.
class UnidadeModel {
  const UnidadeModel({
    required this.id,
    required this.nome,
    required this.sigla,
    this.siglaCentro = '',
    this.nomeCentro = '',
    this.tipoUnidade = '',
    this.fonteOficial = false,
    this.ativo = true,
    this.labelCurto = '',
    this.labelCompleto = '',
  });

  final int id;
  final String nome;
  final String sigla;
  final String siglaCentro;
  final String nomeCentro;
  final String tipoUnidade;
  final bool fonteOficial;
  final bool ativo;
  final String labelCurto;
  final String labelCompleto;

  String get rotulo => labelCurto.isNotEmpty ? labelCurto : nome;

  factory UnidadeModel.fromJson(Map<String, dynamic> json) {
    return UnidadeModel(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String? ?? '',
      sigla: json['sigla'] as String? ?? '',
      siglaCentro: json['sigla_centro'] as String? ?? '',
      nomeCentro: json['nome_centro'] as String? ?? '',
      tipoUnidade: json['tipo_unidade'] as String? ?? '',
      fonteOficial: json['fonte_oficial'] as bool? ?? false,
      ativo: json['ativo'] as bool? ?? true,
      labelCurto: json['label_curto'] as String? ?? '',
      labelCompleto: json['label_completo'] as String? ?? '',
    );
  }
}
