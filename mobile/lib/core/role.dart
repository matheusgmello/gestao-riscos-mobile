/// Três níveis de acesso do backend, checados nas views:
/// - [admin]      = `is_superuser` (cadastro de gestores, unidades, inativos)
/// - [gestorAdm]  = `cargo == 'gestor_adm'` (gerencia membros de equipe)
/// - [gestor]     = `cargo == 'gestor'` (CRUD de riscos só nos próprios setores)
enum Role {
  gestor,
  gestorAdm,
  admin;

  static Role from({required String? cargo, required bool isSuperuser}) {
    if (isSuperuser) return Role.admin;
    if (cargo == 'gestor_adm') return Role.gestorAdm;
    return Role.gestor;
  }

  bool get podeGerenciarEquipe => this == Role.gestorAdm || this == Role.admin;
  bool get ehAdmin => this == Role.admin;
}

/// Espelha a permissão `PertenceAoSetorDoRisco`: escrita num risco só é
/// permitida se o setor do risco estiver entre os setores do usuário.
/// O backend continua sendo a fonte de verdade — isto só controla a UI.
bool podeEscreverNoSetor(int setorId, List<int> setoresDoUsuario) {
  return setoresDoUsuario.contains(setorId);
}
