import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/journal_input.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';
import '../utils/test_diagnostics_helper.dart';

void main() {
  group('JournalInput Widget Tests', () {
    setUpAll(() {
      // Ensure Flutter binding is initialized properly
      TestSetupHelper.ensureFlutterBindingWithDiagnostics();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    testWidgets('should render journal input with placeholder text', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      // Use the improved widget test utilities for pumping with theme
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: JournalInput(
            controller: controller,
            onChanged: (text) {},
            onSave: () {},
          ),
        ),
      );

      // Use the improved verification methods with better error messages
      WidgetTestUtils.verifyWidgetState(
        find.byType(JournalInput),
        customMessage: 'JournalInput widget should be rendered and visible',
      );

      // Verify TextField is displayed for text input
      WidgetTestUtils.verifyWidgetState(
        find.byType(TextField),
        customMessage: 'TextField should be rendered for journal text input',
      );
      
      // Verify the hint text is displayed
      WidgetTestUtils.verifyWidgetState(
        find.text('Share your thoughts, experiences, and reflections...'),
        customMessage: 'Hint text should be displayed in the text field',
      );
      
      // Verify the header text is displayed
      WidgetTestUtils.verifyWidgetState(
        find.text('What\'s on your mind?'),
        customMessage: 'Header text should be displayed above the text field',
      );
    });

    testWidgets('should handle text input and trigger onChanged callback', (WidgetTester tester) async {
      final controller = TextEditingController();
      String? changedText;
      
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: JournalInput(
            controller: controller,
            onChanged: (text) {
              changedText = text;
            },
            onSave: () {},
          ),
        ),
      );

      // Use the improved text input method with proper state verification
      final textField = find.byType(TextField);
      await WidgetTestUtils.enterText(
        tester,
        textField,
        'Test journal entry',
        customMessage: 'Should be able to enter text into journal input field',
      );

      // Use TestDiagnosticsHelper for better error messages
      TestDiagnosticsHelper.verifyEquals(
        controller.text,
        'Test journal entry',
        message: 'Controller text should be updated with entered text',
        suggestion: 'Check if the TextField is properly connected to the controller',
      );
      
      // Verify onChanged callback was triggered with detailed error message
      TestDiagnosticsHelper.verifyEquals(
        changedText,
        'Test journal entry',
        message: 'onChanged callback should be triggered with entered text',
        suggestion: 'Check if the onChanged callback is properly connected to the TextField',
      );
      
      // Verify auto-save indicator appears
      WidgetTestUtils.verifyWidgetState(
        find.text('Auto-saving...'),
        customMessage: 'Auto-saving indicator should appear after text input',
      );
    });

    testWidgets('should handle saving state', (WidgetTester tester) async {
      final controller = TextEditingController();
      bool saveCalled = false;
      
      // Use the improved widget test utilities for pumping with theme
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: JournalInput(
            controller: controller,
            onChanged: (text) {},
            onSave: () {
              saveCalled = true;
            },
            isSaving: true,
          ),
        ),
      );

      // Use the improved loading state verification
      WidgetTestUtils.verifyLoadingState(
        tester,
        shouldBeLoading: true,
        customMessage: 'Loading indicator should be visible when isSaving is true',
      );
      
      // Verify save button text shows "Saving..."
      WidgetTestUtils.verifyWidgetState(
        find.text('Saving...'),
        customMessage: 'Save button should show "Saving..." text when isSaving is true',
      );
    });

    testWidgets('should handle analyzing state', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      // Use the improved widget test utilities for pumping with theme
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: JournalInput(
            controller: controller,
            onChanged: (text) {},
            onSave: () {},
            isAnalyzing: true,
          ),
        ),
      );

      // Verify analyzing state is displayed
      WidgetTestUtils.verifyWidgetState(
        find.text('AI Analysis in Progress'),
        customMessage: 'AI Analysis indicator should be visible when isAnalyzing is true',
      );
      
      // Verify analyzing description text
      WidgetTestUtils.verifyWidgetState(
        find.text('Analyzing your emotions and updating your cores...'),
        customMessage: 'Analysis description should be visible when isAnalyzing is true',
      );
      
      // Verify save button text shows "Analyzing..."
      WidgetTestUtils.verifyWidgetState(
        find.text('Analyzing...'),
        customMessage: 'Save button should show "Analyzing..." text when isAnalyzing is true',
      );
    });

    testWidgets('should work in both light and dark themes', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      // Use the improved theme testing utility
      await WidgetTestUtils.runThemeTest(
        tester,
        Scaffold(
          body: JournalInput(
            controller: controller,
            onChanged: (text) {},
            onSave: () {},
          ),
        ),
        testDescription: 'JournalInput',
        commonTest: (tester, themeMode) async {
          final themeDescription = themeMode == ThemeMode.light ? 'light' : 'dark';
          
          // Verify text field is present
          WidgetTestUtils.verifyWidgetState(
            find.byType(TextField),
            customMessage: 'TextField should be present in $themeDescription theme',
          );
          
          // Verify journal input widget renders correctly
          WidgetTestUtils.verifyWidgetState(
            find.byType(JournalInput),
            customMessage: 'JournalInput should render correctly in $themeDescription theme',
          );
          
          // Verify theme-specific text colors
          WidgetTestUtils.verifyTextThemeColors(
            tester,
            themeMode,
            find.byType(Text),
            customMessage: 'Text colors should be appropriate for $themeDescription theme',
          );
          
          // Verify save button is present and properly themed
          WidgetTestUtils.verifyWidgetState(
            find.widgetWithText(ElevatedButton, 'Save Entry'),
            customMessage: 'Save button should be present in $themeDescription theme',
          );
          
          // Verify button theme colors
          WidgetTestUtils.verifyButtonThemeColors(
            tester,
            themeMode,
            find.widgetWithText(ElevatedButton, 'Save Entry'),
            customMessage: 'Button colors should be appropriate for $themeDescription theme',
          );
        },
      );
    });

    testWidgets('should handle auto-save functionality', (WidgetTester tester) async {
      final controller = TextEditingController();
      String? autoSavedText;
      
      // Use the improved widget test utilities for pumping with theme
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: JournalInput(
            controller: controller,
            onChanged: (text) {},
            onSave: () {},
            onAutoSave: (text) {
              autoSavedText = text;
            },
          ),
        ),
      );

      // Enter text to trigger auto-save
      await WidgetTestUtils.enterText(
        tester,
        find.byType(TextField),
        'Auto save test',
        customMessage: 'Should be able to enter text to trigger auto-save',
      );
      
      // Verify auto-save indicator appears
      WidgetTestUtils.verifyWidgetState(
        find.text('Auto-saving...'),
        customMessage: 'Auto-saving indicator should appear after text input',
      );
      
      // Wait for auto-save timer (2 seconds in the widget)
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      
      // Verify auto-save callback was triggered
      expect(autoSavedText, 'Auto save test', 
        reason: 'onAutoSave callback should be triggered after delay');
      
      // Verify "Saved" indicator appears after auto-save
      WidgetTestUtils.verifyWidgetState(
        find.text('Saved'),
        customMessage: 'Saved indicator should appear after auto-save completes',
      );
    });
    
    testWidgets('should handle save button tap', (WidgetTester tester) async {
      final controller = TextEditingController();
      bool savePressed = false;
      
      // Use the improved widget test utilities for pumping with theme
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: JournalInput(
            controller: controller,
            onChanged: (text) {},
            onSave: () {
              savePressed = true;
            },
          ),
        ),
      );

      // Enter some text first
      await WidgetTestUtils.enterText(
        tester,
        find.byType(TextField),
        'Test entry to save',
        customMessage: 'Should be able to enter text before saving',
      );
      
      // Find and tap the save button using improved utilities
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Entry');
      await WidgetTestUtils.tapButton(
        tester,
        saveButton,
        customMessage: 'Should be able to tap the save button',
      );
      
      // Verify save callback was triggered
      TestDiagnosticsHelper.verifyCondition(
        savePressed,
        message: 'Save button press should trigger onSave callback',
        suggestion: 'Check if the onSave callback is properly connected to the button',
      );
    });
    
    testWidgets('should disable save button when analyzing or saving', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      // Test with isSaving = true
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: JournalInput(
            controller: controller,
            onChanged: (text) {},
            onSave: () {},
            isSaving: true,
          ),
        ),
      );

      // Find save button and verify it's disabled
      final saveButton = find.widgetWithText(ElevatedButton, 'Saving...');
      WidgetTestUtils.verifyButtonState(
        tester,
        saveButton,
        shouldBeEnabled: false,
        customMessage: 'Save button should be disabled when isSaving is true',
      );
      
      // Test with isAnalyzing = true
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: JournalInput(
            controller: controller,
            onChanged: (text) {},
            onSave: () {},
            isAnalyzing: true,
          ),
        ),
      );

      // Find save button and verify it's disabled
      final analyzeButton = find.widgetWithText(ElevatedButton, 'Analyzing...');
      WidgetTestUtils.verifyButtonState(
        tester,
        analyzeButton,
        shouldBeEnabled: false,
        customMessage: 'Save button should be disabled when isAnalyzing is true',
      );
    });
  });
}