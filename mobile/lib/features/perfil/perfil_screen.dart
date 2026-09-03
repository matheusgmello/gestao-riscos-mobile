import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error.dart';
import '../../core/preferencias.dart';
import '../../data/models/usuario_model.dart';
import '../../widgets/estado.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/token_service.dart';
import '../../data/services/usuario_service.dart';
import 'editar_perfil_screen.dart';

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

  Future<void> _editar(UsuarioModel u) async {
    final mudou = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => EditarPerfilScreen(usuario: u)),
    );
    if (mudou == true) {
      setState(() => _future = _carregar());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          FutureBuilder<UsuarioModel>(
            future: _future,
            builder: (context, snap) => snap.hasData
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar perfil',
                    onPressed: () => _editar(snap.data!),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: FutureBuilder<UsuarioModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return EstadoErro(
              erro: snap.error!,
              onTentar: () => setState(() => _future = _carregar()),
            );
          }
          final u = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _linha('Nome', u.nome),
              _linha('SIAPE', u.siape),
              _linha('E-mail', u.email ?? '—'),
              _linha(
                'Cargo',
                u.isSuperuser ? 'Administrador do sistema' : u.cargo,
              ),
              const SizedBox(height: 8),
              Text('Setores', style: Theme.of(context).textTheme.titleMedium),
              if (u.setores.isEmpty) const Text('Nenhum setor vinculado.'),
              for (final s in u.setores) Text('• ${s.rotulo}'),
              const SizedBox(height: 20),
              Text('Aparência', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const _SeletorTema(),
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

class _SeletorTema extends StatelessWidget {
  const _SeletorTema();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Preferencias.tema,
      builder: (context, modo, _) => SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.system,
            label: Text('Sistema'),
            icon: Icon(Icons.brightness_auto),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            label: Text('Claro'),
            icon: Icon(Icons.light_mode),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: Text('Escuro'),
            icon: Icon(Icons.dark_mode),
          ),
        ],
        selected: {modo},
        showSelectedIcon: false,
        onSelectionChanged: (s) => Preferencias.definirTema(s.first),
      ),
    );
  }
}
