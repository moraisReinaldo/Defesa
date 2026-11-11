import 'providers/acessibilidade_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'constants/app_colors.dart';
import 'providers/ocorrencia_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/ponto_interesse_provider.dart';
import 'providers/clima_provider.dart';
import 'providers/alerta_provider.dart';
import 'providers/cidade_provider.dart';
import 'providers/rota_emergencia_provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';
import 'services/ad_service.dart';
import 'services/offline_map_service.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Orientação apenas vertical em mobile
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

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

  // Inicializar cache de mapas offline (FMTC)
  await OfflineMapService().init();

  final apiService = ApiService(storageService);

  // AdService criado aqui, mas a inicialização (ATT + AdMob) acontece
  // no LoadingScreen após o primeiro frame renderizar.
  final adService = AdService();

  // Inicializar OneSignal
  if (!kIsWeb) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(NotificationService.oneSignalAppId);
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
        ChangeNotifierProvider(
          create: (_) => RotaEmergenciaProvider(apiService, hiveService),
        ),
        ChangeNotifierProvider(
          create: (_) => AcessibilidadeProvider(hiveService),
        ),
        Provider.value(value: notificationService),
        Provider.value(value: hiveService),
        ChangeNotifierProvider.value(value: adService),
      ],
      child: Builder(
        builder: (context) {
          final acessibilidade = context.watch<AcessibilidadeProvider>();
          return MaterialApp(
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(acessibilidade.escalaFonte),
                ),
                child: child,
              );
            },
            title: 'Defesa em Foco',
            debugShowCheckedModeBanner: false,
            theme: acessibilidade.modoAltoContraste
                ? acessibilidade.temaAltoContraste
                : ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.slate50,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryTeal,
                primary: AppColors.primaryTeal,
                secondary: AppColors.accentAmber,
                surface: Colors.white,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: false,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.slate200, width: 1),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.8),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.statusActive, width: 1),
                ),
                labelStyle: const TextStyle(color: AppColors.slate600, fontSize: 14),
                hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 14),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              dialogTheme: DialogThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
                backgroundColor: Colors.white,
              ),
              dividerTheme: const DividerThemeData(
                color: AppColors.slate200,
                thickness: 1,
                space: 1,
              ),
            ),
            navigatorObservers: [SyncNavigatorObserver(context)],
            home: const LoadingScreen(),
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
