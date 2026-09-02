import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/role.dart';
import '../../data/services/token_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  List<_Tab> _tabs = _tabsPara(Role.gestor);

  @override
  void initState() {
    super.initState();
    _carregarPapel();
  }

  Future<void> _carregarPapel() async {
    final role = (await TokenService().getUsuario())?.role ?? Role.gestor;
    if (!mounted) return;
    setState(() => _tabs = _tabsPara(role));
  }

  static List<_Tab> _tabsPara(Role role) {
    return [
      const _Tab(
        '/riscos',
        Icons.warning_amber_outlined,
        Icons.warning_amber,
        'Riscos',
      ),
      const _Tab(
        '/dashboard',
        Icons.insights_outlined,
        Icons.insights,
        'Dashboard',
      ),
      if (role.podeGerenciarEquipe && !role.ehAdmin)
        const _Tab('/equipe', Icons.groups_outlined, Icons.groups, 'Equipe'),
      if (role.ehAdmin)
        const _Tab(
          '/admin',
          Icons.admin_panel_settings_outlined,
          Icons.admin_panel_settings,
          'Admin',
        ),
      const _Tab('/perfil', Icons.person_outline, Icons.person, 'Perfil'),
    ];
  }

  int _indexAtual(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexWhere((t) => loc.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexAtual(context);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.activeIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.path, this.icon, this.activeIcon, this.label);
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
