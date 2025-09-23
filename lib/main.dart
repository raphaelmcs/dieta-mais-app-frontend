import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Só serão usados fora do Web
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'api/firebase_api.dart'; // define handleBackgroundMessage e FirebaseApi

Future<void> _initFirebaseForNative() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Notificações/FCM apenas em plataformas suportadas (Android/iOS/macOS).
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  final firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();
  await firebaseApi.scheduleRemindersFromPreferences();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // Inicializa Firebase só em plataformas nativas
    try {
      await _initFirebaseForNative();
    } catch (e) {
      // Não quebrar o boot caso algo do FCM falhe
      debugPrint('Falha ao inicializar Firebase (nativo): $e');
    }
  } else {
    // No Web: não inicializa Firebase para evitar interop com JS sem SW/config
    debugPrint('Executando no Web: Firebase desativado.');
  }

  Animate.restartOnHotReload = true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // outros providers globais aqui…
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dieta+ App',
      theme: themeProvider.currentTheme.themeData,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      home: const SplashScreen(),
    );
  }
}
