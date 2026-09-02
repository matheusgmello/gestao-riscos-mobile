class HistoricoEntrada {
  const HistoricoEntrada({
    required this.id,
    required this.usuarioNome,
    required this.dataHora,
    required this.descricao,
  });

  final int id;
  final String usuarioNome;
  final DateTime? dataHora;
  final String descricao;

  factory HistoricoEntrada.fromJson(Map<String, dynamic> j) => HistoricoEntrada(
        id: (j['id'] as num).toInt(),
        usuarioNome: j['usuario_nome'] as String? ?? '',
        dataHora: DateTime.tryParse(j['data_hora'] as String? ?? ''),
        descricao: j['descricao'] as String? ?? '',
      );
}
