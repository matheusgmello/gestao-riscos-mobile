import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/core/role.dart';
import 'package:gestao_risco_mobile/features/shell/app_shell.dart';

void main() {
  List<String> rotulos(Role r) => tabsPara(r).map((t) => t.label).toList();

  test('gestor comum: Riscos / Dashboard / Perfil', () {
    expect(rotulos(Role.gestor), ['Riscos', 'Dashboard', 'Perfil']);
  });

  test('gestor_adm: ganha a aba Equipe', () {
    expect(rotulos(Role.gestorAdm), ['Riscos', 'Dashboard', 'Equipe', 'Perfil']);
  });

  test('admin: ganha Equipe e Admin', () {
    expect(
      rotulos(Role.admin),
      ['Riscos', 'Dashboard', 'Equipe', 'Admin', 'Perfil'],
    );
  });

  test('gestor comum não vê Equipe nem Admin', () {
    final r = rotulos(Role.gestor);
    expect(r, isNot(contains('Equipe')));
    expect(r, isNot(contains('Admin')));
  });
}
