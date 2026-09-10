class Monitoramento {
  const Monitoramento({
    required this.id,
    required this.riscoUuid,
    required this.resultados,
    required this.acoesFuturas,
    required this.analiseCritica,
    this.dataVerificacao = '',
    this.foto,
    this.fotoLocalPath,
    this.ativo = true,
    this.atualizadoEm,
  });

  final int id;
  final String riscoUuid;
  final String resultados;
  final String acoesFuturas;
  final String analiseCritica;
  final String dataVerificacao;

  /// URL da foto de evidência no servidor (leitura).
  final String? foto;

  /// Caminho do arquivo local enquanto a foto ainda não sincronizou.
  final String? fotoLocalPath;

  final bool ativo;
  final String? atualizadoEm;

  bool get temFoto => (foto != null && foto!.isNotEmpty) || fotoLocalPath != null;

  factory Monitoramento.fromJson(Map<String, dynamic> j) => Monitoramento(
    id: (j['id'] as num).toInt(),
    riscoUuid: j['risco'] as String? ?? '',
    resultados: j['resultados'] as String? ?? '',
    acoesFuturas: j['acoes_futuras'] as String? ?? '',
    analiseCritica: j['analise_critica'] as String? ?? '',
    dataVerificacao: j['data_verificacao'] as String? ?? '',
    foto: j['foto'] as String?,
    fotoLocalPath: j['foto_local_path'] as String?,
    ativo: j['ativo'] as bool? ?? true,
    atualizadoEm: j['atualizado_em'] as String?,
  );

  /// Payload de texto. A foto sobe via multipart no [MotorSync], não aqui.
  Map<String, dynamic> toPayload() => {
    'risco': riscoUuid,
    'resultados': resultados,
    'acoes_futuras': acoesFuturas,
    'analise_critica': analiseCritica,
  };
}
