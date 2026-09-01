class FormValidators {
  static String? obrigatorio(String? v, [String campo = 'Campo']) {
    if (v == null || v.trim().isEmpty) return '$campo é obrigatório.';
    return null;
  }

  static String? senha(String? v) {
    if (v == null || v.isEmpty) return 'Senha é obrigatória.';
    if (v.length < 8) return 'A senha deve ter pelo menos 8 caracteres.';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(v.trim()) ? null : 'E-mail inválido.';
  }
}
