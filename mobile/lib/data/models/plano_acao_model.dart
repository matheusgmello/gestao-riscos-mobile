class PlanoAcao {
  const PlanoAcao({
    required this.id,
    required this.riscoUuid,
    required this.tipoResposta,
    required this.descricaoAcao,
    required this.responsavel,
    required this.dataInicio,
    required this.dataFim,
    required this.status,
    this.parceiros = '',
    this.progresso = 0,
    this.observacoes = '',
    this.ativo = true,
  });

  final int id;
  final String riscoUuid;
  final String tipoResposta;
  final String descricaoAcao;
  final String responsavel;
  final String parceiros;
  final String dataInicio;
  final String dataFim;
  final String status;
  final int progresso;
  final String observacoes;
  final bool ativo;

  static const tiposResposta = ['Mitigar', 'Evitar', 'Transferir', 'Aceitar'];
  static const statuses = [
    'Não iniciada',
    'Em andamento',
    'Concluída',
    'Atrasada',
  ];

  factory PlanoAcao.fromJson(Map<String, dynamic> j) => PlanoAcao(
        id: (j['id'] as num).toInt(),
        riscoUuid: j['risco'] as String? ?? '',
        tipoResposta: j['tipo_resposta'] as String? ?? '',
        descricaoAcao: j['descricao_acao'] as String? ?? '',
        responsavel: j['responsavel'] as String? ?? '',
        parceiros: j['parceiros'] as String? ?? '',
        dataInicio: j['data_inicio'] as String? ?? '',
        dataFim: j['data_fim'] as String? ?? '',
        status: j['status'] as String? ?? '',
        progresso: (j['progresso'] as num?)?.toInt() ?? 0,
        observacoes: j['observacoes'] as String? ?? '',
        ativo: j['ativo'] as bool? ?? true,
      );

  Map<String, dynamic> toPayload() => {
        'risco': riscoUuid,
        'tipo_resposta': tipoResposta,
        'descricao_acao': descricaoAcao,
        'responsavel': responsavel,
        'parceiros': parceiros,
        'data_inicio': dataInicio,
        'data_fim': dataFim,
        'status': status,
        'progresso': progresso,
        'observacoes': observacoes,
      };
}
