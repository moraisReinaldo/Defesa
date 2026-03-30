import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Solicitar permissão
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurar notificações locais para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    // Criar canal de alta importância para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Este canal é usado para notificações importantes.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Ouvir mensagens em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
            ),
          ),
        );
      }
    });
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      if (kDebugMode) print("Erro ao obter token FCM: $e");
      return null;
    }
  }
}
