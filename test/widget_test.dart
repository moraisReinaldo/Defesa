// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:defesa_civil_app/main.dart';
import 'package:defesa_civil_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Initialize storage service
    final storageService = StorageService();
    await storageService.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(storageService: storageService));

    // Wait for the splash screen or initial screen to load
    await tester.pumpAndSettle();

    // Verify that the app has started (basic smoke test)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
