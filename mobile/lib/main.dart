import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/app_theme.dart';
import 'core/preferencias.dart';
import 'data/services/token_service.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Preferencias.carregar();
  runApp(const GestaoRiscoApp());
}

class GestaoRiscoApp extends StatelessWidget {
  const GestaoRiscoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(TokenService());
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Preferencias.tema,
      builder: (context, modo, _) => MaterialApp.router(
        title: 'Gestão de Risco UFSM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: modo,
        routerConfig: router,
      ),
    );
  }
}
