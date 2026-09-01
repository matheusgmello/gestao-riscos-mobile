import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/token_service.dart';
import '../../data/services/usuario_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _service = UsuarioService(TokenService());
  late Future<UsuarioModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<UsuarioModel> _carregar() async {
    try {
      return await _service.me();
    } on ApiError {
      final cache = await TokenService().getUsuario();
      if (cache != null) return cache;
      rethrow;
    }
  }

  Future<void> _sair() async {
    await AuthService(TokenService()).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: FutureBuilder<UsuarioModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final u = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _linha('Nome', u.nome),
              _linha('SIAPE', u.siape),
              _linha('E-mail', u.email ?? '—'),
              _linha('Cargo',
                  u.isSuperuser ? 'Administrador do sistema' : u.cargo),
              const SizedBox(height: 8),
              Text('Setores', style: Theme.of(context).textTheme.titleMedium),
              if (u.setores.isEmpty) const Text('Nenhum setor vinculado.'),
              for (final s in u.setores) Text('• ${s.rotulo}'),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _sair,
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _linha(String rotulo, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rotulo, style: Theme.of(context).textTheme.labelMedium),
            Text(valor, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
}
