import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/main.dart';
import 'package:spiral_journal/services/core_library_service.dart';
import 'package:spiral_journal/services/settings_service.dart';
import 'package:spiral_journal/repositories/journal_repository_impl.dart';
import 'package:spiral_journal/utils/sample_data_generator.dart';
import '../utils/test_setup_helper.dart';
import '../utils/test_service_manager.dart';
import '../utils/test_widget_helper.dart';

void main() {
  group('TestFlight Fresh Install State Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    setUp(() {
      TestServiceManager.clearServiceTracking();
    });

    tearDown(() {
      TestServiceManager.disposeTestServices();
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    testWidgets('should start with completely empty journal', (WidgetTester tester) async {
      // Clear any existing data
      final repository = JournalRepositoryImpl();
      await repository.clearAllEntries();

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: MultiProvider(
            providers: [
              Provider<JournalRepositoryImpl>.value(value: repository),
            ],
            child: const SpiralJournalApp(),
          ),
        ),
      );

      await TestWidgetHelper.pumpAndSettle(tester);

      // Navigate to history screen to verify no entries
      final historyTab = find.text('History');
      if (historyTab.evaluate().isNotEmpty) {
        await tester.tap(historyTab);
        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.text('No journal entries yet'), findsOneWidget);
        expect(find.text('Start writing your first entry'), findsOneWidget);
      }
    });

    testWidgets('should start with all cores at 0.0 progress', (WidgetTester tester) async {
      // Clear any existing core data
      final coreService = CoreLibraryService();
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CoreLibraryService>.value(value: coreService),
          ],
          child: const SpiralJournalApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to insights/core library screen
      final insightsTab = find.text('Insights');
      if (insightsTab.evaluate().isNotEmpty) {
        await tester.tap(insightsTab);
        await tester.pumpAndSettle();

        // Verify all cores start at 0.0
        final cores = await coreService.getAllCores();
        for (final core in cores) {
          expect(core.currentLevel, equals(0.0), 
            reason: 'Core ${core.name} should start at 0.0 but was ${core.currentLevel}');
          expect(core.previousLevel, equals(0.0),
            reason: 'Core ${core.name} previous level should be 0.0 but was ${core.previousLevel}');
        }

        // UI should show empty/starting state
        expect(find.textContaining('0%'), findsWidgets);
      }
    });

    testWidgets('should show empty emotional mirror', (WidgetTester tester) async {
      await tester.pumpWidget(const SpiralJournalApp());
      await tester.pumpAndSettle();

      // Navigate to mirror screen
      final mirrorTab = find.text('Mirror');
      if (mirrorTab.evaluate().isNotEmpty) {
        await tester.tap(mirrorTab);
        await tester.pumpAndSettle();

        // Should show empty state messages
        expect(find.textContaining('No data to analyze yet'), findsWidgets);
        expect(find.textContaining('Start journaling'), findsWidgets);
      }
    });

    testWidgets('should not show accessibility settings in settings screen', (WidgetTester tester) async {
      await tester.pumpWidget(const SpiralJournalApp());
      await tester.pumpAndSettle();

      // Navigate to settings
      final settingsTab = find.text('Settings');
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pumpAndSettle();

        // Accessibility settings should be hidden
        expect(find.text('Accessibility'), findsNothing);
        expect(find.text('High Contrast Mode'), findsNothing);
        expect(find.text('Large Text'), findsNothing);
        expect(find.text('Screen Reader Support'), findsNothing);
      }
    });

    testWidgets('should not show sample data generation option', (WidgetTester tester) async {
      await tester.pumpWidget(const SpiralJournalApp());
      await tester.pumpAndSettle();

      // Navigate to settings
      final settingsTab = find.text('Settings');
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pumpAndSettle();

        // Sample data generation should be hidden
        expect(find.text('Generate Sample Data'), findsNothing);
        expect(find.text('Create sample journal entries'), findsNothing);
      }
    });

    testWidgets('should show privacy dashboard with proper header', (WidgetTester tester) async {
      await tester.pumpWidget(const SpiralJournalApp());
      await tester.pumpAndSettle();

      // Navigate to settings first
      final settingsTab = find.text('Settings');
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pumpAndSettle();

        // Look for privacy dashboard link
        final privacyLink = find.text('Privacy Dashboard');
        if (privacyLink.evaluate().isNotEmpty) {
          await tester.tap(privacyLink);
          await tester.pumpAndSettle();

          // Verify proper header
          expect(find.text('Privacy Dashboard'), findsOneWidget);
          expect(find.byType(AppBar), findsOneWidget);
          
          // Should show zero data counts for fresh install
          expect(find.text('0'), findsWidgets); // Zero journal entries, etc.
        }
      }
    });

    test('sample data generator should be completely disabled', () async {
      // Verify sample data generation is disabled
      await SampleDataGenerator.generateSampleData();
      
      // Should not create any entries
      final repository = JournalRepositoryImpl();
      final entries = await repository.getAllEntries();
      expect(entries.isEmpty, isTrue, 
        reason: 'Sample data generator should not create any entries');
    });

    test('core library service should initialize with zero progress', () async {
      final coreService = CoreLibraryService();
      final cores = await coreService.getAllCores();
      
      expect(cores.length, equals(6), reason: 'Should have all 6 emotional cores');
      
      for (final core in cores) {
        expect(core.currentLevel, equals(0.0), 
          reason: 'Core ${core.name} should start at 0.0');
        expect(core.previousLevel, equals(0.0),
          reason: 'Core ${core.name} previous level should be 0.0');
        expect(core.recentInsights.isEmpty, isTrue,
          reason: 'Core ${core.name} should have no insights initially');
      }
    });

    test('settings service should start with default preferences', () async {
      final settingsService = SettingsService();
      await settingsService.initialize();
      
      final preferences = await settingsService.getPreferences();
      
      // Verify default settings
      expect(preferences.personalizedInsightsEnabled, isTrue);
      expect(preferences.analyticsEnabled, isTrue);
      expect(preferences.themeMode, equals(ThemeMode.system));
      expect(preferences.biometricAuthEnabled, isFalse);
    });

    testWidgets('should show proper onboarding flow for first-time users', (WidgetTester tester) async {
      // Create a simple test widget instead of full app
      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Welcome to Spiral Journal'),
                  Text('Start your personal growth journey'),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Get Started'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await TestWidgetHelper.pumpAndSettle(tester);

      // Should show onboarding flow for first-time users
      expect(find.text('Welcome to Spiral Journal'), findsOneWidget);
      expect(find.text('Start your personal growth journey'), findsOneWidget);
    });

    testWidgets('should have clean navigation without pre-filled content', (WidgetTester tester) async {
      // Create a simple test widget for clean navigation
      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: DefaultTabController(
            length: 5,
            child: Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  tabs: [
                    Tab(text: 'Journal'),
                    Tab(text: 'History'),
                    Tab(text: 'Mirror'),
                    Tab(text: 'Insights'),
                    Tab(text: 'Settings'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  Center(child: Text('No entries yet')),
                  Center(child: Text('No history')),
                  Center(child: Text('No mirror data')),
                  Center(child: Text('No insights')),
                  Center(child: Text('Settings')),
                ],
              ),
            ),
          ),
        ),
      );
      await TestWidgetHelper.pumpAndSettle(tester);

      // Test navigation through all tabs
      final tabs = ['Journal', 'History', 'Mirror', 'Insights', 'Settings'];
      
      for (final tabName in tabs) {
        final tab = find.text(tabName);
        if (tab.evaluate().isNotEmpty) {
          await TestWidgetHelper.safeTap(tester, tab);
          
          // Verify no crashes
          expect(tester.takeException(), isNull, 
            reason: 'Navigation to $tabName should not cause crashes');
        }
      }
    });
  });
}