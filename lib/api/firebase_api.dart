import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Esta função lida com mensagens quando o app está em segundo plano ou fechado.
// Ela precisa ficar fora de uma classe.
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Inicializa tudo relacionado às notificações
  Future<void> initNotifications() async {
    // Pede permissão e pega o token (já fazemos no login, mas é bom ter aqui)
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Configuração inicial para as notificações locais
    await _initLocalNotifications();

    // Configura os listeners para quando as notificações chegam
    _initPushNotifications();
  }

  // Lida com a notificação e a exibe na tela
  Future<void> _handleMessage(RemoteMessage? message) async {
    if (message == null || message.notification == null) return;

    // Usa o plugin de notificações locais para mostrar a notificação
    _localNotifications.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      _notificationDetails(),
      payload: message.data.toString(),
    );
  }

  // Configuração inicial do plugin de notificações locais
  Future<void> _initLocalNotifications() async {
    // O nome do ícone DEVE ser o mesmo que você colocou nas pastas mipmap
    const android = AndroidInitializationSettings('@mipmap/ic_notification');
    const settings = InitializationSettings(android: android);
    await _localNotifications.initialize(settings);
  }

  // Detalhes de como a notificação deve se parecer no Android
  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      'high_importance_channel', // id do canal
      'High Importance Notifications', // nome do canal
      channelDescription: 'Este canal é usado para notificações importantes.',
      importance: Importance.max,
      priority: Priority.high,
    );
    return const NotificationDetails(android: android);
  }

  // Ativa os "ouvintes" de notificação
  void _initPushNotifications() {
    // Lida com a notificação se o app for aberto a partir dela (estava fechado)
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);

    // Lida com a notificação se o app for aberto a partir dela (estava em segundo plano)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Lida com notificações em segundo plano (quando o app está minimizado)
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Lida com notificações que chegam enquanto o app está ABERTO (em primeiro plano)
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }
}
