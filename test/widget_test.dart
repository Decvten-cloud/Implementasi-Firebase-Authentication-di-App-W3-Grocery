// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_12/main.dart';

void main() {
  testWidgets('Grocery app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Pump the main app shell directly to avoid splash/login flows in tests.
    await tester.pumpWidget(
      MaterialApp(
        home: RootShell(
          onPickBrand: (_) {},
          onToggleDark: () {},
          brandIndex: 0,
          brandColors: const [
            Color(0xFF10B981),
            Color(0xFF3B82F6),
            Color(0xFFF59E0B),
            Color(0xFFEF4444),
            Color(0xFF06B6D4),
            Color(0xFF8B5CF6),
          ],
          dark: false,
        ),
      ),
    );

    // Verify that the app shell shows Grocery title
    expect(find.text('Grocery'), findsOneWidget);

    // Verify that navigation bar is present and has items
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
