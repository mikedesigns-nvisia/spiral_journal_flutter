// This is a basic Flutter widget test for Spiral Journal app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spiral_journal/main.dart';

void main() {
  testWidgets('Spiral Journal app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpiralJournalApp());

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Look for navigation elements
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
