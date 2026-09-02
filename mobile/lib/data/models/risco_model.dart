import '../../core/nivel_risco.dart';
import 'pdi_model.dart';
import 'unidade_model.dart';

class Risco {
  const Risco({
    required this.uuid,
    required this.setorId,
    required this.objetivoId,
    required this.macroprocessoId,
    required this.categoria,
    required this.evento,
    required this.causa,
    required this.consequencia,
    required this.controlesAtuais,
    required this.eficaciaControle,
    required this.probabilidade,
    required this.impacto,
    required this.nivelRisco,
    required this.probResidual,
    required this.impResidual,
    required this.nivelResidual,
    this.setor,
    this.objetivo,
    this.macroprocesso,
    this.periodoInicio,
    this.periodoFim,
    this.possuiPlanoAcao = false,
    this.possuiMonitoramento = false,
    this.ativo = true,
    this.atualizadoEm,
    this.pendenteSync = false,
  });

  final String uuid;
  final int setorId;
  final int objetivoId;
  final int macroprocessoId;
  final String categoria;
  final String evento;
  final String causa;
  final String consequencia;
  final String controlesAtuais;
  final String eficaciaControle;
  final int probabilidade;
  final int impacto;
  final int nivelRisco;
  final int probResidual;
  final int impResidual;
  final int nivelResidual;

  final UnidadeModel? setor;
  final ObjetivoPdi? objetivo;
  final Macroprocesso? macroprocesso;
  final String? periodoInicio;
  final String? periodoFim;
  final bool possuiPlanoAcao;
  final bool possuiMonitoramento;

  /// `false` = registro desativado (soft delete). Usado pelo cache offline
  /// para propagar a exclusão feita no servidor.
  final bool ativo;

  /// `atualizado_em` do servidor (ISO 8601). Cursor do pull incremental e
  /// versão-base enviada no PATCH para a checagem de concorrência.
  final String? atualizadoEm;

  /// `true` quando há uma alteração local ainda não sincronizada.
  final bool pendenteSync;

  FaixaNivel get faixaInerente => FaixaNivel.of(nivelRisco);
  FaixaNivel get faixaResidual => FaixaNivel.of(nivelResidual);
  String get setorRotulo => setor?.rotulo ?? 'Setor $setorId';

  static const categorias = [
    'Operacional',
    'Estratégico',
    'Integridade',
    'Imagem',
    'Financeiro',
  ];
  static const eficacias = ['Inexistente', 'Fraco', 'Satisfatório', 'Forte'];

  factory Risco.fromJson(Map<String, dynamic> j) {
    final sd = j['setor_detalhes'];
    final od = j['objetivo_detalhes'];
    final md = j['macroprocesso_detalhes'];
    final periodo = j['periodo_acao'];
    return Risco(
      uuid: j['uuid'] as String,
      setorId: (j['setor'] as num).toInt(),
      objetivoId: (j['objetivo'] as num).toInt(),
      macroprocessoId: (j['macroprocesso'] as num).toInt(),
      categoria: j['categoria'] as String? ?? '',
      evento: j['evento'] as String? ?? '',
      causa: j['causa'] as String? ?? '',
      consequencia: j['consequencia'] as String? ?? '',
      controlesAtuais: j['controles_atuais'] as String? ?? '',
      eficaciaControle: j['eficacia_controle'] as String? ?? '',
      probabilidade: (j['probabilidade'] as num?)?.toInt() ?? 1,
      impacto: (j['impacto'] as num?)?.toInt() ?? 1,
      nivelRisco: (j['nivel_risco'] as num?)?.toInt() ?? 0,
      probResidual: (j['prob_residual'] as num?)?.toInt() ?? 1,
      impResidual: (j['imp_residual'] as num?)?.toInt() ?? 1,
      nivelResidual: (j['nivel_residual'] as num?)?.toInt() ?? 0,
      setor: sd is Map<String, dynamic> ? UnidadeModel.fromJson(sd) : null,
      objetivo: od is Map<String, dynamic> ? ObjetivoPdi.fromJson(od) : null,
      macroprocesso: md is Map<String, dynamic>
          ? Macroprocesso.fromJson(md)
          : null,
      periodoInicio: periodo is Map ? periodo['data_inicio'] as String? : null,
      periodoFim: periodo is Map ? periodo['data_fim'] as String? : null,
      possuiPlanoAcao: j['possui_plano_acao'] as bool? ?? false,
      possuiMonitoramento: j['possui_monitoramento'] as bool? ?? false,
      ativo: j['ativo'] as bool? ?? true,
      atualizadoEm: j['atualizado_em'] as String?,
      pendenteSync: j['pendente_sync'] as bool? ?? false,
    );
  }

  /// Payload de criação/edição. Nunca envia `nivel_risco`/`nivel_residual`
  /// (calculados no backend).
  Map<String, dynamic> toPayload() => {
    'setor': setorId,
    'objetivo': objetivoId,
    'macroprocesso': macroprocessoId,
    'categoria': categoria,
    'evento': evento,
    'causa': causa,
    'consequencia': consequencia,
    'controles_atuais': controlesAtuais,
    'eficacia_controle': eficaciaControle,
    'probabilidade': probabilidade,
    'impacto': impacto,
    'prob_residual': probResidual,
    'imp_residual': impResidual,
  };
}
