import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/core/role.dart';

void main() {
  test('is_superuser vence o cargo', () {
    expect(Role.from(cargo: 'gestor', isSuperuser: true), Role.admin);
  });

  test('cargo gestor_adm', () {
    final r = Role.from(cargo: 'gestor_adm', isSuperuser: false);
    expect(r, Role.gestorAdm);
    expect(r.podeGerenciarEquipe, isTrue);
    expect(r.ehAdmin, isFalse);
  });

  test('gestor padrão', () {
    final r = Role.from(cargo: 'gestor', isSuperuser: false);
    expect(r, Role.gestor);
    expect(r.podeGerenciarEquipe, isFalse);
  });

  test('podeEscreverNoSetor respeita a lista de setores', () {
    expect(podeEscreverNoSetor(3, [1, 3, 5]), isTrue);
    expect(podeEscreverNoSetor(9, [1, 3, 5]), isFalse);
  });
}
