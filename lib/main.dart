import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

// registre o handler de mensagens em background (top-level function)
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  final firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();
  await firebaseApi.scheduleRemindersFromPreferences();

  Animate.restartOnHotReload = true;
  runApp(
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Dieta+ App',
      theme: themeProvider.currentTheme.themeData,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      // ***** ALTERAÇÃO AQUI *****
      home: const SplashScreen(), // Adicionado 'const'
    );
  }
}
