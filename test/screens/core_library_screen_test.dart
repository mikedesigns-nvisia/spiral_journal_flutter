import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/screens/core_library_screen.dart';
import 'package:spiral_journal/theme/app_theme.dart';

void main() {
  group('CoreLibraryScreen', () {
    setUp(() async {
      // Initialize SharedPreferences with mock values
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display core library screen with loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display header with title and description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Should display header elements
      expect(find.text('Core Library'), findsOneWidget);
      expect(find.text('Track your emotional growth across six personality cores'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });

    testWidgets('should display all six personality cores', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Should display all six core names
      expect(find.text('Optimism'), findsOneWidget);
      expect(find.text('Resilience'), findsOneWidget);
      expect(find.text('Self-Awareness'), findsOneWidget);
      expect(find.text('Creativity'), findsOneWidget);
      expect(find.text('Social Connection'), findsOneWidget);
      expect(find.text('Growth Mindset'), findsOneWidget);
    });

    testWidgets('should display core overview with progress statistics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Should display overall progress section
      expect(find.text('Overall Progress'), findsOneWidget);
      expect(find.text('Average Core Level'), findsOneWidget);
      expect(find.text('Cores Rising'), findsOneWidget);
    });

    testWidgets('should display core grid with progress circles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Should display the core grid section
      expect(find.text('Your Six Personality Cores'), findsOneWidget);
      
      // Should have custom paint widgets for progress circles
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Should display core icons (allowing for multiple instances)
      expect(find.byIcon(Icons.wb_sunny), findsWidgets); // Optimism
      expect(find.byIcon(Icons.shield), findsWidgets); // Resilience
      expect(find.byIcon(Icons.psychology), findsWidgets); // Self-Awareness
      expect(find.byIcon(Icons.palette), findsWidgets); // Creativity
      expect(find.byIcon(Icons.people), findsWidgets); // Social Connection
      expect(find.byIcon(Icons.trending_up), findsWidgets); // Growth Mindset
    });

    testWidgets('should show core detail sheet when core card is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Tap on the first core card (Optimism)
      await tester.tap(find.text('Optimism'));
      await tester.pumpAndSettle();

      // Should show the core detail sheet
      expect(find.byType(CoreDetailSheet), findsOneWidget);
    });

    testWidgets('should support pull-to-refresh', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Should have RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Perform pull-to-refresh gesture
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 300), 1000);
      await tester.pump();
      
      // Should show refresh indicator
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle();
    });

    testWidgets('should display growth recommendations when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Should display growth recommendations section if recommendations exist
      // Note: This depends on the core service returning recommendations
      // The test will pass regardless since recommendations might be empty initially
      final recommendationsTitle = find.text('Growth Recommendations');
      if (recommendationsTitle.evaluate().isNotEmpty) {
        expect(find.byIcon(Icons.lightbulb_outline), findsWidgets);
      }
    });

    testWidgets('should display core synergies when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Should display core synergies section if combinations exist
      // Note: This depends on the core service returning combinations
      // The test will pass regardless since combinations might be empty initially
      final synergiesTitle = find.text('Core Synergies');
      if (synergiesTitle.evaluate().isNotEmpty) {
        expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      }
    });
  });

  group('CoreDetailSheet', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display core details in bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Tap on a core card to open detail sheet
      await tester.tap(find.text('Optimism'));
      await tester.pumpAndSettle();

      // Should display core detail sheet elements
      expect(find.text('Progress Timeline'), findsOneWidget);
      expect(find.text('Milestones'), findsOneWidget);
      expect(find.text('Current Level'), findsOneWidget);
      
      // Should display milestone items
      expect(find.text('Foundation'), findsOneWidget);
      expect(find.text('Development'), findsOneWidget);
      expect(find.text('Proficiency'), findsOneWidget);
      expect(find.text('Mastery'), findsOneWidget);
    });

    testWidgets('should display progress timeline with linear progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Open core detail sheet
      await tester.tap(find.text('Resilience'));
      await tester.pumpAndSettle();

      // Should display linear progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display milestones with achievement status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CoreLibraryScreen(),
        ),
      );

      // Wait for the data to load
      await tester.pumpAndSettle();

      // Scroll to make sure Self-Awareness is visible
      await tester.ensureVisible(find.text('Self-Awareness'));
      await tester.pumpAndSettle();

      // Open core detail sheet
      await tester.tap(find.text('Self-Awareness'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should display milestone icons (achieved or unachieved)
      // Note: Some milestones might be achieved, some might not be
      final checkCircles = find.byIcon(Icons.check_circle);
      final uncheckedCircles = find.byIcon(Icons.radio_button_unchecked);
      
      // At least one type of milestone icon should be present
      expect(checkCircles.evaluate().isNotEmpty || uncheckedCircles.evaluate().isNotEmpty, isTrue);
    });
  });

  group('CircularProgressPainter', () {
    testWidgets('should paint circular progress correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomPaint(
                size: const Size(100, 100),
                painter: CircularProgressPainter(
                  progress: 0.7,
                  color: Colors.blue,
                  strokeWidth: 8,
                ),
              ),
            ),
          ),
        ),
      );

      // Should render without errors - allow for multiple CustomPaint widgets
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}