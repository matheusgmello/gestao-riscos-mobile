import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/core/nivel_risco.dart';
import 'package:gestao_risco_mobile/data/models/risco_model.dart';
import 'package:gestao_risco_mobile/data/services/risco_service.dart';

void main() {
  group('FaixaNivel', () {
    test('faixas seguem os cortes do backend', () {
      expect(FaixaNivel.of(3), FaixaNivel.baixo);
      expect(FaixaNivel.of(4), FaixaNivel.moderado);
      expect(FaixaNivel.of(12), FaixaNivel.alto);
      expect(FaixaNivel.of(20), FaixaNivel.extremo);
      expect(FaixaNivel.of(25), FaixaNivel.extremo);
    });
  });

  group('FiltroRisco.toQuery', () {
    test('inclui só o que está setado + page e ordenacao', () {
      final q = const FiltroRisco().toQuery(2);
      expect(q, {'page': 2, 'ordenacao': 'desc'});
    });

    test('monta filtros completos', () {
      final q = const FiltroRisco(
        busca: 'fogo',
        setorId: 5,
        categoria: 'Operacional',
        dataInicio: '2026-01-01',
        dataFim: '2026-12-31',
        ordenacao: OrdenacaoRisco.nivelMaior,
        incluirInativos: true,
      ).toQuery(1);
      expect(q['search'], 'fogo');
      expect(q['setor'], 5);
      expect(q['categoria'], 'Operacional');
      expect(q['data_inicio'], '2026-01-01');
      expect(q['data_fim'], '2026-12-31');
      expect(q['ordenacao'], 'nivel_desc');
      expect(q['incluir_inativos'], 'true');
    });

    test('copyWith limpa campos com flags', () {
      const base = FiltroRisco(setorId: 3, categoria: 'Imagem');
      final limpo = base.copyWith(limparSetor: true, limparCategoria: true);
      expect(limpo.setorId, isNull);
      expect(limpo.categoria, isNull);
    });
  });

  group('Risco.toPayload', () {
    test('nunca envia nivel_risco / nivel_residual', () {
      final r = Risco.fromJson({
        'uuid': 'abc',
        'setor': 1,
        'objetivo': 2,
        'macroprocesso': 3,
        'categoria': 'Operacional',
        'evento': 'e',
        'causa': 'c',
        'consequencia': 'q',
        'controles_atuais': 'ca',
        'eficacia_controle': 'Fraco',
        'probabilidade': 4,
        'impacto': 5,
        'nivel_risco': 20,
        'prob_residual': 2,
        'imp_residual': 3,
        'nivel_residual': 6,
      });
      final p = r.toPayload();
      expect(p.containsKey('nivel_risco'), isFalse);
      expect(p.containsKey('nivel_residual'), isFalse);
      expect(p['probabilidade'], 4);
      expect(r.faixaResidual, FaixaNivel.moderado);
    });
  });

  group('FiltroRisco.aplicar', () {
    final riscos = [
      _risco(uuid: 'a', setor: 1, categoria: 'Operacional', nivelResidual: 12),
      _risco(uuid: 'b', setor: 2, categoria: 'Imagem', nivelResidual: 4),
      _risco(uuid: 'c', setor: 1, categoria: 'Operacional', ativo: false),
    ];

    test('esconde inativos por padrão', () {
      final out = const FiltroRisco().aplicar(riscos);
      expect(out.map((r) => r.uuid), unorderedEquals(['a', 'b']));
    });

    test('filtra por setor e categoria', () {
      final out = const FiltroRisco(
        setorId: 1,
        categoria: 'Operacional',
      ).aplicar(riscos);
      expect(out.single.uuid, 'a');
    });

    test('ordena por nível residual', () {
      final out = const FiltroRisco(ordenacao: OrdenacaoRisco.nivelMaior)
          .aplicar(riscos);
      expect(out.first.uuid, 'a');
    });

    test('busca textual no evento', () {
      final lista = [_risco(uuid: 'x', evento: 'incêndio no laboratório')];
      expect(const FiltroRisco(busca: 'incêndio').aplicar(lista), hasLength(1));
      expect(const FiltroRisco(busca: 'inundação').aplicar(lista), isEmpty);
    });
  });
}

// --- FiltroRisco.aplicar (modo offline) ---

Risco _risco({
  String uuid = 'x',
  int setor = 1,
  String categoria = 'Operacional',
  String evento = 'evento',
  int nivelResidual = 6,
  bool ativo = true,
  String? atualizadoEm,
  String? periodoFim,
}) => Risco(
  uuid: uuid,
  setorId: setor,
  objetivoId: 1,
  macroprocessoId: 1,
  categoria: categoria,
  evento: evento,
  causa: 'c',
  consequencia: 'q',
  controlesAtuais: 'ca',
  eficaciaControle: 'Fraco',
  probabilidade: 2,
  impacto: 3,
  nivelRisco: 6,
  probResidual: 2,
  impResidual: 3,
  nivelResidual: nivelResidual,
  ativo: ativo,
  atualizadoEm: atualizadoEm,
  periodoFim: periodoFim,
);
