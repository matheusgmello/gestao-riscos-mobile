import 'package:flutter/material.dart';

import '../../widgets/em_construcao.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmConstrucao('Dashboard', 'Analytics e matriz de risco — Fase 2.'),
    );
  }
}
