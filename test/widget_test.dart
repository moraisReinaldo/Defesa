import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:defesa_civil_app/screens/loading_screen.dart';
import 'package:defesa_civil_app/providers/usuario_provider.dart';
import 'package:defesa_civil_app/services/storage_service.dart';
import 'package:defesa_civil_app/services/api_service.dart';
import 'package:defesa_civil_app/services/hive_service.dart';

class FakeStorageService extends StorageService {}

class FakeApiService extends ApiService {
  FakeApiService(super.storage);
}

class FakeHiveService extends HiveService {
  @override
  String? get cidadeFavorita => null;
  @override
  bool get temaEscuro => false;
  @override
  String get filtroStatus => 'TODOS';
  @override
  String get filtroTipo => 'TODOS';
  @override
  bool get notificacoesAtivas => true;
  @override
  DateTime? get ultimaAtualizacao => null;
  @override
  double get limiteChuvaDiaria => 50.0;
  @override
  Future<void> init() async {}
}

void main() {
  testWidgets('Loading screen renders branding correctly', (WidgetTester tester) async {
    final storage = FakeStorageService();
    final api = FakeApiService(storage);
    final hive = FakeHiveService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => UsuarioProvider(storage, api, hive),
          ),
        ],
        child: const MaterialApp(
          home: LoadingScreen(),
        ),
      ),
    );

    expect(find.text('Reinaldo Henrique Morais'), findsOneWidget);
  });
}
