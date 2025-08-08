import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/interactive_core_card.dart';
import 'package:spiral_journal/models/core.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';

void main() {
  group('InteractiveCoreCard Widget Tests', () {
    late EmotionalCore testCore;

    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    setUp(() {
      testCore = EmotionalCore(
        id: 'test-core',
        name: 'Optimism',
        description: 'Test core description',
        color: '#FF6B35',
        currentLevel: 0.75,
        previousLevel: 0.60,
        trend: 'rising',
        insight: 'Test insight',
        percentage: 75.0,
        milestones: [
          CoreMilestone(
            id: 'milestone-1',
            title: 'First milestone',
            description: 'Test milestone',
            isAchieved: true,
          ),
        ],
      );
    });

    testWidgets('should render interactive core card with basic content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: testCore,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.byType(InteractiveCoreCard),
        customMessage: 'InteractiveCoreCard should render properly',
      );

      WidgetTestUtils.verifyWidgetState(
        find.text('Optimism'),
        customMessage: 'Core name should be displayed',
      );

      WidgetTestUtils.verifyWidgetState(
        find.text('75%'),
        customMessage: 'Core percentage should be displayed',
      );
    });

    testWidgets('should handle tap interactions', (WidgetTester tester) async {
      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: testCore,
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await WidgetTestUtils.tapButton(
        tester,
        find.byType(InteractiveCoreCard),
        customMessage: 'Should be able to tap InteractiveCoreCard',
      );

      expect(tapCalled, isTrue, reason: 'onTap callback should be called');
    });

    testWidgets('should handle long press interactions', (WidgetTester tester) async {
      bool longPressCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: testCore,
              onLongPress: () => longPressCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPress(find.byType(InteractiveCoreCard));
      await tester.pumpAndSettle();

      expect(longPressCalled, isTrue, reason: 'onLongPress callback should be called');
    });

    testWidgets('should handle double tap interactions', (WidgetTester tester) async {
      bool doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: testCore,
              onDoubleTap: () => doubleTapCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final cardFinder = find.byType(InteractiveCoreCard);
      await tester.tap(cardFinder);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      expect(doubleTapCalled, isTrue, reason: 'onDoubleTap callback should be called');
    });

    testWidgets('should show progress bar with correct level', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: testCore,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressContainer = find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      );
      
      expect(progressContainer, findsWidgets, reason: 'Progress bar container should be present');
    });

    testWidgets('should show trend indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: testCore,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.text('Level ${(testCore.currentLevel * 10).round()}'),
        customMessage: 'Level text should be displayed',
      );
    });

    testWidgets('should handle pulsing animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: testCore,
              isPulsing: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      WidgetTestUtils.verifyWidgetState(
        find.byType(InteractiveCoreCard),
        customMessage: 'InteractiveCoreCard should handle pulsing animation',
      );
    });

    testWidgets('should show evolution story when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: testCore,
              showEvolutionStory: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPress(find.byType(InteractiveCoreCard));
      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.text('Evolution Story'),
        customMessage: 'Evolution story section should be displayed after long press',
      );
    });

    testWidgets('should display milestone information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: testCore,
              showEvolutionStory: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPress(find.byType(InteractiveCoreCard));
      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.text('First milestone'),
        customMessage: 'Milestone title should be displayed',
      );
    });

    testWidgets('should handle accessibility focus', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: testCore,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics,
      );

      expect(semanticsFinder, findsOneWidget, reason: 'Semantics widget should be present for accessibility');
    });

    testWidgets('should work in both light and dark themes', (WidgetTester tester) async {
      await WidgetTestUtils.runThemeTest(
        tester,
        InteractiveCoreCard(core: testCore),
        testDescription: 'InteractiveCoreCard',
        commonTest: (tester, themeMode) async {
          final themeDescription = themeMode == ThemeMode.light ? 'light' : 'dark';
          
          WidgetTestUtils.verifyWidgetState(
            find.byType(InteractiveCoreCard),
            customMessage: 'InteractiveCoreCard should render correctly in $themeDescription theme',
          );
          
          WidgetTestUtils.verifyWidgetState(
            find.text('Optimism'),
            customMessage: 'Core name should be visible in $themeDescription theme',
          );
        },
      );
    });

    testWidgets('should handle different core types', (WidgetTester tester) async {
      final coreTypes = [
        'Optimism',
        'Resilience', 
        'Self-Awareness',
        'Creativity',
        'Social Connection',
        'Growth Mindset',
      ];

      for (final coreType in coreTypes) {
        final core = EmotionalCore(
          id: 'test-$coreType',
          name: coreType,
          description: 'Test $coreType description',
          color: '#FF6B35',
          currentLevel: 0.5,
          previousLevel: 0.4,
          trend: 'stable',
          insight: '',
          percentage: 50.0,
          milestones: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InteractiveCoreCard(
                core: core,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        WidgetTestUtils.verifyWidgetState(
          find.text(coreType),
          customMessage: '$coreType core should render correctly',
        );
      }
    });

    testWidgets('should handle edge cases gracefully', (WidgetTester tester) async {
      final edgeCaseCore = EmotionalCore(
        id: 'edge-case',
        name: 'Test Core',
        description: '',
        color: 'invalid-color',
        currentLevel: 0.0,
        previousLevel: 0.0,
        trend: 'unknown',
        insight: '',
        percentage: 0.0,
        milestones: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCoreCard(
              core: edgeCaseCore,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.byType(InteractiveCoreCard),
        customMessage: 'InteractiveCoreCard should handle edge cases gracefully',
      );

      WidgetTestUtils.verifyWidgetState(
        find.text('Test Core'),
        customMessage: 'Core name should still be displayed with edge case data',
      );
    });
  });
}