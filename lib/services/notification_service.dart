import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Serviço de notificações locais.
/// O Firebase Cloud Messaging foi removido — push remoto é um stub por enquanto.
/// Notificações locais (via flutter_local_notifications) continuam funcionando.
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'defesa_civil_channel';
  static const _channelName = 'Defesa Civil';
  static const _channelDesc = 'Notificações do app Defesa Civil em Foco';

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    // Criar canal de alta importância para Android 8+
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    if (kDebugMode) print('✅ NotificationService inicializado (sem Firebase)');
  }

  /// Exibe uma notificação local imediatamente.
  Future<void> mostrarNotificacaoLocal({
    required String titulo,
    required String corpo,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(id, titulo, corpo, details);
  }

  /// Token para push remoto — stub enquanto FCM não for reintegrado.
  /// Para reativar: integre com OneSignal ou FCM HTTP v1 API.
  Future<String?> getToken() async {
    if (kDebugMode) {
      print('⚠️ [NotificationService] Push remoto desativado. getToken() retorna null.');
    }
    return null;
  }
}
