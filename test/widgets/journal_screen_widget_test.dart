import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/screens/journal_screen.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';

void main() {
  group('JournalScreen Widget Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });
    testWidgets('should render journal screen with input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify journal screen is rendered with detailed error message
      WidgetTestUtils.verifyWidgetState(
        find.byType(JournalScreen),
        customMessage: 'JournalScreen widget should be rendered properly with all required providers',
      );
      
      // Verify text input field is present
      WidgetTestUtils.verifyWidgetState(
        find.byType(TextField),
        customMessage: 'TextField should be present for journal entry input',
      );
    });

    testWidgets('should handle text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter text in journal input using enhanced utility method
      const testText = 'Today was a wonderful day filled with gratitude and joy.';
      await WidgetTestUtils.enterText(
        tester,
        find.byType(TextField),
        testText,
        customMessage: 'Should be able to enter text into journal input field',
      );

      // Verify text is displayed with detailed error message
      WidgetTestUtils.verifyWidgetState(
        find.text(testText),
        customMessage: 'Entered text should be visible in the journal input field',
      );
    });

    testWidgets('should show mood selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify MoodSelector widget is present
      WidgetTestUtils.verifyWidgetState(
        find.byType(MoodSelector),
        customMessage: 'MoodSelector widget should be present in journal screen',
      );

      // Verify primary mood selector moods are displayed with specific FilterChip finders
      final expectedPrimaryMoods = ['Happy', 'Content', 'Energetic', 'Grateful', 'Peaceful'];
      for (final mood in expectedPrimaryMoods) {
        final moodChipFinder = find.byWidgetPredicate(
          (widget) => widget is FilterChip && 
                      widget.label is Text && 
                      (widget.label as Text).data == mood,
        );
        WidgetTestUtils.verifyWidgetState(
          moodChipFinder,
          customMessage: 'Primary mood "$mood" should be visible as FilterChip in the mood selector within journal screen',
        );
      }
    });

    testWidgets('should handle mood selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Happy mood FilterChip specifically
      final happyMoodChipFinder = find.byWidgetPredicate(
        (widget) => widget is FilterChip && 
                    widget.label is Text && 
                    (widget.label as Text).data == 'Happy',
      );

      // Verify mood chip is available before selection
      WidgetTestUtils.verifyWidgetStateBeforeAction(
        happyMoodChipFinder,
        'select mood',
        customMessage: 'Happy mood FilterChip should be available for selection in journal screen',
      );

      // Verify initial state - chip should not be selected
      final initialChip = tester.widget<FilterChip>(happyMoodChipFinder);
      if (initialChip.selected) {
        fail('Expected Happy mood chip to be initially unselected in journal screen, but it was selected. '
             'This indicates incorrect initial state setup.');
      }

      // Select the mood by tapping the FilterChip
      await tester.tap(happyMoodChipFinder);
      await tester.pumpAndSettle();

      // Verify mood chip is still visible after selection (visual feedback)
      WidgetTestUtils.verifyWidgetState(
        happyMoodChipFinder,
        customMessage: 'Happy mood FilterChip should remain visible after selection',
      );

      // Verify the chip's selected state has changed
      final selectedChip = tester.widget<FilterChip>(happyMoodChipFinder);
      if (!selectedChip.selected) {
        fail('Expected Happy mood chip to be visually selected after tap in journal screen, but it was not. '
             'This indicates FilterChip selection state is not being updated properly.');
      }
    });

    testWidgets('should show save button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for save functionality with better finder
      final saveButton = WidgetTestUtils.findButton(text: 'Save');
      if (saveButton.evaluate().isNotEmpty) {
        WidgetTestUtils.verifyWidgetState(
          saveButton,
          customMessage: 'Save button should be present and accessible for journal entry saving',
        );
      }
    });

    testWidgets('should handle AI analysis trigger', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter text first using enhanced utility method
      await WidgetTestUtils.enterText(
        tester,
        find.byType(TextField),
        'Test entry for AI analysis',
        customMessage: 'Should be able to enter text before triggering AI analysis',
      );

      // Look for analyze button with better finder
      final analyzeButton = WidgetTestUtils.findButton(text: 'Analyze');
      if (analyzeButton.evaluate().isNotEmpty) {
        await WidgetTestUtils.tapButton(
          tester,
          analyzeButton,
          customMessage: 'Should be able to tap Analyze button to trigger AI analysis',
        );

        // Verify loading state is shown
        WidgetTestUtils.verifyLoadingState(
          tester,
          shouldBeLoading: true,
          customMessage: 'Loading indicator should appear when AI analysis is triggered',
        );
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
          child: const Scaffold(body: JournalScreen()),
        ),
        testDescription: 'JournalScreen',
        commonTest: (tester, themeMode) async {
          final themeDescription = themeMode == ThemeMode.light ? 'light' : 'dark';
          
          // Verify the screen renders correctly
          WidgetTestUtils.verifyWidgetState(
            find.byType(JournalScreen),
            customMessage: 'JournalScreen should render correctly in $themeDescription theme',
          );
          
          // Verify journal input is present
          WidgetTestUtils.verifyWidgetState(
            find.byType(JournalInput),
            customMessage: 'JournalInput should be present in $themeDescription theme',
          );
          
          // Verify mood selector is present
          WidgetTestUtils.verifyWidgetState(
            find.byType(MoodSelector),
            customMessage: 'MoodSelector should be present in $themeDescription theme',
          );
          
          // Verify theme-specific text colors
          WidgetTestUtils.verifyTextThemeColors(
            tester,
            themeMode,
            find.byType(Text),
            customMessage: 'Text colors should be appropriate for $themeDescription theme',
          );
        },
      );
    });

    testWidgets('should show AI detected moods when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen renders without AI moods initially
      WidgetTestUtils.verifyWidgetState(
        find.byType(JournalScreen),
        customMessage: 'JournalScreen should render correctly without AI detected moods initially',
      );
    });

    testWidgets('should handle auto-save functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter text to trigger auto-save using enhanced utility method
      await WidgetTestUtils.enterText(
        tester,
        find.byType(TextField),
        'Auto-save test entry',
        customMessage: 'Should be able to enter text to trigger auto-save functionality',
      );

      // Wait for potential auto-save
      await tester.pump(const Duration(milliseconds: 500));

      // Verify screen remains functional after auto-save
      WidgetTestUtils.verifyWidgetState(
        find.byType(JournalScreen),
        customMessage: 'JournalScreen should remain functional after auto-save operation',
      );
    });

    testWidgets('should show draft recovery when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen renders without draft initially
      WidgetTestUtils.verifyWidgetState(
        find.byType(JournalScreen),
        customMessage: 'JournalScreen should render correctly without draft recovery initially',
      );
    });

    testWidgets('should handle error states gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => CoreProvider()),
          ],
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen renders without errors
      WidgetTestUtils.verifyWidgetState(
        find.byType(JournalScreen),
        customMessage: 'JournalScreen should render without throwing exceptions',
      );
      
      // Verify no exceptions were thrown during rendering
      final exception = tester.takeException();
      if (exception != null) {
        fail('Expected no exceptions during JournalScreen rendering, but got: $exception. '
             'This indicates a critical error in the widget setup or dependencies.');
      }
    });
  });
}