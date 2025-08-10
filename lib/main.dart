import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importa o Firebase Core
import 'api/firebase_api.dart';
import 'firebase_options.dart'; // Importa as configurações geradas
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

// A função main agora é assíncrona para poder usar 'await'
Future<void> main() async {
  // 1. Garante que o Flutter está pronto para chamadas nativas antes de rodar o app
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa o Firebase e espera (await) a conclusão
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // INICIALIZA AS NOTIFICAÇÕES AQUI
  await FirebaseApi().initNotifications();

  // 3. Só depois de o Firebase estar pronto, roda o aplicativo
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dieta+ App',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
