class Monitoramento {
  const Monitoramento({
    required this.id,
    required this.riscoUuid,
    required this.resultados,
    required this.acoesFuturas,
    required this.analiseCritica,
    this.dataVerificacao = '',
    this.ativo = true,
    this.atualizadoEm,
  });

  final int id;
  final String riscoUuid;
  final String resultados;
  final String acoesFuturas;
  final String analiseCritica;
  final String dataVerificacao;
  final bool ativo;
  final String? atualizadoEm;

  factory Monitoramento.fromJson(Map<String, dynamic> j) => Monitoramento(
    id: (j['id'] as num).toInt(),
    riscoUuid: j['risco'] as String? ?? '',
    resultados: j['resultados'] as String? ?? '',
    acoesFuturas: j['acoes_futuras'] as String? ?? '',
    analiseCritica: j['analise_critica'] as String? ?? '',
    dataVerificacao: j['data_verificacao'] as String? ?? '',
    ativo: j['ativo'] as bool? ?? true,
    atualizadoEm: j['atualizado_em'] as String?,
  );

  Map<String, dynamic> toPayload() => {
    'risco': riscoUuid,
    'resultados': resultados,
    'acoes_futuras': acoesFuturas,
    'analise_critica': analiseCritica,
  };
}
