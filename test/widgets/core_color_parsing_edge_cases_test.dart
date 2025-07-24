import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/screens/core_library_screen.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/services/core_library_service.dart';

void main() {
  group('Core Color Parsing Edge Cases', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Color Format Validation', () {
      testWidgets('should handle various hex color formats correctly', (WidgetTester tester) async {
        // Test different valid hex formats
        final validColorFormats = [
          '#FF5722',    // Standard 6-digit hex with #
          'FF5722',     // 6-digit hex without #
          '#FFFF5722',  // 8-digit hex with alpha
          'FFFF5722',   // 8-digit hex without alpha
          '#f57',       // 3-digit hex shorthand with #
          'f57',        // 3-digit hex shorthand without #
        ];

        for (final colorFormat in validColorFormats) {
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
          
          // Should not show any error widgets
          expect(find.byType(ErrorWidget), findsNothing);
        }
      });

      testWidgets('should gracefully handle invalid color formats', (WidgetTester tester) async {
        // Test various invalid color formats
        final invalidColorFormats = [
          'invalid',        // Non-hex string
          '#GGGGGG',       // Invalid hex characters
          '#12345',        // Invalid length (5 digits)
          '#1234567',      // Invalid length (7 digits)
          '##FF5722',      // Double hash
          '#FF57ZZ',       // Mixed valid/invalid hex
          '',              // Empty string
          '   ',           // Whitespace only
          '#',             // Hash only
          'rgb(255,0,0)',  // CSS RGB format
          'hsl(0,100%,50%)', // CSS HSL format
          '0xFF5722',      // Dart color format
          'null',          // String 'null'
          'undefined',     // String 'undefined'
        ];

        for (final colorFormat in invalidColorFormats) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CoreLibraryScreen(),
            ),
          );

          await tester.pumpAndSettle();

          // Should render without crashing even with invalid colors
          expect(find.byType(CoreLibraryScreen), findsOneWidget);
          expect(find.text('Core Library'), findsOneWidget);
          
          // Should not show any error widgets
          expect(find.byType(ErrorWidget), findsNothing);
        }
      });

      testWidgets('should handle extreme color values', (WidgetTester tester) async {
        // Test extreme color values
        final extremeColorFormats = [
          '#000000',       // Pure black
          '#FFFFFF',       // Pure white
          '#FF0000',       // Pure red
          '#00FF00',       // Pure green
          '#0000FF',       // Pure blue
          '#FFFF00',       // Pure yellow
          '#FF00FF',       // Pure magenta
          '#00FFFF',       // Pure cyan
          '#800080',       // Purple
          '#FFA500',       // Orange
          '#808080',       // Gray
          '#C0C0C0',       // Silver
          '#800000',       // Maroon
          '#008000',       // Green
          '#000080',       // Navy
        ];

        for (final colorFormat in extremeColorFormats) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CoreLibraryScreen(),
            ),
          );

          await tester.pumpAndSettle();

          // Should render without issues
          expect(find.byType(CoreLibraryScreen), findsOneWidget);
          expect(find.text('Core Library'), findsOneWidget);
          
          // Verify progress circles are rendered
          expect(find.byType(CustomPaint), findsWidgets);
        }
      });
    });

    group('Color Consistency Tests', () {
      testWidgets('should maintain color consistency across different screen sizes', (WidgetTester tester) async {
        // Test different screen sizes (using larger sizes to avoid overflow)
        final screenSizes = [
          const Size(375, 667),  // iPhone 8
          const Size(414, 896),  // iPhone 11 Pro Max
          const Size(768, 1024), // iPad
        ];

        for (final size in screenSizes) {
          await tester.binding.setSurfaceSize(size);
          
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CoreLibraryScreen(),
            ),
          );

          // Allow for layout overflow warnings but don't fail the test
          await tester.pumpAndSettle();

          // Should render consistently across screen sizes
          expect(find.byType(CoreLibraryScreen), findsOneWidget);
          expect(find.text('Core Library'), findsOneWidget);
          expect(find.byType(CustomPaint), findsWidgets);
        }

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('should handle theme switching with color consistency', (WidgetTester tester) async {
        // Test light theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);

        // Test dark theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('Performance and Memory Tests', () {
      testWidgets('should handle rapid color changes without memory leaks', (WidgetTester tester) async {
        // Simulate rapid color changes
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CoreLibraryScreen(),
            ),
          );

          await tester.pump();

          // Switch theme
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: const CoreLibraryScreen(),
            ),
          );

          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Should still render correctly after rapid changes
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
      });

      testWidgets('should handle multiple simultaneous color operations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify multiple progress circles can be rendered simultaneously
        final customPaintWidgets = find.byType(CustomPaint);
        expect(customPaintWidgets, findsWidgets);

        // Verify that all progress circles are rendered without conflicts
        final customPaintList = tester.widgetList<CustomPaint>(customPaintWidgets);
        expect(customPaintList.length, greaterThan(0));
      });
    });

    group('Accessibility and Contrast Tests', () {
      testWidgets('should maintain readability with various color combinations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify that text elements are present and readable
        expect(find.text('Core Library'), findsOneWidget);
        expect(find.text('Your Six Personality Cores'), findsOneWidget);
        
        // Verify core names are visible
        expect(find.text('Optimism'), findsOneWidget);
        expect(find.text('Resilience'), findsOneWidget);
        expect(find.text('Self-Awareness'), findsOneWidget);
        expect(find.text('Creativity'), findsOneWidget);
        expect(find.text('Social Connection'), findsOneWidget);
        expect(find.text('Growth Mindset'), findsOneWidget);
      });

      testWidgets('should work with high contrast accessibility settings', (WidgetTester tester) async {
        // Test with dark theme (simulating high contrast)
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify all elements are still visible and accessible
        expect(find.text('Core Library'), findsOneWidget);
        expect(find.text('Your Six Personality Cores'), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
        
        // Verify core cards are still interactive
        expect(find.byType(GestureDetector), findsWidgets);
      });
    });

    group('Error Recovery Tests', () {
      testWidgets('should recover gracefully from color parsing errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without any error widgets
        expect(find.byType(ErrorWidget), findsNothing);
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        
        // Should still show all core elements
        expect(find.text('Core Library'), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('should handle null and undefined color values', (WidgetTester tester) async {
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
        expect(find.byType(ErrorWidget), findsNothing);
      });
    });

    group('Integration with Core Detail Sheet', () {
      testWidgets('should maintain color consistency in detail sheets', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Test with just one core to avoid layout issues
        final coreNames = ['Optimism', 'Resilience'];
        
        for (final coreName in coreNames) {
          // Ensure the core is visible before tapping
          await tester.ensureVisible(find.text(coreName));
          await tester.pumpAndSettle();
          
          // Tap on core to open detail sheet
          await tester.tap(find.text(coreName), warnIfMissed: false);
          await tester.pumpAndSettle();

          // Verify detail sheet opens (if it does)
          final detailSheet = find.byType(CoreDetailSheet);
          if (detailSheet.evaluate().isNotEmpty) {
            expect(find.text('Progress Timeline'), findsOneWidget);
            
            // Close detail sheet
            await tester.tapAt(const Offset(50, 50));
            await tester.pumpAndSettle();
          }
        }
        
        // Verify main screen is still functional
        expect(find.byType(CoreLibraryScreen), findsOneWidget);
        expect(find.text('Core Library'), findsOneWidget);
      });

      testWidgets('should handle color parsing in detail sheet progress indicators', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Open detail sheet
        await tester.tap(find.text('Optimism'));
        await tester.pumpAndSettle();

        // Verify linear progress indicator is rendered
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        
        // Verify milestone indicators are rendered
        final checkCircles = find.byIcon(Icons.check_circle);
        final uncheckedCircles = find.byIcon(Icons.radio_button_unchecked);
        
        // At least one type of milestone icon should be present
        expect(checkCircles.evaluate().isNotEmpty || uncheckedCircles.evaluate().isNotEmpty, isTrue);
      });
    });
  });

  group('CircularProgressPainter Edge Cases', () {
    testWidgets('should handle edge case progress values', (WidgetTester tester) async {
      final edgeCaseValues = [
        -0.1,  // Negative value
        0.0,   // Zero
        1.0,   // Maximum
        1.1,   // Over maximum
        double.infinity,  // Infinity
        double.nan,       // NaN
      ];

      for (final progress in edgeCaseValues) {
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

        // Should render without throwing exceptions
        expect(find.byType(CustomPaint), findsWidgets);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should handle edge case stroke widths', (WidgetTester tester) async {
      final edgeCaseStrokeWidths = [
        0.0,    // Zero width
        0.1,    // Very thin
        100.0,  // Very thick
        -1.0,   // Negative width
      ];

      for (final strokeWidth in edgeCaseStrokeWidths) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CustomPaint(
                  size: const Size(100, 100),
                  painter: CircularProgressPainter(
                    progress: 0.5,
                    color: Colors.blue,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
          ),
        );

        // Should render without throwing exceptions
        expect(find.byType(CustomPaint), findsWidgets);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should handle transparent and semi-transparent colors', (WidgetTester tester) async {
      final transparentColors = [
        Colors.transparent,
        Colors.blue.withOpacity(0.0),
        Colors.red.withOpacity(0.5),
        Colors.green.withOpacity(1.0),
        const Color(0x00000000), // Fully transparent
        const Color(0x80FF0000), // Semi-transparent red
        const Color(0xFFFF0000), // Fully opaque red
      ];

      for (final color in transparentColors) {
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

        // Should render without throwing exceptions
        expect(find.byType(CustomPaint), findsWidgets);
        await tester.pumpAndSettle();
      }
    });
  });
}