import 'package:flutter/material.dart';

import '../../widgets/em_construcao.dart';

class RiscosScreen extends StatelessWidget {
  const RiscosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmConstrucao('Riscos', 'Lista e cadastro de riscos — Fase 1.'),
    );
  }
}
