import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaamkaaz/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Run the app inside runAsync to handle any Timers correctly
    await tester.runAsync(() async {
      await tester.pumpWidget(const ProviderScope(child: KaamkaazApp()));
      
      // Wait for any initial animations or state updates
      await tester.pumpAndSettle();

      // Verify that the splash screen or initial route renders
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
