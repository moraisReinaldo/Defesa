import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Serviço de notificações: local (flutter_local_notifications) + push remoto (OneSignal).
/// [CR3 - Recursos Nativos]: Uso de push notification na implementação do aplicativo.
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'defesa_civil_channel';
  static const _channelName = 'Defesa Civil';
  static const _channelDesc = 'Notificações do app Defesa Civil em Foco';

  // ID do app no OneSignal (configurado em main.dart)
  static const _oneSignalAppId = '6537856b-c264-42af-b2a9-583652a175d2';

  Future<void> init() async {
    // ── 1. Notificações LOCAIS ──────────────────────────────────────────────
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

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

    // ── 2. Push REMOTO via OneSignal ───────────────────────────────────────
    _configurarOneSignal();

    if (kDebugMode) print('✅ NotificationService inicializado (local + OneSignal)');
  }

  /// Configura handlers do OneSignal para push remoto.
  void _configurarOneSignal() {
    // Exibir notificação local quando uma push chegar em foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      if (kDebugMode) {
        print('📬 [OneSignal] Push recebida em foreground: ${event.notification.title}');
      }
      // Exibir como notificação local também
      mostrarNotificacaoLocal(
        titulo: event.notification.title ?? 'Defesa Civil em Foco',
        corpo: event.notification.body ?? '',
        id: event.notification.hashCode,
      );
      // Não exibir o banner nativo do OneSignal (evita duplicata)
      event.preventDefault();
    });

    // Handler de clique em notificação push
    OneSignal.Notifications.addClickListener((event) {
      if (kDebugMode) {
        print('👆 [OneSignal] Notificação clicada: ${event.notification.title}');
      }
    });

    if (kDebugMode) print('📡 [OneSignal] Handlers configurados (App ID: $_oneSignalAppId)');
  }

  /// Retorna o token/playerID do OneSignal para vincular ao usuário no backend.
  /// [CR3 - Recursos Nativos]: Token real de push notification.
  Future<String?> getToken() async {
    try {
      final deviceState = OneSignal.User.pushSubscription;
      final token = deviceState.id; // OneSignal Player ID / Subscription ID
      if (kDebugMode) print('📡 [OneSignal] Push token: $token');
      return token;
    } catch (e) {
      if (kDebugMode) print('⚠️ [OneSignal] Erro ao obter token: $e');
      return null;
    }
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
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      id: id,
      title: titulo,
      body: corpo,
      notificationDetails: details,
    );
  }

  /// Envia tag ao OneSignal para segmentação de notificações por cidade.
  Future<void> definirTagCidade(String cidade) async {
    try {
      OneSignal.User.addTagWithKey('cidade', cidade);
      if (kDebugMode) print('🏷️ [OneSignal] Tag cidade=$cidade definida');
    } catch (e) {
      if (kDebugMode) print('⚠️ [OneSignal] Erro ao definir tag cidade: $e');
    }
  }

  /// Define o ID do usuário no OneSignal para envio direcionado.
  Future<void> vincularUsuario(String usuarioId) async {
    try {
      OneSignal.login(usuarioId);
      if (kDebugMode) print('👤 [OneSignal] Usuário vinculado: $usuarioId');
    } catch (e) {
      if (kDebugMode) print('⚠️ [OneSignal] Erro ao vincular usuário: $e');
    }
  }

  /// Remove o vínculo do usuário ao fazer logout.
  Future<void> desvincularUsuario() async {
    try {
      OneSignal.logout();
      if (kDebugMode) print('👤 [OneSignal] Usuário desvinculado');
    } catch (e) {
      if (kDebugMode) print('⚠️ [OneSignal] Erro ao desvincular usuário: $e');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) print('👆 Notificação local clicada: ${response.payload}');
  }
}
