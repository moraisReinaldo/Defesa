import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/ocorrencia_provider.dart';
import 'providers/usuario_provider.dart';
import 'providers/ponto_interesse_provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Orientação apenas vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final storageService = StorageService();
  await storageService.init();

  final apiService = ApiService(storageService);

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
  ));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;
  final NotificationService notificationService;

   const MyApp({
    super.key,
    required this.storageService,
    required this.apiService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UsuarioProvider(storageService, apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => OcorrenciaProvider(storageService, apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => PontoInteresseProvider(apiService),
        ),
        Provider.value(value: notificationService),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'Defesa Civil em Foco',
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
    context.read<UsuarioProvider>().sincronizarGlobal();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    context.read<UsuarioProvider>().sincronizarGlobal();
  }
}
