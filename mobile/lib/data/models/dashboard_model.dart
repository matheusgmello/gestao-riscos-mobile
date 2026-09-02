import 'risco_model.dart';

class RiscosPorNivel {
  const RiscosPorNivel({
    required this.extremo,
    required this.alto,
    required this.moderado,
    required this.baixo,
  });

  final int extremo;
  final int alto;
  final int moderado;
  final int baixo;

  int get total => extremo + alto + moderado + baixo;

  factory RiscosPorNivel.fromJson(Map<String, dynamic> j) => RiscosPorNivel(
    extremo: (j['extremo'] as num?)?.toInt() ?? 0,
    alto: (j['alto'] as num?)?.toInt() ?? 0,
    moderado: (j['moderado'] as num?)?.toInt() ?? 0,
    baixo: (j['baixo'] as num?)?.toInt() ?? 0,
  );
}

class StatusTratamentos {
  const StatusTratamentos({
    required this.emAndamento,
    required this.concluidas,
    required this.atrasadas,
    required this.naoIniciadas,
  });

  final int emAndamento;
  final int concluidas;
  final int atrasadas;
  final int naoIniciadas;

  factory StatusTratamentos.fromJson(Map<String, dynamic> j) =>
      StatusTratamentos(
        emAndamento: (j['em_andamento'] as num?)?.toInt() ?? 0,
        concluidas: (j['concluidas'] as num?)?.toInt() ?? 0,
        atrasadas: (j['atrasadas'] as num?)?.toInt() ?? 0,
        naoIniciadas: (j['nao_iniciadas'] as num?)?.toInt() ?? 0,
      );
}

class CategoriaContagem {
  const CategoriaContagem(this.nome, this.quantidade);
  final String nome;
  final int quantidade;

  factory CategoriaContagem.fromJson(Map<String, dynamic> j) =>
      CategoriaContagem(
        j['nome'] as String? ?? '',
        (j['quantidade'] as num?)?.toInt() ?? 0,
      );
}

class UnidadeExposicao {
  const UnidadeExposicao({
    required this.id,
    required this.nome,
    required this.pontos,
    required this.quantidadeRiscos,
    required this.criticos,
  });

  final int id;
  final String nome;
  final int pontos;
  final int quantidadeRiscos;
  final int criticos;

  factory UnidadeExposicao.fromJson(Map<String, dynamic> j) => UnidadeExposicao(
    id: (j['id'] as num?)?.toInt() ?? 0,
    nome: j['nome'] as String? ?? '',
    pontos: (j['pontos'] as num?)?.toInt() ?? 0,
    quantidadeRiscos: (j['quantidade_riscos'] as num?)?.toInt() ?? 0,
    criticos: (j['criticos'] as num?)?.toInt() ?? 0,
  );
}

class CelulaMatriz {
  const CelulaMatriz({
    required this.probabilidade,
    required this.impacto,
    required this.quantidade,
    required this.score,
  });

  final int probabilidade;
  final int impacto;
  final int quantidade;
  final int score;

  factory CelulaMatriz.fromJson(Map<String, dynamic> j) => CelulaMatriz(
    probabilidade: (j['probabilidade'] as num).toInt(),
    impacto: (j['impacto'] as num).toInt(),
    quantidade: (j['quantidade'] as num?)?.toInt() ?? 0,
    score: (j['score'] as num?)?.toInt() ?? 0,
  );
}

class RiscoPrioritario {
  const RiscoPrioritario({
    required this.risco,
    this.responsavel,
    this.tipoResposta,
    this.statusTratamento,
  });

  final Risco risco;
  final String? responsavel;
  final String? tipoResposta;
  final String? statusTratamento;

  factory RiscoPrioritario.fromJson(Map<String, dynamic> j) => RiscoPrioritario(
    risco: Risco.fromJson(j),
    responsavel: j['responsavel'] as String?,
    tipoResposta: j['tipo_resposta'] as String?,
    statusTratamento: j['status_tratamento'] as String?,
  );
}

class Dashboard {
  const Dashboard({
    required this.totalPlanos,
    required this.riscosCriticos,
    required this.riscosPorNivel,
    required this.statusTratamentos,
    required this.acoesAtrasadas,
    required this.riscosSemAcao,
    required this.riscosMonitorados,
    required this.coberturaMonitoramento,
    required this.objetivosCobertos,
    required this.desafiosCobertos,
    required this.taxaMitigacao,
    required this.riscosMelhorados,
    required this.distribuicaoCategorias,
    required this.unidadesMaiorExposicao,
    required this.matrizResidual,
    required this.riscosPrioritarios,
  });

  final int totalPlanos;
  final int riscosCriticos;
  final RiscosPorNivel riscosPorNivel;
  final StatusTratamentos statusTratamentos;
  final int acoesAtrasadas;
  final int riscosSemAcao;
  final int riscosMonitorados;
  final double coberturaMonitoramento;
  final int objetivosCobertos;
  final int desafiosCobertos;
  final double taxaMitigacao;
  final int riscosMelhorados;
  final List<CategoriaContagem> distribuicaoCategorias;
  final List<UnidadeExposicao> unidadesMaiorExposicao;
  final List<CelulaMatriz> matrizResidual;
  final List<RiscoPrioritario> riscosPrioritarios;

  static List<T> _lista<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) => (raw as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList();

  factory Dashboard.fromJson(Map<String, dynamic> j) => Dashboard(
    totalPlanos: (j['total_planos'] as num?)?.toInt() ?? 0,
    riscosCriticos: (j['riscos_criticos'] as num?)?.toInt() ?? 0,
    riscosPorNivel: RiscosPorNivel.fromJson(
      j['riscos_por_nivel'] as Map<String, dynamic>? ?? const {},
    ),
    statusTratamentos: StatusTratamentos.fromJson(
      j['status_tratamentos'] as Map<String, dynamic>? ?? const {},
    ),
    acoesAtrasadas: (j['acoes_atrasadas'] as num?)?.toInt() ?? 0,
    riscosSemAcao: (j['riscos_sem_acao'] as num?)?.toInt() ?? 0,
    riscosMonitorados: (j['riscos_monitorados'] as num?)?.toInt() ?? 0,
    coberturaMonitoramento:
        (j['cobertura_monitoramento'] as num?)?.toDouble() ?? 0,
    objetivosCobertos: (j['objetivos_cobertos'] as num?)?.toInt() ?? 0,
    desafiosCobertos: (j['desafios_cobertos'] as num?)?.toInt() ?? 0,
    taxaMitigacao: (j['taxa_mitigacao'] as num?)?.toDouble() ?? 0,
    riscosMelhorados: (j['riscos_melhorados'] as num?)?.toInt() ?? 0,
    distribuicaoCategorias: _lista(
      j['distribuicao_categorias'],
      CategoriaContagem.fromJson,
    ),
    unidadesMaiorExposicao: _lista(
      j['unidades_maior_exposicao'],
      UnidadeExposicao.fromJson,
    ),
    matrizResidual: _lista(j['matriz_residual'], CelulaMatriz.fromJson),
    riscosPrioritarios: _lista(
      j['riscos_prioritarios'],
      RiscoPrioritario.fromJson,
    ),
  );
}
