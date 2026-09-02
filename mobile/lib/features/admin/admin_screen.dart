import 'package:flutter/material.dart';

import 'gestores_screen.dart';
import 'pdi_screen.dart';
import 'unidades_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itens = [
      (
        Icons.badge_outlined,
        'Gestores',
        'Cadastrar, editar e desativar gestores',
        const GestoresScreen(),
      ),
      (
        Icons.apartment_outlined,
        'Unidades',
        'Unidades organizacionais e seus membros',
        const UnidadesScreen(),
      ),
      (
        Icons.account_tree_outlined,
        'Estrutura PDI',
        'Desafios, objetivos e macroprocessos',
        const PdiScreen(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Administração')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final (icone, titulo, sub, tela) in itens)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(icone),
                title: Text(titulo),
                subtitle: Text(sub),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).push(MaterialPageRoute(builder: (_) => tela)),
              ),
            ),
        ],
      ),
    );
  }
}
