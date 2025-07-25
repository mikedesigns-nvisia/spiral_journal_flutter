import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/services/core_navigation_context_service.dart';
import 'package:spiral_journal/widgets/your_cores_card.dart';
import 'package:spiral_journal/screens/core_library_screen.dart';
import 'package:spiral_journal/models/core.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';

void main() {
  group('Core Integration Accessibility Tests', () {
    late TestSetupHelper testHelper;
    late CoreProvider coreProvider;
    late CoreNavigationContextService navigationService;

    setUp(() async {
      testHelper = TestSetupHelper();
      await testHelper.setUp();
      
      SharedPreferences.setMockInitialValues({});
      
      coreProvider = CoreProvider();
      navigationService = CoreNavigationContextService();
      
      await coreProvider.initialize();
    });

    tearDown(() async {
      await coreProvider.dispose();
      navigationService.dispose();
      await testHelper.tearDown();
    });

    group('Screen Reader Compatibility', () {
      testWidgets('should provide proper semantic labels for Your Cores widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify semantic structure
        final semantics = tester.getSemantics(find.byType(YourCoresCard));
        expect(semantics.label, contains('Your Cores'));
        expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);

        // Verify core cards have proper semantics
        final topCores = coreProvider.topCores;
        for (final core in topCores) {
          final coreCardFinder = find.text(core.name);
          expect(coreCardFinder, findsOneWidget);
          
          final coreSemantics = tester.getSemantics(coreCardFinder);
          expect(coreSemantics.label, contains(core.name));
          expect(coreSemantics.value, contains('${(core.currentLevel * 100).toInt()}%'));
        }

        // Verify "Explore All" button has proper semantics
        final exploreAllFinder = find.text('Explore All');
        expect(exploreAllFinder, findsOneWidget);
        
        final exploreAllSemantics = tester.getSemantics(exploreAllFinder);
        expect(exploreAllSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
        expect(exploreAllSemantics.label, equals('Explore All'));
        expect(exploreAllSemantics.hint, contains('Navigate to core library'));
      });

      testWidgets('should announce core level changes', (WidgetTester tester) async {
        final announcements = <String>[];
        
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: Semantics(
              onLiveRegionChanged: (String announcement) {
                announcements.add(announcement);
              },
              child: const YourCoresCard(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Update a core to trigger announcement
        final testCore = coreProvider.topCores.first.copyWith(
          currentLevel: coreProvider.topCores.first.currentLevel + 0.15,
          trend: 'rising',
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(testCore);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify announcement was made
        expect(announcements, isNotEmpty);
        expect(announcements.any((a) => a.contains(testCore.name)), isTrue);
        expect(announcements.any((a) => a.contains('increased')), isTrue);
      });

      testWidgets('should provide context-aware announcements', (WidgetTester tester) async {
        final announcements = <String>[];
        
        // Create navigation context
        final context = navigationService.createJournalToCoreContext(
          targetCoreId: 'optimism',
          triggeredBy: 'journal_analysis',
        );

        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: Semantics(
              onLiveRegionChanged: (String announcement) {
                announcements.add(announcement);
              },
              child: CoreLibraryScreen(navigationContext: context),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify context announcement
        expect(announcements, isNotEmpty);
        expect(announcements.any((a) => a.contains('from journal')), isTrue);
        expect(announcements.any((a) => a.contains('optimism')), isTrue);
      });

      testWidgets('should provide proper semantic descriptions for progress indicators', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Find progress indicators
        final progressIndicators = find.byType(LinearProgressIndicator);
        expect(progressIndicators, findsWidgets);

        // Verify each progress indicator has proper semantics
        for (int i = 0; i < tester.widgetList(progressIndicators).length; i++) {
          final progressFinder = progressIndicators.at(i);
          final progressSemantics = tester.getSemantics(progressFinder);
          
          expect(progressSemantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
          expect(progressSemantics.value, isNotNull);
          expect(progressSemantics.value, matches(RegExp(r'\d+%')));
        }
      });

      testWidgets('should provide semantic descriptions for trend indicators', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find trend icons
        final trendIcons = [
          find.byIcon(Icons.trending_up),
          find.byIcon(Icons.trending_down),
          find.byIcon(Icons.trending_flat),
        ];

        for (final iconFinder in trendIcons) {
          if (tester.any(iconFinder)) {
            final iconSemantics = tester.getSemantics(iconFinder);
            expect(iconSemantics.label, isNotNull);
            expect(iconSemantics.label, anyOf(
              contains('rising'),
              contains('declining'),
              contains('stable'),
            ));
          }
        }
      });

      testWidgets('should handle loading state announcements', (WidgetTester tester) async {
        final announcements = <String>[];
        final loadingProvider = CoreProvider();

        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: loadingProvider),
            ],
            child: Semantics(
              onLiveRegionChanged: (String announcement) {
                announcements.add(announcement);
              },
              child: const YourCoresCard(),
            ),
          ),
        );

        await tester.pump();

        // Verify loading announcement
        expect(announcements, isNotEmpty);
        expect(announcements.any((a) => a.contains('loading')), isTrue);

        await loadingProvider.dispose();
      });

      testWidgets('should handle error state announcements', (WidgetTester tester) async {
        final announcements = <String>[];

        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: Semantics(
              onLiveRegionChanged: (String announcement) {
                announcements.add(announcement);
              },
              child: const YourCoresCard(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Trigger an error
        await coreProvider.updateCoreWithContext('non_existent_core', null);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify error announcement
        expect(announcements, isNotEmpty);
        expect(announcements.any((a) => a.contains('error')), isTrue);
      });
    });

    group('Touch Target Sizes', () {
      testWidgets('should have minimum 44pt touch targets for core cards', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Find all tappable core cards
        final coreCards = find.byType(Card);
        expect(coreCards, findsWidgets);

        // Verify each card meets minimum touch target size
        for (int i = 0; i < tester.widgetList(coreCards).length; i++) {
          final cardFinder = coreCards.at(i);
          final cardSize = tester.getSize(cardFinder);
          
          // Minimum 44pt (44 logical pixels) touch target
          expect(cardSize.width, greaterThanOrEqualTo(44.0));
          expect(cardSize.height, greaterThanOrEqualTo(44.0));
        }
      });

      testWidgets('should have proper spacing between touch targets', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find core cards in grid
        final coreCards = find.byType(Card);
        expect(coreCards, findsWidgets);

        // Verify spacing between cards
        final cardWidgets = tester.widgetList<Card>(coreCards).toList();
        if (cardWidgets.length > 1) {
          final firstCardRect = tester.getRect(coreCards.at(0));
          final secondCardRect = tester.getRect(coreCards.at(1));
          
          // Minimum 8pt spacing between touch targets
          final horizontalSpacing = (secondCardRect.left - firstCardRect.right).abs();
          final verticalSpacing = (secondCardRect.top - firstCardRect.bottom).abs();
          
          expect(horizontalSpacing >= 8.0 || verticalSpacing >= 8.0, isTrue);
        }
      });

      testWidgets('should have accessible button sizes', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Find "Explore All" button
        final exploreAllButton = find.text('Explore All');
        expect(exploreAllButton, findsOneWidget);

        // Verify button size meets accessibility guidelines
        final buttonSize = tester.getSize(exploreAllButton);
        expect(buttonSize.width, greaterThanOrEqualTo(44.0));
        expect(buttonSize.height, greaterThanOrEqualTo(44.0));
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('should support tab navigation through core cards', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Find focusable elements
        final focusableElements = find.byType(InkWell);
        expect(focusableElements, findsWidgets);

        // Test tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Verify focus is on first element
        final firstFocusable = focusableElements.first;
        final firstWidget = tester.widget<InkWell>(firstFocusable);
        expect(firstWidget.focusNode?.hasFocus ?? false, isTrue);

        // Continue tabbing
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Verify focus moved to next element
        final secondFocusable = focusableElements.at(1);
        final secondWidget = tester.widget<InkWell>(secondFocusable);
        expect(secondWidget.focusNode?.hasFocus ?? false, isTrue);
      });

      testWidgets('should support enter key activation', (WidgetTester tester) async {
        bool corePressed = false;
        String? pressedCoreId;

        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: YourCoresCard(
              onCorePressed: (coreId) {
                corePressed = true;
                pressedCoreId = coreId;
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Focus on first core card
        final firstCard = find.byType(InkWell).first;
        await tester.tap(firstCard);
        await tester.pump();

        // Press enter key
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        // Verify activation
        expect(corePressed, isTrue);
        expect(pressedCoreId, isNotNull);
      });

      testWidgets('should support arrow key navigation in grid', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find grid view
        final gridView = find.byType(GridView);
        expect(gridView, findsOneWidget);

        // Focus on grid
        await tester.tap(gridView);
        await tester.pump();

        // Test arrow key navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        // Navigation should work without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should provide keyboard shortcuts for common actions', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Test refresh shortcut (Ctrl+R or Cmd+R)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pump();

        // Should trigger refresh without errors
        expect(tester.takeException(), isNull);
      });
    });

    group('High Contrast Mode', () {
      testWidgets('should maintain visibility in high contrast mode', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                highContrast: true,
                accessibleNavigation: true,
              ),
              child: const YourCoresCard(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify elements are still visible
        expect(find.byType(Card), findsWidgets);
        expect(find.byType(LinearProgressIndicator), findsWidgets);

        // Verify text is readable
        final topCores = coreProvider.topCores;
        for (final core in topCores) {
          expect(find.text(core.name), findsOneWidget);
        }
      });

      testWidgets('should use appropriate contrast ratios', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: MediaQuery(
              data: const MediaQueryData(highContrast: true),
              child: const CoreLibraryScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get theme colors
        final theme = Theme.of(tester.element(find.byType(MaterialApp)));
        
        // Verify high contrast colors are used
        expect(theme.brightness, anyOf(Brightness.light, Brightness.dark));
        
        // Text should have sufficient contrast
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        expect(textWidgets, isNotEmpty);
        
        for (final textWidget in textWidgets) {
          expect(textWidget.style?.color, isNotNull);
        }
      });
    });

    group('Dynamic Type Support', () {
      testWidgets('should scale text appropriately with large text sizes', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: MediaQuery(
              data: const MediaQueryData(textScaleFactor: 2.0),
              child: const YourCoresCard(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify layout doesn't break with large text
        expect(find.byType(Card), findsWidgets);
        
        // Verify text is still readable
        final topCores = coreProvider.topCores;
        for (final core in topCores) {
          expect(find.text(core.name), findsOneWidget);
        }

        // Verify no overflow errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should maintain layout with extra large text', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: MediaQuery(
              data: const MediaQueryData(textScaleFactor: 3.0),
              child: const CoreLibraryScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify grid layout adapts to large text
        expect(find.byType(GridView), findsOneWidget);
        
        // Verify no rendering errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should provide readable text at minimum sizes', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: MediaQuery(
              data: const MediaQueryData(textScaleFactor: 0.8),
              child: const YourCoresCard(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify text is still readable at small sizes
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        expect(textWidgets, isNotEmpty);

        for (final textWidget in textWidgets) {
          final fontSize = textWidget.style?.fontSize ?? 14.0;
          final scaledSize = fontSize * 0.8;
          
          // Minimum readable size should be maintained
          expect(scaledSize, greaterThanOrEqualTo(10.0));
        }
      });
    });

    group('Motor Accessibility', () {
      testWidgets('should support switch control navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: MediaQuery(
              data: const MediaQueryData(accessibleNavigation: true),
              child: const YourCoresCard(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify elements are focusable for switch control
        final focusableElements = find.byType(InkWell);
        expect(focusableElements, findsWidgets);

        // Verify semantic properties for switch control
        for (int i = 0; i < tester.widgetList(focusableElements).length; i++) {
          final elementFinder = focusableElements.at(i);
          final semantics = tester.getSemantics(elementFinder);
          
          expect(semantics.hasFlag(SemanticsFlag.isFocusable), isTrue);
          expect(semantics.hasAction(SemanticsAction.tap), isTrue);
        }
      });

      testWidgets('should provide alternative interaction methods', (WidgetTester tester) async {
        bool longPressTriggered = false;

        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: GestureDetector(
              onLongPress: () {
                longPressTriggered = true;
              },
              child: const YourCoresCard(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test long press as alternative to tap
        final firstCard = find.byType(Card).first;
        await tester.longPress(firstCard);
        await tester.pump();

        expect(longPressTriggered, isTrue);
      });

      testWidgets('should have generous touch targets for motor difficulties', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify touch targets are generous (larger than minimum)
        final coreCards = find.byType(Card);
        expect(coreCards, findsWidgets);

        for (int i = 0; i < tester.widgetList(coreCards).length; i++) {
          final cardFinder = coreCards.at(i);
          final cardSize = tester.getSize(cardFinder);
          
          // Generous touch targets (60pt+) for motor accessibility
          expect(cardSize.width, greaterThanOrEqualTo(60.0));
          expect(cardSize.height, greaterThanOrEqualTo(60.0));
        }
      });
    });

    group('Voice Control Compatibility', () {
      testWidgets('should provide voice control labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify elements have voice control labels
        final topCores = coreProvider.topCores;
        for (final core in topCores) {
          final coreCardFinder = find.text(core.name);
          expect(coreCardFinder, findsOneWidget);
          
          final semantics = tester.getSemantics(coreCardFinder);
          expect(semantics.label, isNotNull);
          expect(semantics.label, isNotEmpty);
        }

        // Verify "Explore All" button has voice label
        final exploreAllFinder = find.text('Explore All');
        final exploreAllSemantics = tester.getSemantics(exploreAllFinder);
        expect(exploreAllSemantics.label, equals('Explore All'));
      });

      testWidgets('should support voice commands for navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify semantic actions are available for voice control
        final coreCards = find.byType(Card);
        expect(coreCards, findsWidgets);

        for (int i = 0; i < tester.widgetList(coreCards).length; i++) {
          final cardFinder = coreCards.at(i);
          final semantics = tester.getSemantics(cardFinder);
          
          expect(semantics.hasAction(SemanticsAction.tap), isTrue);
          expect(semantics.label, isNotNull);
        }
      });
    });
  });
}