import 'package:flutter/material.dart';

import '../../widgets/em_construcao.dart';

class EquipeScreen extends StatelessWidget {
  const EquipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmConstrucao('Equipe', 'Gestão de membros por setor — Fase 4.'),
    );
  }
}
