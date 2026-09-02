import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/role.dart';
import '../data/services/token_service.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/equipe/equipe_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/perfil/perfil_screen.dart';
import '../features/riscos/riscos_screen.dart';
import '../features/shell/app_shell.dart';

GoRouter buildRouter(TokenService tokenService) {
  return GoRouter(
    initialLocation: '/riscos',
    redirect: (context, state) async {
      final logado = await tokenService.hasToken();
      final indoParaLogin = state.matchedLocation == '/login';

      if (!logado) return indoParaLogin ? null : '/login';
      if (indoParaLogin) return '/riscos';

      // Gating por papel para áreas restritas.
      final role = (await tokenService.getUsuario())?.role ?? Role.gestor;
      final loc = state.matchedLocation;
      if (loc.startsWith('/admin') && !role.ehAdmin) return '/riscos';
      if (loc.startsWith('/equipe') && !role.podeGerenciarEquipe) {
        return '/riscos';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/riscos',
            builder: (context, state) => const RiscosScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/equipe',
            builder: (context, state) => const EquipeScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Rota não encontrada: ${state.uri}')),
    ),
  );
}
