import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/templated_insight_card.dart';
import 'package:spiral_journal/models/insight_template.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';

void main() {
  group('TemplatedInsightCard Widget Tests', () {
    late List<TemplateSelection> testInsights;
    late InsightTemplate testTemplate;
    late InsightCategory testCategory;

    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    setUp(() {
      testCategory = InsightCategory(
        id: 'growth',
        name: 'Growth',
        emoji: '🌱',
        color: Colors.green,
        description: 'Personal growth insights',
      );

      testTemplate = InsightTemplate(
        id: 'test-template',
        title: 'Growth Reflection',
        category: testCategory,
        promptTemplate: 'Test prompt',
        tags: ['growth', 'reflection', 'personal'],
        priority: TemplatePriority.medium,
        animationType: AnimationType.slideUp,
        validationRules: [],
      );

      testInsights = [
        TemplateSelection(
          template: testTemplate,
          generatedInsight: 'This is a test insight about personal growth and development.',
          score: 8.5,
        ),
      ];
    });

    testWidgets('should render templated insight card with content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: testInsights,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.byType(TemplatedInsightCard),
        customMessage: 'TemplatedInsightCard should render properly',
      );

      WidgetTestUtils.verifyWidgetState(
        find.text('Growth Reflection'),
        customMessage: 'Template title should be displayed',
      );

      WidgetTestUtils.verifyWidgetState(
        find.text('This is a test insight about personal growth and development.'),
        customMessage: 'Generated insight text should be displayed',
      );
    });

    testWidgets('should render empty when no insights provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final cardFinder = find.byType(TemplatedInsightCard);
      final sizedBoxFinder = find.byType(SizedBox);
      
      expect(cardFinder, findsOneWidget, reason: 'TemplatedInsightCard widget should be present');
      expect(sizedBoxFinder, findsWidgets, reason: 'SizedBox should be rendered for empty state');
    });

    testWidgets('should handle tap interactions', (WidgetTester tester) async {
      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: testInsights,
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(tapCalled, isTrue, reason: 'onTap callback should be called');
    });

    testWidgets('should handle long press interactions', (WidgetTester tester) async {
      bool longPressCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: testInsights,
              onLongPress: () => longPressCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPress(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(longPressCalled, isTrue, reason: 'onLongPress callback should be called');
    });

    testWidgets('should display multiple insights with page view', (WidgetTester tester) async {
      final multipleInsights = [
        TemplateSelection(
          template: testTemplate,
          generatedInsight: 'First insight about growth.',
          score: 8.5,
        ),
        TemplateSelection(
          template: testTemplate.copyWith(title: 'Second Template'),
          generatedInsight: 'Second insight about development.',
          score: 7.8,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: multipleInsights,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.byType(PageView),
        customMessage: 'PageView should be present for multiple insights',
      );

      WidgetTestUtils.verifyWidgetState(
        find.text('First insight about growth.'),
        customMessage: 'First insight should be displayed initially',
      );
    });

    testWidgets('should show page indicators for multiple insights', (WidgetTester tester) async {
      final multipleInsights = [
        testInsights[0],
        TemplateSelection(
          template: testTemplate,
          generatedInsight: 'Second insight',
          score: 7.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: multipleInsights,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final pageIndicators = find.byWidgetPredicate(
        (widget) => widget is AnimatedContainer,
      );

      expect(pageIndicators, findsWidgets, reason: 'Page indicators should be present for multiple insights');
    });

    testWidgets('should handle page changes', (WidgetTester tester) async {
      int pageChangedIndex = -1;
      final multipleInsights = [
        testInsights[0],
        TemplateSelection(
          template: testTemplate,
          generatedInsight: 'Second insight',
          score: 7.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: multipleInsights,
              onPageChanged: (index) => pageChangedIndex = index,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      pageView.controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await tester.pumpAndSettle();

      expect(pageChangedIndex, equals(1), reason: 'onPageChanged should be called with correct index');
    });

    testWidgets('should display template category and emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: testInsights,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.text('🌱'),
        customMessage: 'Category emoji should be displayed',
      );

      WidgetTestUtils.verifyWidgetState(
        find.text('GROWTH'),
        customMessage: 'Category name should be displayed in uppercase',
      );
    });

    testWidgets('should display insight score', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: testInsights,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.text('Score: 8.5'),
        customMessage: 'Insight score should be displayed',
      );
    });

    testWidgets('should display template tags', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: testInsights,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.text('growth'),
        customMessage: 'Template tags should be displayed',
      );
    });

    testWidgets('should show interaction hints initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: testInsights,
            ),
          ),
        ),
      );

      await tester.pump();

      final hintsFinder = find.byIcon(Icons.touch_app_rounded);
      expect(hintsFinder, findsOneWidget, reason: 'Interaction hints should be shown initially');
    });

    testWidgets('should handle high priority templates', (WidgetTester tester) async {
      final highPriorityTemplate = testTemplate.copyWith(
        priority: TemplatePriority.high,
      );
      
      final highPriorityInsights = [
        TemplateSelection(
          template: highPriorityTemplate,
          generatedInsight: 'High priority insight',
          score: 9.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: highPriorityInsights,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.text('★'),
        customMessage: 'High priority indicator should be displayed',
      );
    });

    testWidgets('should handle critical priority templates', (WidgetTester tester) async {
      final criticalTemplate = testTemplate.copyWith(
        priority: TemplatePriority.critical,
      );
      
      final criticalInsights = [
        TemplateSelection(
          template: criticalTemplate,
          generatedInsight: 'Critical insight',
          score: 9.5,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: criticalInsights,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.text('!'),
        customMessage: 'Critical priority indicator should be displayed',
      );
    });

    testWidgets('should work in both light and dark themes', (WidgetTester tester) async {
      await WidgetTestUtils.runThemeTest(
        tester,
        TemplatedInsightCard(insights: testInsights),
        testDescription: 'TemplatedInsightCard',
        commonTest: (tester, themeMode) async {
          final themeDescription = themeMode == ThemeMode.light ? 'light' : 'dark';
          
          WidgetTestUtils.verifyWidgetState(
            find.byType(TemplatedInsightCard),
            customMessage: 'TemplatedInsightCard should render correctly in $themeDescription theme',
          );
          
          WidgetTestUtils.verifyWidgetState(
            find.text('Growth Reflection'),
            customMessage: 'Template title should be visible in $themeDescription theme',
          );
        },
      );
    });

    testWidgets('should handle different animation types', (WidgetTester tester) async {
      final animationTypes = [
        AnimationType.slideUp,
        AnimationType.fadeIn,
        AnimationType.bounce,
        AnimationType.scaleIn,
      ];

      for (final animationType in animationTypes) {
        final template = testTemplate.copyWith(animationType: animationType);
        final insights = [
          TemplateSelection(
            template: template,
            generatedInsight: 'Test insight with ${animationType.toString()} animation',
            score: 8.0,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TemplatedInsightCard(
                insights: insights,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        WidgetTestUtils.verifyWidgetState(
          find.byType(TemplatedInsightCard),
          customMessage: 'TemplatedInsightCard should handle ${animationType.toString()} animation',
        );
      }
    });

    testWidgets('should handle custom height and margin', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplatedInsightCard(
              insights: testInsights,
              height: 350,
              margin: const EdgeInsets.all(20),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TemplatedInsightCard),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.margin, equals(const EdgeInsets.all(20)), reason: 'Custom margin should be applied');
    });
  });
}