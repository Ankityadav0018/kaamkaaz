import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:kaamkaaz/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Kaamkaaz End-to-End Test', () {
    testWidgets('Verify app initialization', (tester) async {
      // Allow app to initialize fully with a safe runAsync handler for Timers
      await tester.runAsync(() async {
        app.main();
        // Wait for splash screen and initial routing
        await tester.pumpAndSettle();
      });

      // Verify that the app's root widget is present
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
