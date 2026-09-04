import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'providers/ocorrencia_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/ponto_interesse_provider.dart';
import 'providers/clima_provider.dart';
import 'providers/alerta_provider.dart';
import 'providers/cidade_provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';
import 'services/ad_service.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Orientação apenas vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Edge-to-edge: habilitar modo de exibição de ponta a ponta (Android 15+)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  final storageService = StorageService();
  await storageService.init();

  // Inicializar Hive para preferências do usuário [CR2 - Recursos Nativos]
  final hiveService = HiveService();
  await hiveService.init();

  final apiService = ApiService(storageService);

  // Inicializar AdMob
  final adService = AdService();
  adService.initialize();

  // Inicializar OneSignal
  if (!kIsWeb) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("6537856b-c264-42af-b2a9-583652a175d2");
    OneSignal.Notifications.requestPermission(true);
  }

  final notificationService = NotificationService();
  try {
    await notificationService.init();
  } catch (e) {
    if (kDebugMode) print('⚠️ Notificações não inicializadas: $e');
  }

  runApp(MyApp(
    storageService: storageService,
    apiService: apiService,
    notificationService: notificationService,
    hiveService: hiveService,
    adService: adService,
  ));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;
  final NotificationService notificationService;
  final HiveService hiveService;
  final AdService adService;

  const MyApp({
    super.key,
    required this.storageService,
    required this.apiService,
    required this.notificationService,
    required this.hiveService,
    required this.adService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UsuarioProvider(storageService, apiService, hiveService),
        ),
        ChangeNotifierProvider(
          create: (_) => OcorrenciaProvider(storageService, apiService, hiveService),
        ),
        ChangeNotifierProvider(
          create: (_) => PontoInteresseProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ClimaProvider(hiveService),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertaProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CidadeProvider(apiService),
        ),
        Provider.value(value: notificationService),
        Provider.value(value: hiveService),
        ChangeNotifierProvider.value(value: adService),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'Defesa em Foco',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor:  const Color(0xFF003366),
                primary:  const Color(0xFF003366),
                secondary:  const Color(0xFFFF6600),
              ),
              appBarTheme:  const AppBarTheme(
                backgroundColor: Color(0xFF003366),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            navigatorObservers: [SyncNavigatorObserver(context)],
            home:  const LoadingScreen(),
          );
        }
      ),
    );
  }
}

// Observador customizado para capturar mudanças de tela
class SyncNavigatorObserver extends NavigatorObserver {
  final BuildContext context;
  SyncNavigatorObserver(this.context);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (context.mounted) {
      context.read<UsuarioProvider>().sincronizarGlobal();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (context.mounted) {
      context.read<UsuarioProvider>().sincronizarGlobal();
    }
  }
}
