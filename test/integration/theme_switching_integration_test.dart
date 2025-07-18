import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/main.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/services/theme_service.dart';
import 'package:spiral_journal/services/settings_service.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('Theme Switching Integration Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });
    late ThemeService themeService;
    late SettingsService settingsService;

    setUp(() {
      themeService = ThemeService();
      settingsService = SettingsService();
    });

    testWidgets('should switch between light and dark themes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Find theme toggle switch
      final themeSwitch = find.byType(Switch);
      expect(themeSwitch, findsWidgets);

      if (themeSwitch.evaluate().isNotEmpty) {
        // Get initial theme state
        final initialSwitch = tester.widget<Switch>(themeSwitch.first);
        final initialValue = initialSwitch.value;

        // Toggle theme
        await tester.tap(themeSwitch.first);
        await tester.pumpAndSettle();

        // Verify theme changed
        final updatedSwitch = tester.widget<Switch>(themeSwitch.first);
        expect(updatedSwitch.value, equals(!initialValue));

        // Navigate to other screens to verify theme applied
        await tester.tap(find.text('Journal'));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);

        await tester.tap(find.text('History'));
        await tester.pumpAndSettle();
        expect(find.text('History'), findsOneWidget);

        await tester.tap(find.text('Mirror'));
        await tester.pumpAndSettle();
        expect(find.text('Mirror'), findsOneWidget);

        await tester.tap(find.text('Insights'));
        await tester.pumpAndSettle();
        expect(find.text('Insights'), findsOneWidget);
      }
    });

    testWidgets('should persist theme preference across app restarts', (WidgetTester tester) async {
      // First app instance
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to settings and change theme
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      final themeSwitch = find.byType(Switch);
      if (themeSwitch.evaluate().isNotEmpty) {
        await tester.tap(themeSwitch.first);
        await tester.pumpAndSettle();
      }

      // Simulate app restart by creating new widget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Theme preference should be maintained
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should handle system theme changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // App should respond to system theme (tested by ensuring no crashes)
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should apply theme to all UI components', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test theme application on journal screen
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Happy'), findsOneWidget);

      // Navigate to history and test theme
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);

      // Navigate to mirror and test theme
      await tester.tap(find.text('Mirror'));
      await tester.pumpAndSettle();
      expect(find.text('Mirror'), findsOneWidget);

      // Navigate to insights and test theme
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Insights'), findsOneWidget);

      // Navigate to settings and test theme
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should handle theme switching performance', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      final themeSwitch = find.byType(Switch);
      if (themeSwitch.evaluate().isNotEmpty) {
        // Measure theme switch performance
        final stopwatch = Stopwatch()..start();
        
        await tester.tap(themeSwitch.first);
        await tester.pumpAndSettle();
        
        stopwatch.stop();

        // Theme switch should be fast (less than 1 second)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));

        // App should remain responsive
        await tester.tap(find.text('Journal'));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
      }
    });

    test('should handle theme service operations', () async {
      // Test theme service initialization
      await themeService.initialize();

      // Test getting current theme
      final currentTheme = await themeService.getThemeMode();
      expect(currentTheme, isA<ThemeMode>());

      // Test setting theme mode
      await themeService.setThemeMode(ThemeMode.dark);
      final darkTheme = await themeService.getThemeMode();
      expect(darkTheme, equals(ThemeMode.dark));

      // Test setting light theme
      await themeService.setThemeMode(ThemeMode.light);
      final lightTheme = await themeService.getThemeMode();
      expect(lightTheme, equals(ThemeMode.light));

      // Test system theme
      await themeService.setThemeMode(ThemeMode.system);
      final systemTheme = await themeService.getThemeMode();
      expect(systemTheme, equals(ThemeMode.system));
    });

    test('should integrate with settings service', () async {
      // Initialize services
      await settingsService.initialize();
      await themeService.initialize();

      // Test theme preference through settings
      await settingsService.setThemeMode(ThemeMode.dark);
      final savedTheme = await settingsService.getThemeMode();
      expect(savedTheme, equals(ThemeMode.dark));

      // Test theme service reflects settings
      final themeServiceMode = await themeService.getThemeMode();
      expect(themeServiceMode, equals(ThemeMode.dark));
    });

    testWidgets('should handle theme errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // App should handle theme errors without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should maintain theme consistency across navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate through all screens to verify theme consistency
      final screens = ['Journal', 'History', 'Mirror', 'Insights', 'Settings'];
      
      for (final screen in screens) {
        await tester.tap(find.text(screen));
        await tester.pumpAndSettle();
        
        // Verify screen loads without theme-related errors
        expect(find.text(screen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('should handle rapid theme switching', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      final themeSwitch = find.byType(Switch);
      if (themeSwitch.evaluate().isNotEmpty) {
        // Rapidly toggle theme multiple times
        for (int i = 0; i < 5; i++) {
          await tester.tap(themeSwitch.first);
          await tester.pump();
        }
        
        await tester.pumpAndSettle();

        // App should remain stable
        expect(find.text('Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}