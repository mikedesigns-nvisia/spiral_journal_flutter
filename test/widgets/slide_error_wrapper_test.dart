import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/slide_error_wrapper.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';

void main() {
  group('SlideErrorWrapper', () {
    testWidgets('displays child when no error', (WidgetTester tester) async {
      const testChild = Text('Test Content');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideErrorWrapper(
              slideTitle: 'Test Slide',
              child: testChild,
            ),
          ),
        ),
      );
      
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.text('Unable to load Test Slide'), findsNothing);
    });
    
    testWidgets('displays loading state when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideErrorWrapper(
              slideTitle: 'Test Slide',
              isLoading: true,
              child: Text('Test Content'),
            ),
          ),
        ),
      );
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Test Slide...'), findsOneWidget);
      expect(find.text('Test Content'), findsNothing);
    });
    
    testWidgets('displays error state when error is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideErrorWrapper(
              slideTitle: 'Test Slide',
              error: 'Network error occurred',
              child: Text('Test Content'),
            ),
          ),
        ),
      );
      
      expect(find.text('Unable to load Test Slide'), findsOneWidget);
      expect(find.text('Network error occurred'), findsOneWidget);
      expect(find.text('Test Content'), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
    
    testWidgets('displays retry button when onRetry is provided', (WidgetTester tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideErrorWrapper(
              slideTitle: 'Test Slide',
              error: 'Network error occurred',
              onRetry: () => retryPressed = true,
              child: Text('Test Content'),
            ),
          ),
        ),
      );
      
      expect(find.text('Retry'), findsOneWidget);
      
      await tester.tap(find.text('Retry'));
      await tester.pump();
      
      expect(retryPressed, isTrue);
    });
    
    testWidgets('displays skip button in error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideErrorWrapper(
              slideTitle: 'Test Slide',
              error: 'Network error occurred',
              child: Text('Test Content'),
            ),
          ),
        ),
      );
      
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('You can continue navigating to other slides'), findsOneWidget);
    });
    
    testWidgets('uses custom error builder when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideErrorWrapper(
              slideTitle: 'Test Slide',
              error: 'Custom error',
              errorBuilder: (error, onRetry) => Text('Custom Error: $error'),
              child: Text('Test Content'),
            ),
          ),
        ),
      );
      
      expect(find.text('Custom Error: Custom error'), findsOneWidget);
      expect(find.text('Unable to load Test Slide'), findsNothing);
    });
    
    testWidgets('extension method works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text('Test Content').withSlideErrorHandling(
              slideTitle: 'Test Slide',
              error: 'Test error',
            ),
          ),
        ),
      );
      
      expect(find.text('Unable to load Test Slide'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
    });
  });
}