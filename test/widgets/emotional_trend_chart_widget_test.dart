import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/emotional_trend_chart.dart';
import 'package:spiral_journal/services/emotional_mirror_service.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';
import '../utils/chart_test_utils.dart';

void main() {
  group('EmotionalTrendChart Widget Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });
    late List<EmotionalTrendPoint> testTrendPoints;

    setUp(() {
      testTrendPoints = [
        EmotionalTrendPoint(
          date: DateTime.now().subtract(const Duration(days: 7)),
          intensity: 0.8,
          entryCount: 2,
        ),
        EmotionalTrendPoint(
          date: DateTime.now().subtract(const Duration(days: 5)),
          intensity: 0.6,
          entryCount: 1,
        ),
        EmotionalTrendPoint(
          date: DateTime.now().subtract(const Duration(days: 2)),
          intensity: 0.7,
          entryCount: 3,
        ),
      ];
    });

    testWidgets('should render emotional trend chart with data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmotionalTrendChart(trendPoints: testTrendPoints),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render the chart widget
      expect(find.byType(EmotionalTrendChart), findsOneWidget);
      
      // Should show chart content
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should handle empty data gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmotionalTrendChart(trendPoints: []),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(EmotionalTrendChart), findsOneWidget);
      
      // Should show empty state message
      expect(find.textContaining('No trend data'), findsOneWidget);
    });

    testWidgets('should work in both light and dark themes', (WidgetTester tester) async {
      await WidgetTestUtils.runThemeTest(
        tester,
        Scaffold(
          body: EmotionalTrendChart(trendPoints: testTrendPoints),
        ),
        testDescription: 'EmotionalTrendChart',
        commonTest: (tester, themeMode) async {
          final themeDescription = themeMode == ThemeMode.light ? 'light' : 'dark';
          
          // Verify the chart renders correctly
          WidgetTestUtils.verifyWidgetState(
            find.byType(EmotionalTrendChart),
            customMessage: 'EmotionalTrendChart should render correctly in $themeDescription theme',
          );
          
          // Verify theme-specific text colors if text is present
          WidgetTestUtils.verifyTextThemeColors(
            tester,
            themeMode,
            find.byType(Text),
            customMessage: 'Text colors should be appropriate for $themeDescription theme',
          );
        },
      );
    });

    testWidgets('should display custom title', (WidgetTester tester) async {
      const customTitle = 'Custom Trend Chart';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmotionalTrendChart(
              trendPoints: testTrendPoints,
              title: customTitle,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(customTitle), findsOneWidget);
    });

    testWidgets('should handle custom height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmotionalTrendChart(
              trendPoints: testTrendPoints,
              height: 300,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render with custom height
      expect(find.byType(EmotionalTrendChart), findsOneWidget);
    });

    testWidgets('should handle single data point', (WidgetTester tester) async {
      final singlePoint = [
        EmotionalTrendPoint(
          date: DateTime.now(),
          intensity: 0.5,
          entryCount: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmotionalTrendChart(trendPoints: singlePoint),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render single point without errors
      expect(find.byType(EmotionalTrendChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Verify no exceptions are thrown during rendering
      expect(() => tester.pumpAndSettle(), returnsNormally);
    });
    
    testWidgets('should handle identical intensity values', (WidgetTester tester) async {
      // Create data points with identical intensity values
      final identicalPoints = [
        EmotionalTrendPoint(
          date: DateTime.now().subtract(const Duration(days: 2)),
          intensity: 0.7,
          entryCount: 1,
        ),
        EmotionalTrendPoint(
          date: DateTime.now().subtract(const Duration(days: 1)),
          intensity: 0.7,
          entryCount: 1,
        ),
        EmotionalTrendPoint(
          date: DateTime.now(),
          intensity: 0.7,
          entryCount: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmotionalTrendChart(trendPoints: identicalPoints),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(EmotionalTrendChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Verify no exceptions are thrown during rendering
      expect(() => tester.pumpAndSettle(), returnsNormally);
    });
    
    testWidgets('should handle extreme intensity values', (WidgetTester tester) async {
      // Create data points with extreme intensity values
      final extremePoints = [
        EmotionalTrendPoint(
          date: DateTime.now().subtract(const Duration(days: 3)),
          intensity: 0.0, // Minimum value
          entryCount: 1,
        ),
        EmotionalTrendPoint(
          date: DateTime.now().subtract(const Duration(days: 2)),
          intensity: 10.0, // Maximum value
          entryCount: 1,
        ),
        EmotionalTrendPoint(
          date: DateTime.now().subtract(const Duration(days: 1)),
          intensity: double.maxFinite, // Invalid value that should be handled
          entryCount: 1,
        ),
        EmotionalTrendPoint(
          date: DateTime.now(),
          intensity: double.nan, // NaN value that should be handled
          entryCount: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmotionalTrendChart(trendPoints: extremePoints),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors despite extreme values
      expect(find.byType(EmotionalTrendChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Verify no exceptions are thrown during rendering
      expect(() => tester.pumpAndSettle(), returnsNormally);
    });
    
    testWidgets('should handle problematic data using ChartErrorTestData', (WidgetTester tester) async {
      // Use the ChartErrorTestData utility to generate problematic data
      final mixedProblematicData = ChartErrorTestData.generateMixedProblematicData();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmotionalTrendChart(trendPoints: mixedProblematicData),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors despite problematic data
      expect(find.byType(EmotionalTrendChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Verify no exceptions are thrown during rendering
      expect(() => tester.pumpAndSettle(), returnsNormally);
    });
    
    testWidgets('should handle problematic sentiment data', (WidgetTester tester) async {
      // Use the ChartErrorTestData utility to generate problematic sentiment data
      final problematicSentimentData = ChartErrorTestData.generateProblematicSentimentData();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentimentTrendChart(trendPoints: problematicSentimentData),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors despite problematic data
      expect(find.byType(SentimentTrendChart), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Verify no exceptions are thrown during rendering
      expect(() => tester.pumpAndSettle(), returnsNormally);
    });
  });
}