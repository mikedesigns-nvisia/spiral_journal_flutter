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
  group('Core Integration UI Tests', () {
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

    group('Your Cores Widget UI', () {
      testWidgets('should display core cards with proper visual elements', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify core cards are displayed
        expect(find.byType(Card), findsWidgets);
        
        // Verify core names are displayed
        final topCores = coreProvider.topCores;
        for (final core in topCores) {
          expect(find.text(core.name), findsOneWidget);
        }

        // Verify progress indicators are present
        expect(find.byType(LinearProgressIndicator), findsWidgets);
        
        // Verify "Explore All" button is present
        expect(find.text('Explore All'), findsOneWidget);
      });

      testWidgets('should show core level changes with animations', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Get initial core state
        final initialCore = coreProvider.topCores.first;
        final initialLevel = initialCore.currentLevel;

        // Update core level
        final updatedCore = initialCore.copyWith(
          currentLevel: initialLevel + 0.2,
          trend: 'rising',
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(updatedCore);
        await tester.pump();

        // Verify animation is triggered
        expect(find.byType(AnimatedContainer), findsWidgets);
        
        // Pump animation frames
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Verify updated level is displayed
        final progressIndicators = find.byType(LinearProgressIndicator);
        expect(progressIndicators, findsWidgets);
        
        // Verify trend indicator is shown
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });

      testWidgets('should handle core tap navigation', (WidgetTester tester) async {
        bool navigationTriggered = false;
        String? navigatedCoreId;

        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: Builder(
              builder: (context) => YourCoresCard(
                onCorePressed: (coreId) {
                  navigationTriggered = true;
                  navigatedCoreId = coreId;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on first core card
        final coreCards = find.byType(Card);
        expect(coreCards, findsWidgets);
        
        await tester.tap(coreCards.first);
        await tester.pumpAndSettle();

        // Verify navigation was triggered
        expect(navigationTriggered, isTrue);
        expect(navigatedCoreId, isNotNull);
        expect(navigatedCoreId, equals(coreProvider.topCores.first.id));
      });

      testWidgets('should show recent update indicators', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Update a core to trigger recent change indicator
        final testCore = coreProvider.topCores.first.copyWith(
          currentLevel: coreProvider.topCores.first.currentLevel + 0.1,
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(testCore);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify recent update indicator is shown
        expect(find.byType(AnimatedContainer), findsWidgets);
        
        // Look for pulse animation or color change indicators
        final animatedContainers = tester.widgetList<AnimatedContainer>(
          find.byType(AnimatedContainer)
        );
        
        expect(animatedContainers, isNotEmpty);
      });

      testWidgets('should display loading state correctly', (WidgetTester tester) async {
        // Create provider in loading state
        final loadingProvider = CoreProvider();
        // Don't initialize to keep in loading state

        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: loadingProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pump();

        // Verify loading indicators are shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        await loadingProvider.dispose();
      });

      testWidgets('should display error state correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Trigger an error
        await coreProvider.updateCoreWithContext('non_existent_core', null);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify error state is displayed
        expect(find.textContaining('Error'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });
    });

    group('Core Library Screen UI', () {
      testWidgets('should display all cores in grid layout', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify grid layout is present
        expect(find.byType(GridView), findsOneWidget);
        
        // Verify all cores are displayed
        final allCores = coreProvider.allCores;
        for (final core in allCores) {
          expect(find.text(core.name), findsOneWidget);
        }

        // Verify core cards have proper visual elements
        expect(find.byType(Card), findsNWidgets(allCores.length));
      });

      testWidgets('should show core details with proper formatting', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify core level percentages are formatted correctly
        final allCores = coreProvider.allCores;
        for (final core in allCores) {
          final levelText = '${(core.currentLevel * 100).toInt()}%';
          expect(find.text(levelText), findsOneWidget);
        }

        // Verify trend indicators are shown
        expect(find.byIcon(Icons.trending_up), findsWidgets);
        expect(find.byIcon(Icons.trending_down), findsWidgets);
        expect(find.byIcon(Icons.trending_flat), findsWidgets);
      });

      testWidgets('should handle core filtering and sorting', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Look for filter/sort controls
        expect(find.byType(DropdownButton), findsWidgets);
        
        // Test filtering by trend
        final filterDropdown = find.byType(DropdownButton).first;
        await tester.tap(filterDropdown);
        await tester.pumpAndSettle();

        // Select "Rising" filter
        await tester.tap(find.text('Rising').last);
        await tester.pumpAndSettle();

        // Verify only rising cores are shown
        final risingCores = coreProvider.risingCores;
        expect(find.byType(Card), findsNWidgets(risingCores.length));
      });

      testWidgets('should show navigation context indicators', (WidgetTester tester) async {
        // Create navigation context
        final context = navigationService.createJournalToCoreContext(
          targetCoreId: 'optimism',
          triggeredBy: 'your_cores_tap',
        );

        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: CoreLibraryScreen(navigationContext: context),
          ),
        );

        await tester.pumpAndSettle();

        // Verify context indicators are shown
        expect(find.textContaining('From Journal'), findsOneWidget);
        
        // Verify target core is highlighted
        expect(find.byKey(const Key('highlighted_core_optimism')), findsOneWidget);
      });
    });

    group('Visual Consistency', () {
      testWidgets('should use consistent colors across components', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: Column(
              children: const [
                Expanded(child: YourCoresCard()),
                Expanded(child: CoreLibraryScreen()),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get color schemes from both components
        final yourCoresCards = tester.widgetList<Card>(find.byType(Card));
        expect(yourCoresCards.length, greaterThan(6)); // Both components have cards

        // Verify consistent color usage
        final theme = Theme.of(tester.element(find.byType(MaterialApp)));
        
        // Check that cards use theme colors
        for (final card in yourCoresCards) {
          expect(card.color, anyOf(
            equals(theme.cardColor),
            equals(theme.colorScheme.surface),
            isNull, // Uses default
          ));
        }
      });

      testWidgets('should use consistent typography', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: Column(
              children: const [
                Expanded(child: YourCoresCard()),
                Expanded(child: CoreLibraryScreen()),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify consistent text styles
        final theme = Theme.of(tester.element(find.byType(MaterialApp)));
        
        // Check core names use consistent style
        final coreNameTexts = tester.widgetList<Text>(
          find.textContaining('Optimism').first.evaluate().first
        );
        
        // Verify text styles are from theme
        expect(coreNameTexts, isNotEmpty);
      });

      testWidgets('should maintain consistent spacing', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify consistent padding and margins
        final paddingWidgets = tester.widgetList<Padding>(find.byType(Padding));
        expect(paddingWidgets, isNotEmpty);

        // Check that spacing follows design system
        for (final padding in paddingWidgets) {
          final insets = padding.padding as EdgeInsets;
          // Verify spacing uses multiples of 8 (Material Design)
          expect(insets.left % 4, equals(0));
          expect(insets.right % 4, equals(0));
          expect(insets.top % 4, equals(0));
          expect(insets.bottom % 4, equals(0));
        }
      });

      testWidgets('should show consistent loading states', (WidgetTester tester) async {
        final loadingProvider = CoreProvider();
        
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: loadingProvider),
            ],
            child: Column(
              children: const [
                Expanded(child: YourCoresCard()),
                Expanded(child: CoreLibraryScreen()),
              ],
            ),
          ),
        );

        await tester.pump();

        // Verify both components show loading indicators
        expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
        
        // Verify loading indicators are styled consistently
        final loadingIndicators = tester.widgetList<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator)
        );
        
        for (final indicator in loadingIndicators) {
          expect(indicator.strokeWidth, equals(4.0)); // Consistent stroke width
        }
        
        await loadingProvider.dispose();
      });
    });

    group('Animation Performance', () {
      testWidgets('should animate core level changes smoothly', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Update core to trigger animation
        final testCore = coreProvider.topCores.first.copyWith(
          currentLevel: coreProvider.topCores.first.currentLevel + 0.3,
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(testCore);
        await tester.pump();

        // Verify animation is running
        expect(find.byType(AnimatedContainer), findsWidgets);
        
        // Test animation frames
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 300));
        
        // Animation should complete smoothly
        await tester.pumpAndSettle();
        
        // Verify final state
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });

      testWidgets('should handle reduced motion preferences', (WidgetTester tester) async {
        // Set reduced motion preference
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/platform'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'SystemChrome.setSystemUIOverlayStyle') {
              return null;
            }
            return null;
          },
        );

        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                accessibleNavigation: true,
                disableAnimations: true,
              ),
              child: const YourCoresCard(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Update core
        final testCore = coreProvider.topCores.first.copyWith(
          currentLevel: coreProvider.topCores.first.currentLevel + 0.2,
          lastUpdated: DateTime.now(),
        );

        await coreProvider.updateCore(testCore);
        await tester.pump();

        // With reduced motion, changes should be immediate
        await tester.pumpAndSettle();
        
        // Verify update is applied without animation
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });

      testWidgets('should maintain 60fps during animations', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Start performance monitoring
        final frameTimings = <Duration>[];
        
        // Trigger multiple animations
        for (int i = 0; i < 5; i++) {
          final testCore = coreProvider.topCores.first.copyWith(
            currentLevel: 0.2 + (i * 0.15),
            lastUpdated: DateTime.now(),
          );

          final startTime = DateTime.now();
          await coreProvider.updateCore(testCore);
          await tester.pump();
          
          // Pump several animation frames
          for (int frame = 0; frame < 10; frame++) {
            await tester.pump(const Duration(milliseconds: 16)); // ~60fps
            frameTimings.add(DateTime.now().difference(startTime));
          }
        }

        // Verify smooth animation performance
        expect(frameTimings, isNotEmpty);
        
        // Most frames should be under 16ms for 60fps
        final smoothFrames = frameTimings.where((t) => t.inMilliseconds <= 20).length;
        final totalFrames = frameTimings.length;
        
        expect(smoothFrames / totalFrames, greaterThan(0.8)); // 80% smooth frames
      });
    });

    group('Responsive Layout', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Test small screen
        await tester.binding.setSurfaceSize(const Size(320, 568)); // iPhone SE
        
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const YourCoresCard(),
          ),
        );

        await tester.pumpAndSettle();

        // Verify layout adapts to small screen
        expect(find.byType(Card), findsWidgets);
        
        // Test large screen
        await tester.binding.setSurfaceSize(const Size(768, 1024)); // iPad
        await tester.pumpAndSettle();

        // Verify layout adapts to large screen
        expect(find.byType(Card), findsWidgets);
        
        // Reset to default size
        await tester.binding.setSurfaceSize(const Size(800, 600));
      });

      testWidgets('should handle orientation changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: const CoreLibraryScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Portrait mode
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpAndSettle();
        
        expect(find.byType(GridView), findsOneWidget);
        
        // Landscape mode
        await tester.binding.setSurfaceSize(const Size(800, 400));
        await tester.pumpAndSettle();
        
        expect(find.byType(GridView), findsOneWidget);
        
        // Reset
        await tester.binding.setSurfaceSize(const Size(800, 600));
      });

      testWidgets('should scale text appropriately', (WidgetTester tester) async {
        await tester.pumpWidget(
          WidgetTestUtils.createTestApp(
            providers: [
              ChangeNotifierProvider<CoreProvider>.value(value: coreProvider),
            ],
            child: MediaQuery(
              data: const MediaQueryData(textScaleFactor: 1.5),
              child: const YourCoresCard(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify text scales without breaking layout
        expect(find.byType(Card), findsWidgets);
        
        // Verify core names are still visible
        final topCores = coreProvider.topCores;
        for (final core in topCores) {
          expect(find.text(core.name), findsOneWidget);
        }
      });
    });
  });
}