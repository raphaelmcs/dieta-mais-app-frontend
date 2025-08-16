import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'api/firebase_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();

  Animate.restartOnHotReload = true; // Opcional, mas ótimo para desenvolvimento
  runApp(
    // 1. O Provider agora "envolve" o nosso aplicativo
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. O MyApp agora consegue encontrar o Provider, pois está "dentro" dele
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Dieta+ App',
      // O tema agora é dinâmico, vindo do Provider
      theme: themeProvider.currentTheme.themeData,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      home: const SplashScreen(),
    );
  }
}
