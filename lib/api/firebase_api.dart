// lib/api/firebase_api.dart
// ---------------------------------------------------------------------------
// Push (FCM) + Notificações Locais (agendamentos diários/por intervalo)
// Compatível com flutter_local_notifications ^19.x (sem Exact Alarms)
// - Usa agendamentos INEXACT (dispensa SCHEDULE_EXACT_ALARM)
// - Respeita toggles do usuário via FlutterSecureStorage:
//     wants_meal_reminders: '1'/'0'   (controla refeições + lanches)
//     wants_hydration_reminders: '1'/'0'
// - Lê horários dos slots (formato "HH:mm"):
//     breakfast_time, lunch_time, dinner_time,
//     snack_morning_time, snack_afternoon_time, snack_night_time
// - Lê intervalo de hidratação: hydration_interval (minutos)
// ---------------------------------------------------------------------------

import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('[BG] Title: ${message.notification?.title}');
  debugPrint('[BG] Body : ${message.notification?.body}');
  debugPrint('[BG] Data : ${message.data}');
}

class FirebaseApi {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _listenersBound = false;

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDescription =
      'Este canal é usado para notificações importantes.';

  // Mapeia as chaves (storage) para títulos amigáveis
  static const Map<String, String> slotTitles = {
    'breakfast_time': 'Café da manhã',
    'lunch_time': 'Almoço',
    'dinner_time': 'Jantar',
    'snack_morning_time': 'Lanche da manhã',
    'snack_afternoon_time': 'Lanche da tarde',
    'snack_night_time': 'Lanche da noite',
  };

  Future<void> initNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(
        tz.getLocation('America/Sao_Paulo')); // ajuste se preciso

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_notification');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    if (Platform.isAndroid) {
      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      try {
        final enabled = await android?.areNotificationsEnabled() ?? true;
        if (!enabled) await android?.requestNotificationsPermission();
      } catch (_) {}
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );
      await android?.createNotificationChannel(channel);
    } else {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
    }

    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    _bindPushListenersOnce();
  }

  void _bindPushListenersOnce() {
    if (_listenersBound) return;
    _listenersBound = true;

    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  Future<void> _handleMessage(RemoteMessage? message) async {
    if (message == null || message.notification == null) return;

    await _local.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      _notificationDetails(),
      payload: message.data.toString(),
    );
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    return const NotificationDetails(android: android);
  }

  /// Lê preferências e (re)agenda:
  /// - refeições + lanches se wants_meal_reminders == true
  /// - hidratação se wants_hydration_reminders == true
  Future<void> scheduleRemindersFromPreferences() async {
    const storage = FlutterSecureStorage();

    final wantsMealsStr =
        await storage.read(key: 'wants_meal_reminders'); // '1'/'0'/null
    final wantsHydrStr =
        await storage.read(key: 'wants_hydration_reminders'); // '1'/'0'/null
    final wantsMeals = wantsMealsStr == null ? true : (wantsMealsStr == '1');
    final wantsHydr = wantsHydrStr == null ? true : (wantsHydrStr == '1');

    // Coletar horários dos slots
    final keys = <String>[
      'breakfast_time',
      'lunch_time',
      'dinner_time',
      'snack_morning_time',
      'snack_afternoon_time',
      'snack_night_time',
    ];

    final mealTimes = <TimeOfDay>[];
    if (wantsMeals) {
      for (final k in keys) {
        final v = await storage.read(key: k);
        if (v != null && _isValidHHmm(v)) {
          mealTimes.add(_parseTime(v));
        }
      }
    }

    // Hidratação
    final intervalStr = await storage.read(key: 'hydration_interval');
    final interval = int.tryParse(intervalStr ?? '');

    // limpa antes de reconfigurar
    await _local.cancelAll();

    if (mealTimes.isNotEmpty) {
      await _scheduleMealNotifications(mealTimes);
    }
    if (wantsHydr && interval != null && interval > 0) {
      await _scheduleHydration(interval);
    }
  }

  // ---------- Helpers de agendamento ----------
  Future<void> _scheduleMealNotifications(List<TimeOfDay> times) async {
    var id = 0;
    for (final t in times) {
      final scheduled = _nextInstanceOfTime(t);
      await _local.zonedSchedule(
        id++,
        'Lembrete',
        'Está na hora da sua refeição/lanche!',
        scheduled,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repete diariamente
        payload: 'meal-$id',
      );
    }
  }

  Future<void> _scheduleHydration(int intervalMinutes) async {
    var next =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: intervalMinutes));
    var id = 100;
    final end = next.add(const Duration(hours: 24));
    while (next.isBefore(end)) {
      await _local.zonedSchedule(
        id++,
        'Hora de beber água',
        'Mantenha-se hidratado!',
        next,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'hydration-$id',
      );
      next = next.add(Duration(minutes: intervalMinutes));
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ---------- Utils ----------
  bool _isValidHHmm(String s) {
    final re = RegExp(r'^\d{2}:\d{2}$');
    if (!re.hasMatch(s)) return false;
    final p = s.split(':');
    final h = int.tryParse(p[0]) ?? -1;
    final m = int.tryParse(p[1]) ?? -1;
    return h >= 0 && h < 24 && m >= 0 && m < 60;
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // ---------- Helpers públicos para a UI ----------
  static Future<void> setTimeAndReschedule({
    required String key,
    required String hhmm,
  }) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: key, value: hhmm);
    await FirebaseApi().scheduleRemindersFromPreferences();
  }

  static Future<void> setHydrationIntervalAndReschedule(int minutes) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'hydration_interval', value: '$minutes');
    await FirebaseApi().scheduleRemindersFromPreferences();
  }

  static Future<void> setLocalToggleAndReschedule({
    required String key,
    required bool value,
  }) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: key, value: value ? '1' : '0');
    await FirebaseApi().scheduleRemindersFromPreferences();
  }
}
