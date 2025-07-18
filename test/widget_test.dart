// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spiral_journal/main.dart';

void main() {
  testWidgets('Spiral Journal app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpiralJournalApp());

    // Wait for the app to initialize
    await tester.pumpAndSettle();

    // Verify that the main navigation elements are present
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Mirror'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify that we can navigate between tabs
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    
    // Should show history screen content
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
