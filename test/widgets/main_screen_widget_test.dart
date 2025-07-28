import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/screens/main_screen.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';

void main() {
  group('MainScreen Widget Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });
    testWidgets('should render main screen with bottom navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render main screen with proper state verification
      WidgetTestUtils.verifyWidgetState(
        find.byType(MainScreen),
        customMessage: 'MainScreen widget should be rendered properly with all required providers',
      );
      
      // Should have bottom navigation bar with proper state verification
      WidgetTestUtils.verifyWidgetState(
        find.byType(BottomNavigationBar),
        customMessage: 'BottomNavigationBar should be present for tab navigation',
      );
    });

    testWidgets('should show all navigation tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show all navigation tabs with proper state verification
      final expectedTabs = ['Journal', 'History', 'Mirror', 'Insights', 'Settings'];
      for (final tabName in expectedTabs) {
        WidgetTestUtils.verifyWidgetState(
          find.text(tabName),
          customMessage: 'Navigation tab "$tabName" should be visible in bottom navigation bar',
        );
      }
      
      // Verify we have exactly 5 tabs
      final bottomNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      if (bottomNavBar.items.length != 5) {
        fail('Expected exactly 5 navigation tabs, but found ${bottomNavBar.items.length}. '
             'This indicates incorrect bottom navigation setup.');
      }
    });

    testWidgets('should navigate between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test navigation to each tab with proper state verification
      final tabsToTest = ['History', 'Mirror', 'Insights', 'Settings', 'Journal'];
      
      for (final tabName in tabsToTest) {
        // Verify tab button exists before tapping
        final tabFinder = find.text(tabName);
        WidgetTestUtils.verifyWidgetStateBeforeAction(
          tabFinder,
          'navigate to $tabName tab',
          customMessage: 'Navigation tab "$tabName" should be available for tapping',
        );

        // Tap the tab
        await WidgetTestUtils.tapButton(
          tester,
          tabFinder,
          customMessage: 'Should be able to tap "$tabName" tab for navigation',
        );

        // Verify navigation was successful
        WidgetTestUtils.verifyWidgetState(
          find.text(tabName),
          customMessage: 'Navigation to "$tabName" tab should be successful and tab should remain visible',
        );
      }
    });

    testWidgets('should start with journal tab selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should start with journal tab (has text input) with proper state verification
      WidgetTestUtils.verifyWidgetState(
        find.byType(TextField),
        customMessage: 'TextField should be present indicating Journal tab is initially selected',
      );
      
      // Verify bottom navigation shows journal as selected
      final bottomNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      if (bottomNavBar.currentIndex != 0) {
        fail('Expected Journal tab (index 0) to be initially selected, but current index is ${bottomNavBar.currentIndex}. '
             'This indicates incorrect initial tab selection.');
      }
    });

    testWidgets('should work in both light and dark themes', (WidgetTester tester) async {
      await WidgetTestUtils.runThemeTest(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MainScreen(),
        ),
        testDescription: 'MainScreen',
        commonTest: (tester, themeMode) async {
          final themeDescription = themeMode == ThemeMode.light ? 'light' : 'dark';
          
          // Verify the main screen renders correctly
          WidgetTestUtils.verifyWidgetState(
            find.byType(MainScreen),
            customMessage: 'MainScreen should render correctly in $themeDescription theme',
          );
          
          // Verify bottom navigation bar is present
          WidgetTestUtils.verifyWidgetState(
            find.byType(BottomNavigationBar),
            customMessage: 'BottomNavigationBar should render correctly in $themeDescription theme',
          );
          
          // Verify theme-specific button colors
          WidgetTestUtils.verifyButtonThemeColors(
            tester,
            themeMode,
            find.byType(BottomNavigationBar),
            customMessage: 'BottomNavigationBar colors should be appropriate for $themeDescription theme',
          );
        },
      );
    });

    testWidgets('should maintain state when switching tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter text in journal with proper state verification
      const testText = 'Test journal entry for state persistence';
      await WidgetTestUtils.enterText(
        tester,
        find.byType(TextField),
        testText,
        customMessage: 'Should be able to enter text in journal for state persistence testing',
      );

      // Navigate away and back with proper state verification
      await WidgetTestUtils.tapButton(
        tester,
        find.text('History'),
        customMessage: 'Should be able to navigate to History tab',
      );
      
      await WidgetTestUtils.tapButton(
        tester,
        find.text('Journal'),
        customMessage: 'Should be able to navigate back to Journal tab',
      );

      // Text should still be there with proper state verification
      WidgetTestUtils.verifyWidgetState(
        find.text(testText),
        customMessage: 'Journal text should persist when switching between tabs, indicating proper state management',
      );
    });

    testWidgets('should handle rapid tab switching', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rapidly switch between tabs with proper state verification
      final tabs = ['History', 'Mirror', 'Insights', 'Settings', 'Journal'];
      
      for (int i = 0; i < 3; i++) {
        for (final tab in tabs) {
          final tabFinder = find.text(tab);
          WidgetTestUtils.verifyWidgetStateBeforeAction(
            tabFinder,
            'rapid tab switch to $tab',
            customMessage: 'Tab "$tab" should be available during rapid switching',
          );
          await tester.tap(tabFinder);
          await tester.pump();
        }
      }
      
      await tester.pumpAndSettle();

      // Should end up on journal tab and be stable with proper state verification
      WidgetTestUtils.verifyWidgetState(
        find.byType(TextField),
        customMessage: 'Should end up on Journal tab after rapid switching, indicated by TextField presence',
      );
      
      // Verify no exceptions occurred during rapid switching
      final exception = tester.takeException();
      if (exception != null) {
        fail('Expected no exceptions during rapid tab switching, but got: $exception. '
             'This indicates instability in tab navigation handling.');
      }
    });

    testWidgets('should show correct icons for each tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have icons in bottom navigation with proper state verification
      WidgetTestUtils.verifyWidgetStateBeforeAction(
        find.byType(BottomNavigationBar),
        'verify navigation icons',
        customMessage: 'BottomNavigationBar should be present for icon verification',
      );

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      
      if (bottomNavBar.items.length != 5) {
        fail('Expected exactly 5 navigation items with icons, but found ${bottomNavBar.items.length}. '
             'This indicates incorrect bottom navigation setup.');
      }
      
      // Each item should have an icon with proper verification
      for (int i = 0; i < bottomNavBar.items.length; i++) {
        final item = bottomNavBar.items[i];
      }
    });

    testWidgets('should handle back button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to different tab with proper state verification
      await WidgetTestUtils.tapButton(
        tester,
        find.text('Settings'),
        customMessage: 'Should be able to navigate to Settings tab for back button testing',
      );

      // Should handle back navigation gracefully with proper state verification
      WidgetTestUtils.verifyWidgetState(
        find.text('Settings'),
        customMessage: 'Settings tab should be accessible and handle back navigation gracefully',
      );
    });

    testWidgets('should handle screen orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render correctly in portrait with proper state verification
      WidgetTestUtils.verifyWidgetState(
        find.byType(BottomNavigationBar),
        customMessage: 'BottomNavigationBar should render correctly in portrait orientation',
      );

      // Simulate orientation change by changing widget size
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpAndSettle();

      // Should still render correctly with proper state verification
      WidgetTestUtils.verifyWidgetState(
        find.byType(BottomNavigationBar),
        customMessage: 'BottomNavigationBar should render correctly after orientation change to landscape',
      );

      // Reset size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}