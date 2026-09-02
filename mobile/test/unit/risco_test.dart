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
}
