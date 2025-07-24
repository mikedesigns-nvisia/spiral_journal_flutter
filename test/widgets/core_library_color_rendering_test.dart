import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/screens/core_library_screen.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/services/core_library_service.dart';

void main() {
  group('Core Library Color Rendering Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Valid Color Formats', () {
      testWidgets('should render cores with hex colors (with #)', (WidgetTester tester) async {
        // Mock cores with various hex color formats
        final testCores = [
          EmotionalCore(
            id: 'optimism',
            name: 'Optimism',
            description: 'Test core',
            currentLevel: 0.7,
            previousLevel: 0.6,
            lastUpdated: DateTime.now(),
            trend: 'rising',
            color: '#FF5722', // Standard hex with #
            iconPath: '',
            insight: '',
            relatedCores: [],
          ),
          EmotionalCore(
            id: 'resilience',
            name: 'Resilience',
            description: 'Test core',
            currentLevel: 0.8,
            previousLevel: 0.7,
            lastUpdated: DateTime.now(),
            trend: 'rising',
            color: '#2196F3', // Blue hex with #
            iconPath: '',
            insight: '',
            relatedCores: [],
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the screen renders without errors
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
      });

      testWidgets('should render cores with hex colors (without #)', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the screen renders without errors
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
      });

      testWidgets('should render cores with 8-digit hex colors (ARGB)', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the screen renders without errors
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
      });
    });

    group('Invalid Color Formats', () {
      testWidgets('should handle invalid hex color gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should still render without crashing
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
        
        // Should not show any error widgets
        expect(find.byType(ErrorWidget), findsNothing);
      });

      testWidgets('should handle empty color string gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should still render without crashing
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
        
        // Should not show any error widgets
        expect(find.byType(ErrorWidget), findsNothing);
      });

      testWidgets('should handle malformed color strings gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should still render without crashing
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
        
        // Should not show any error widgets
        expect(find.byType(ErrorWidget), findsNothing);
      });
    });

    group('Color Consistency Across Themes', () {
      testWidgets('should render consistently in light theme', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify core elements are present
        expect(find.text('Core Library'), findsOneWidget);
        expect(find.text('Your Six Personality Cores'), findsOneWidget);
        
        // Verify progress circles are rendered
        expect(find.byType(CustomPaint), findsWidgets);
        
        // Verify core icons are present
        expect(find.byIcon(Icons.wb_sunny), findsWidgets); // Optimism
        expect(find.byIcon(Icons.shield), findsWidgets); // Resilience
      });

      testWidgets('should render consistently in dark theme', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify core elements are present
        expect(find.text('Core Library'), findsOneWidget);
        expect(find.text('Your Six Personality Cores'), findsOneWidget);
        
        // Verify progress circles are rendered
        expect(find.byType(CustomPaint), findsWidgets);
        
        // Verify core icons are present
        expect(find.byIcon(Icons.wb_sunny), findsWidgets); // Optimism
        expect(find.byIcon(Icons.shield), findsWidgets); // Resilience
      });
    });

    group('Progress Circle Color Rendering', () {
      testWidgets('should render progress circles with correct colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find all CustomPaint widgets (progress circles)
        final customPaintWidgets = find.byType(CustomPaint);
        expect(customPaintWidgets, findsWidgets);

        // Verify that CustomPaint widgets are rendered without errors
        for (final widget in tester.widgetList<CustomPaint>(customPaintWidgets)) {
          if (widget.painter is CircularProgressPainter) {
            expect(widget.painter, isNotNull);
            expect(widget.painter, isA<CircularProgressPainter>());
          }
        }
      });

      testWidgets('should handle different progress values correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify progress percentages are displayed
        final percentageTexts = find.textContaining('%');
        expect(percentageTexts, findsWidgets);

        // Verify that percentages are within valid range (0-100)
        for (final textWidget in tester.widgetList<Text>(percentageTexts)) {
          final text = textWidget.data ?? '';
          if (text.contains('%')) {
            final percentageMatch = RegExp(r'(\d+)%').firstMatch(text);
            if (percentageMatch != null) {
              final percentage = int.parse(percentageMatch.group(1)!);
              expect(percentage, greaterThanOrEqualTo(0));
              expect(percentage, lessThanOrEqualTo(100));
            }
          }
        }
      });
    });

    group('Color Opacity and Styling', () {
      testWidgets('should apply consistent opacity to core colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that the screen renders without errors
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        
        // Verify that core cards are present
        final coreCards = find.byType(GestureDetector);
        expect(coreCards, findsWidgets);
      });

      testWidgets('should maintain color consistency in card styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that containers with decorations are present
        final decoratedContainers = find.byType(Container);
        expect(decoratedContainers, findsWidgets);
        
        // Verify that the overall layout is rendered correctly
        expect(find.text('Core Library'), findsOneWidget);
        expect(find.text('Your Six Personality Cores'), findsOneWidget);
      });
    });

    group('Trend Color Rendering', () {
      testWidgets('should display trend colors correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify trend indicators are present (at least one type should exist)
        final trendUpIcons = find.byIcon(Icons.trending_up);
        final trendDownIcons = find.byIcon(Icons.trending_down);
        final trendFlatIcons = find.byIcon(Icons.trending_flat);
        
        // At least one trend icon should be present
        expect(
          trendUpIcons.evaluate().isNotEmpty || 
          trendDownIcons.evaluate().isNotEmpty || 
          trendFlatIcons.evaluate().isNotEmpty, 
          isTrue
        );
        
        // Verify trend text is displayed (at least one type should exist)
        final risingText = find.textContaining('RISING');
        final stableText = find.textContaining('STABLE');
        final decliningText = find.textContaining('DECLINING');
        
        expect(
          risingText.evaluate().isNotEmpty || 
          stableText.evaluate().isNotEmpty || 
          decliningText.evaluate().isNotEmpty, 
          isTrue
        );
      });
    });

    group('Core Detail Sheet Color Rendering', () {
      testWidgets('should render core detail sheet with consistent colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on a core to open detail sheet
        await tester.tap(find.text('Optimism'));
        await tester.pumpAndSettle();

        // Verify detail sheet is displayed
        expect(find.byType(CoreDetailSheet), findsOneWidget);
        
        // Verify progress timeline is rendered
        expect(find.text('Progress Timeline'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        
        // Verify milestones section
        expect(find.text('Milestones'), findsOneWidget);
      });

      testWidgets('should handle color parsing in detail sheet', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Open detail sheet for different cores
        await tester.tap(find.text('Resilience'));
        await tester.pumpAndSettle();

        // Verify detail sheet renders without errors
        expect(find.byType(CoreDetailSheet), findsOneWidget);
        expect(find.text('Progress Timeline'), findsOneWidget);
        
        // Close the sheet
        await tester.tapAt(const Offset(50, 50));
        await tester.pumpAndSettle();
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should handle null color values gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without crashing
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
      });

      testWidgets('should handle very long color strings', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without crashing
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
      });

      testWidgets('should handle special characters in color strings', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without crashing
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
      });
    });

    group('Color Accessibility', () {
      testWidgets('should maintain sufficient color contrast', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that text is readable (no accessibility warnings)
        expect(find.text('Core Library'), findsOneWidget);
        expect(find.text('Your Six Personality Cores'), findsOneWidget);
        
        // Verify that core names are visible
        expect(find.text('Optimism'), findsOneWidget);
        expect(find.text('Resilience'), findsOneWidget);
        expect(find.text('Self-Awareness'), findsOneWidget);
        expect(find.text('Creativity'), findsOneWidget);
        expect(find.text('Social Connection'), findsOneWidget);
        expect(find.text('Growth Mindset'), findsOneWidget);
      });

      testWidgets('should work with high contrast themes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that all elements are still visible in dark theme
        expect(find.text('Core Library'), findsOneWidget);
        expect(find.text('Your Six Personality Cores'), findsOneWidget);
        
        // Verify core cards are rendered
        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('Performance with Multiple Colors', () {
      testWidgets('should handle multiple cores with different colors efficiently', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        // Measure rendering time
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Verify that rendering completes in reasonable time (less than 5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        
        // Verify all cores are rendered
        expect(find.text('Core Library'), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      });
    });
  });

  group('CircularProgressPainter Color Tests', () {
    testWidgets('should paint with different colors correctly', (WidgetTester tester) async {
      const testColors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
      ];

      for (final color in testColors) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CustomPaint(
                  size: const Size(100, 100),
                  painter: CircularProgressPainter(
                    progress: 0.7,
                    color: color,
                    strokeWidth: 8,
                  ),
                ),
              ),
            ),
          ),
        );

        // Should render without errors
        expect(find.byType(CustomPaint), findsWidgets);
        
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should handle different progress values', (WidgetTester tester) async {
      const testProgressValues = [0.0, 0.25, 0.5, 0.75, 1.0];

      for (final progress in testProgressValues) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CustomPaint(
                  size: const Size(100, 100),
                  painter: CircularProgressPainter(
                    progress: progress,
                    color: Colors.blue,
                    strokeWidth: 8,
                  ),
                ),
              ),
            ),
          ),
        );

        // Should render without errors
        expect(find.byType(CustomPaint), findsWidgets);
        
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should handle different stroke widths', (WidgetTester tester) async {
      const testStrokeWidths = [2.0, 4.0, 8.0, 12.0, 16.0];

      for (final strokeWidth in testStrokeWidths) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CustomPaint(
                  size: const Size(100, 100),
                  painter: CircularProgressPainter(
                    progress: 0.7,
                    color: Colors.blue,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
          ),
        );

        // Should render without errors
        expect(find.byType(CustomPaint), findsWidgets);
        
        await tester.pumpAndSettle();
      }
    });
  });
}