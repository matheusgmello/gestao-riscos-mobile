import 'package:flutter/material.dart';

import '../../widgets/em_construcao.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmConstrucao(
        'Admin',
        'Gestores, unidades e estrutura PDI — Fase 4.',
      ),
    );
  }
}
