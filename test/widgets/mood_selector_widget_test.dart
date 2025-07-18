import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/mood_selector.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';

void main() {
  group('MoodSelector Widget Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    testWidgets('should render mood selector with default moods', (WidgetTester tester) async {
      List<String> selectedMoods = [];
      
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: MoodSelector(
            selectedMoods: selectedMoods,
            onMoodChanged: (moods) {
              selectedMoods = moods;
            },
          ),
        ),
      );

      // Verify mood selector widget is rendered
      WidgetTestUtils.verifyWidgetState(
        find.byType(MoodSelector),
        customMessage: 'MoodSelector widget should be rendered properly',
      );

      // The MoodSelector renders primary moods (5) + secondary moods (varies) FilterChips
      // We'll check for at least the primary moods
      final primaryMoodChips = find.byWidgetPredicate(
        (widget) => widget is FilterChip && 
                    ['Happy', 'Content', 'Energetic', 'Grateful', 'Peaceful']
                        .any((mood) => widget.label is Text && (widget.label as Text).data == mood),
      );
      
      WidgetTestUtils.verifyWidgetState(
        primaryMoodChips,
        shouldExist: true,
        expectedCount: 5,
        customMessage: 'Should render exactly 5 primary mood FilterChip widgets',
      );
      
      // Use more specific finders for primary mood chips with detailed error messages
      final expectedPrimaryMoods = ['Happy', 'Content', 'Energetic', 'Grateful', 'Peaceful'];
      for (final mood in expectedPrimaryMoods) {
        final moodChipFinder = find.byWidgetPredicate(
          (widget) => widget is FilterChip && 
                      widget.label is Text && 
                      (widget.label as Text).data == mood,
        );
        WidgetTestUtils.verifyWidgetState(
          moodChipFinder,
          customMessage: 'Primary mood chip "$mood" should be rendered and findable',
        );
      }
    });

    testWidgets('should handle mood selection and deselection', (WidgetTester tester) async {
      List<String> selectedMoods = [];
      
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: MoodSelector(
                selectedMoods: selectedMoods,
                onMoodChanged: (moods) {
                  setState(() {
                    selectedMoods = moods;
                  });
                },
              ),
            );
          },
        ),
      );

      // Find the Happy mood chip specifically
      final happyChipFinder = find.byWidgetPredicate(
        (widget) => widget is FilterChip && 
                    widget.label is Text && 
                    (widget.label as Text).data == 'Happy',
      );
      
      WidgetTestUtils.verifyWidgetState(
        happyChipFinder,
        customMessage: 'Happy mood chip should be available for selection',
      );

      // Verify initial state - chip should not be selected
      final initialChip = tester.widget<FilterChip>(happyChipFinder);
      if (initialChip.selected) {
        fail('Expected Happy mood chip to be initially unselected, but it was selected. '
             'This indicates incorrect initial state setup.');
      }

      // Tap to select the mood
      await tester.tap(happyChipFinder);
      await tester.pumpAndSettle();
      
      // Verify mood was added to selected list with detailed error message
      if (!selectedMoods.contains('Happy')) {
        fail('Expected "Happy" to be in selectedMoods list after selection, but it was not found. '
             'Current selectedMoods: $selectedMoods. This indicates mood selection callback is not working.');
      }

      // Verify chip visual state is selected
      final selectedChip = tester.widget<FilterChip>(happyChipFinder);
      if (!selectedChip.selected) {
        fail('Expected Happy mood chip to be visually selected after tap, but it was not. '
             'This indicates FilterChip selection state is not being updated properly.');
      }

      // Tap again to deselect
      await tester.tap(happyChipFinder);
      await tester.pumpAndSettle();
      
      // Verify mood was removed from selected list
      if (selectedMoods.contains('Happy')) {
        fail('Expected "Happy" to be removed from selectedMoods list after deselection, but it is still present. '
             'Current selectedMoods: $selectedMoods. This indicates mood deselection callback is not working.');
      }

      // Verify chip visual state is deselected
      final deselectedChip = tester.widget<FilterChip>(happyChipFinder);
      if (deselectedChip.selected) {
        fail('Expected Happy mood chip to be visually deselected after second tap, but it was still selected. '
             'This indicates FilterChip deselection state is not being updated properly.');
      }
    });

    testWidgets('should handle multiple mood selections', (WidgetTester tester) async {
      List<String> selectedMoods = [];
      
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: MoodSelector(
                selectedMoods: selectedMoods,
                onMoodChanged: (moods) {
                  setState(() {
                    selectedMoods = moods;
                  });
                },
              ),
            );
          },
        ),
      );

      // Select multiple primary moods individually with proper state verification
      final moodsToSelect = ['Happy', 'Grateful', 'Content'];
      
      for (final mood in moodsToSelect) {
        final moodChipFinder = find.byWidgetPredicate(
          (widget) => widget is FilterChip && 
                      widget.label is Text && 
                      (widget.label as Text).data == mood,
        );
        
        WidgetTestUtils.verifyWidgetState(
          moodChipFinder,
          customMessage: '$mood mood chip should be available for selection',
        );

        // Tap to select the mood
        await tester.tap(moodChipFinder);
        await tester.pumpAndSettle();
        
        // Verify mood was added to selected list
        if (!selectedMoods.contains(mood)) {
          fail('Expected "$mood" to be in selectedMoods list after selection, but it was not found. '
               'Current selectedMoods: $selectedMoods. This indicates mood selection callback is not working.');
        }

        // Verify chip visual state is selected
        final selectedChip = tester.widget<FilterChip>(moodChipFinder);
        if (!selectedChip.selected) {
          fail('Expected $mood mood chip to be visually selected after tap, but it was not. '
               'This indicates FilterChip selection state is not being updated properly.');
        }
      }

      // Verify final selection count with detailed error message
      if (selectedMoods.length != 3) {
        fail('Expected 3 moods to be selected, but found ${selectedMoods.length}. '
             'Selected moods: $selectedMoods. Expected: $moodsToSelect. '
             'This indicates multiple mood selection is not working correctly.');
      }
      
      // Verify all expected moods are selected
      for (final mood in moodsToSelect) {
        if (!selectedMoods.contains(mood)) {
          fail('Expected mood "$mood" to be in selected list, but it was not found. '
               'Selected moods: $selectedMoods. This indicates mood selection callback issues.');
        }
      }

      // Verify visual state - count selected chips
      final selectedChips = find.byWidgetPredicate(
        (widget) => widget is FilterChip && widget.selected,
      );
      
      final actualSelectedCount = selectedChips.evaluate().length;
      if (actualSelectedCount != 3) {
        fail('Expected 3 FilterChips to be visually selected, but found $actualSelectedCount. '
             'This indicates visual selection state is not being maintained properly.');
      }
    });

    testWidgets('should show AI detected moods differently', (WidgetTester tester) async {
      List<String> selectedMoods = [];
      List<String> aiDetectedMoods = ['Happy', 'Grateful'];
      
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: MoodSelector(
            selectedMoods: selectedMoods,
            aiDetectedMoods: aiDetectedMoods,
            onMoodChanged: (moods) {
              selectedMoods = moods;
            },
          ),
        ),
      );

      // Verify AI detected section is shown with specific finder
      WidgetTestUtils.verifyWidgetState(
        find.textContaining('AI detected'),
        customMessage: 'AI detected section should be visible when aiDetectedMoods are provided',
      );
      
      // AI detected moods appear in both AI section and regular chips
      // So we expect to find multiple instances of the same mood text
      final happyTextFinder = find.text('Happy');
      final happyCount = happyTextFinder.evaluate().length;
      if (happyCount < 2) {
        fail('Expected to find at least 2 instances of "Happy" text (AI section + FilterChip), '
             'but found $happyCount. This indicates AI detected moods are not being displayed properly.');
      }
      
      final gratefulTextFinder = find.text('Grateful');
      final gratefulCount = gratefulTextFinder.evaluate().length;
      if (gratefulCount < 2) {
        fail('Expected to find at least 2 instances of "Grateful" text (AI section + FilterChip), '
             'but found $gratefulCount. This indicates AI detected moods are not being displayed properly.');
      }
      
      // Verify AI detected section icon exists
      WidgetTestUtils.verifyWidgetState(
        find.byIcon(Icons.psychology_rounded),
        customMessage: 'AI psychology icon should be present in AI detected section',
      );
      
      // Verify FilterChips are still present (primary moods)
      final primaryMoodChips = find.byWidgetPredicate(
        (widget) => widget is FilterChip && 
                    ['Happy', 'Content', 'Energetic', 'Grateful', 'Peaceful']
                        .any((mood) => widget.label is Text && (widget.label as Text).data == mood),
      );
      
      WidgetTestUtils.verifyWidgetState(
        primaryMoodChips,
        shouldExist: true,
        expectedCount: 5,
        customMessage: 'Primary mood FilterChips should still be present with AI detected moods',
      );

      // Verify AI detected mood containers exist (different from FilterChips)
      final aiMoodContainers = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && 
                    widget.child is Container,
      );
      
      if (aiMoodContainers.evaluate().length < 2) {
        fail('Expected to find at least 2 AI detected mood containers, '
             'but found ${aiMoodContainers.evaluate().length}. '
             'This indicates AI detected mood UI elements are not being rendered properly.');
      }
    });

    testWidgets('should show AI detected moods section', (WidgetTester tester) async {
      List<String> selectedMoods = [];
      List<String> aiDetectedMoods = ['Happy', 'Grateful'];
      
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: MoodSelector(
            selectedMoods: selectedMoods,
            aiDetectedMoods: aiDetectedMoods,
            onMoodChanged: (moods) {
              selectedMoods = moods;
            },
          ),
        ),
      );

      // Verify AI detected moods section with specific state verification
      WidgetTestUtils.verifyWidgetState(
        find.textContaining('AI detected'),
        customMessage: 'AI detected section should be visible when AI detected moods are provided',
      );
      
      // AI detected moods appear in both sections, so expect multiple instances
      WidgetTestUtils.verifyWidgetState(
        find.text('Happy'),
        shouldExist: true,
        expectedCount: 2,
        customMessage: 'Happy mood should appear in both AI detected section and regular mood chips',
      );
      
      WidgetTestUtils.verifyWidgetState(
        find.text('Grateful'),
        shouldExist: true,
        expectedCount: 2,
        customMessage: 'Grateful mood should appear in both AI detected section and regular mood chips',
      );
      
      // Verify AI section specific elements with detailed error messages
      WidgetTestUtils.verifyWidgetState(
        find.byIcon(Icons.psychology_rounded),
        customMessage: 'AI psychology icon should be present to indicate AI detected section',
      );
    });

    testWidgets('should work in both light and dark themes', (WidgetTester tester) async {
      List<String> selectedMoods = [];
      
      // Test light theme with state verification
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: MoodSelector(
            selectedMoods: selectedMoods,
            onMoodChanged: (moods) {
              selectedMoods = moods;
            },
          ),
        ),
        themeMode: ThemeMode.light,
      );

      // Verify primary mood chips are rendered (at least 5)
      final primaryMoodChips = find.byWidgetPredicate(
        (widget) => widget is FilterChip && 
                    ['Happy', 'Content', 'Energetic', 'Grateful', 'Peaceful']
                        .any((mood) => widget.label is Text && (widget.label as Text).data == mood),
      );
      
      WidgetTestUtils.verifyWidgetState(
        primaryMoodChips,
        shouldExist: true,
        expectedCount: 5,
        customMessage: 'Primary mood FilterChips should render correctly in light theme',
      );
      
      // Verify light theme is applied by checking MaterialApp exists
      WidgetTestUtils.verifyWidgetState(
        find.byType(MaterialApp),
        customMessage: 'MaterialApp should be present with light theme',
      );
      
      // Test dark theme with state verification - need to rebuild the widget tree
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: MoodSelector(
            selectedMoods: selectedMoods,
            onMoodChanged: (moods) {
              selectedMoods = moods;
            },
          ),
        ),
        themeMode: ThemeMode.dark,
      );

      // Verify primary mood chips are rendered in dark theme
      final darkThemePrimaryChips = find.byWidgetPredicate(
        (widget) => widget is FilterChip && 
                    ['Happy', 'Content', 'Energetic', 'Grateful', 'Peaceful']
                        .any((mood) => widget.label is Text && (widget.label as Text).data == mood),
      );
      
      WidgetTestUtils.verifyWidgetState(
        darkThemePrimaryChips,
        shouldExist: true,
        expectedCount: 5,
        customMessage: 'Primary mood FilterChips should render correctly in dark theme',
      );
      
      // Verify dark theme is applied by checking MaterialApp exists
      WidgetTestUtils.verifyWidgetState(
        find.byType(MaterialApp),
        customMessage: 'MaterialApp should be present with dark theme',
      );
    });

    testWidgets('should handle analyzing state', (WidgetTester tester) async {
      List<String> selectedMoods = [];
      
      // Use a custom pump method for analyzing state to avoid infinite animation timeout
      final app = MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: Scaffold(
          body: MoodSelector(
            selectedMoods: selectedMoods,
            isAnalyzing: true,
            onMoodChanged: (moods) {
              selectedMoods = moods;
            },
          ),
        ),
      );

      await tester.pumpWidget(app);
      await tester.pump(); // Use pump() instead of pumpAndSettle() to avoid timeout with CircularProgressIndicator

      // Verify mood selector widget is rendered
      WidgetTestUtils.verifyWidgetState(
        find.byType(MoodSelector),
        customMessage: 'MoodSelector widget should be rendered even in analyzing state',
      );
      
      // Verify loading state is properly displayed
      WidgetTestUtils.verifyLoadingState(
        tester,
        shouldBeLoading: true,
        customMessage: 'Loading indicator should be visible when isAnalyzing is true',
      );
      
      // Verify analyzing text is shown
      WidgetTestUtils.verifyWidgetState(
        find.textContaining('AI is analyzing'),
        customMessage: 'AI analyzing text should be visible during analysis state',
      );
    });

    testWidgets('should handle AI mood acceptance', (WidgetTester tester) async {
      List<String> selectedMoods = [];
      List<String> aiDetectedMoods = ['Happy', 'Grateful'];
      bool acceptCalled = false;
      
      await WidgetTestUtils.pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: MoodSelector(
            selectedMoods: selectedMoods,
            aiDetectedMoods: aiDetectedMoods,
            onMoodChanged: (moods) {
              selectedMoods = moods;
            },
            onAcceptAIMoods: () {
              acceptCalled = true;
            },
          ),
        ),
      );

      // Verify AI detected moods section is shown
      WidgetTestUtils.verifyWidgetState(
        find.textContaining('AI detected'),
        customMessage: 'AI detected section should be visible when AI detected moods and accept callback are provided',
      );
      
      // Look for accept button using better finder with state verification
      final acceptButton = WidgetTestUtils.findButton(text: 'Accept All');
      WidgetTestUtils.verifyWidgetState(
        acceptButton, 
        shouldExist: true,
        customMessage: 'Accept All button should be visible when onAcceptAIMoods callback is provided',
      );
      
      // Verify button is enabled and tap it
      await WidgetTestUtils.tapButton(
        tester, 
        acceptButton,
        customMessage: 'Accept All button should be tappable and trigger callback',
      );
      
      // Verify callback was called with detailed error message
      if (!acceptCalled) {
        fail('Expected onAcceptAIMoods callback to be called when Accept All button is tapped, '
             'but it was not called. This indicates button interaction or callback setup issues.');
      }
    });
  });
}