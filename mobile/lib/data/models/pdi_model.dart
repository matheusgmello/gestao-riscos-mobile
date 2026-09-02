// Estrutura estratégica do PDI: DesafioPDI -> ObjetivoPDI, + Macroprocesso.
// Endpoints sem paginação (/api/riscos/desafios|objetivos|macroprocessos/).

class DesafioPdi {
  const DesafioPdi({required this.id, required this.numero, required this.descricao});

  final int id;
  final int numero;
  final String descricao;

  String get rotulo => '$numero. $descricao';

  factory DesafioPdi.fromJson(Map<String, dynamic> j) => DesafioPdi(
        id: (j['id'] as num).toInt(),
        numero: (j['numero'] as num?)?.toInt() ?? 0,
        descricao: j['descricao'] as String? ?? '',
      );
}

class ObjetivoPdi {
  const ObjetivoPdi({
    required this.id,
    required this.codigo,
    required this.descricao,
    required this.desafioId,
    this.desafio,
  });

  final int id;
  final String codigo;
  final String descricao;
  final int desafioId;
  final DesafioPdi? desafio;

  String get rotulo => '$codigo — $descricao';

  factory ObjetivoPdi.fromJson(Map<String, dynamic> j) {
    final det = j['desafio_detalhes'];
    return ObjetivoPdi(
      id: (j['id'] as num).toInt(),
      codigo: j['codigo'] as String? ?? '',
      descricao: j['descricao'] as String? ?? '',
      desafioId: (j['desafio'] as num?)?.toInt() ?? 0,
      desafio: det is Map<String, dynamic> ? DesafioPdi.fromJson(det) : null,
    );
  }
}

class Macroprocesso {
  const Macroprocesso({required this.id, required this.nome});

  final int id;
  final String nome;

  factory Macroprocesso.fromJson(Map<String, dynamic> j) => Macroprocesso(
        id: (j['id'] as num).toInt(),
        nome: j['nome'] as String? ?? '',
      );
}
