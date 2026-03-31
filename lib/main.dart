import 'package:firebase_core/firebase_core.dart';
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
import 'screens/mapa_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Orientação apenas vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final storageService = StorageService();
  await storageService.init();

  final apiService = ApiService(storageService);

  try {
    await Firebase.initializeApp();
    if (kDebugMode) print("Firebase inicializado com sucesso!");
    
    final notificationService = NotificationService();
    await notificationService.init();

    runApp(MyApp(
      storageService: storageService,
      apiService: apiService,
      notificationService: notificationService,
    ));
  } catch (e) {
    if (kDebugMode) print("ERRO CRÍTICO na inicialização: $e");
    // Mesmo com erro, tentamos rodar o app para não travar na splash
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Erro ao carregar serviços: $e")),
      ),
    ));
  }
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
          create: (_) => UsuarioProvider(storageService, apiService)..verificarUsuarioLogado(),
        ),
        ChangeNotifierProvider(
          create: (_) => OcorrenciaProvider(storageService, apiService)..carregarOcorrencias(),
        ),
        ChangeNotifierProvider(
          create: (_) => PontoInteresseProvider(apiService),
        ),
        Provider.value(value: notificationService),
      ],
      child: MaterialApp(
        title: 'Defesa Civil em Foco',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor:  const Color(0xFF003366), // Azul Defesa Civil
            primary:  const Color(0xFF003366),
            secondary:  const Color(0xFFFF6600), // Laranja Defesa Civil
          ),
          appBarTheme:  const AppBarTheme(
            backgroundColor: Color(0xFF003366),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home:  const MapaScreen(),
      ),
    );
  }
}
