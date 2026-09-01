import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/app_theme.dart';
import 'data/services/token_service.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const GestaoRiscoApp());
}

class GestaoRiscoApp extends StatelessWidget {
  const GestaoRiscoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(TokenService());
    return MaterialApp.router(
      title: 'Gestão de Risco UFSM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
