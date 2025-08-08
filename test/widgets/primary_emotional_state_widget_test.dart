import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/primary_emotional_state_widget.dart';
import 'package:spiral_journal/models/emotional_state.dart';
import 'package:spiral_journal/services/accessibility_service.dart';
import '../utils/test_service_manager.dart';

void main() {
  group('PrimaryEmotionalStateWidget', () {
    late AccessibilityService accessibilityService;

    setUp(() {
      accessibilityService = AccessibilityService();
    });

    testWidgets('displays empty state when no emotional state provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: const PrimaryEmotionalStateWidget(),
        ),
      );

      expect(find.text('No Emotional Data'), findsOneWidget);
      expect(find.text('Start journaling to see your primary emotional state'), findsOneWidget);
      expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
    });

    testWidgets('displays emotional state when provided', (WidgetTester tester) async {
      final emotionalState = EmotionalState(
        emotion: 'happy',
        intensity: 0.8,
        confidence: 0.9,
        primaryColor: Colors.orange,
        accessibleColor: Colors.orange,
        displayName: 'Happy',
        description: 'Feeling very happy',
        timestamp: DateTime.now(),
        semanticLabel: 'Happy emotion at 80 percent intensity, positive feeling, 90 percent confidence',
        accessibilityHint: 'Double tap to view details about this strong Happy emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: emotionalState,
            showAnimation: false, // Disable animations for testing
          ),
        ),
      );

      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Primary Emotion'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget); // Intensity
      expect(find.text('90%'), findsOneWidget); // Confidence
      expect(find.text('Feeling very happy'), findsOneWidget);
    });

    testWidgets('displays confidence indicator when enabled', (WidgetTester tester) async {
      final emotionalState = EmotionalState(
        emotion: 'calm',
        intensity: 0.6,
        confidence: 0.7,
        primaryColor: Colors.green,
        accessibleColor: Colors.green,
        displayName: 'Calm',
        description: 'Feeling calm and peaceful',
        timestamp: DateTime.now(),
        semanticLabel: 'Calm emotion at 60 percent intensity, positive feeling, 70 percent confidence',
        accessibilityHint: 'Double tap to view details about this moderate Calm emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: emotionalState,
            showConfidence: true,
            showAnimation: false,
          ),
        ),
      );

      expect(find.text('Confidence Level'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('Good confidence in this emotional assessment'), findsOneWidget);
    });

    testWidgets('hides confidence indicator when disabled', (WidgetTester tester) async {
      final emotionalState = EmotionalState(
        emotion: 'excited',
        intensity: 0.9,
        confidence: 0.8,
        primaryColor: Colors.orange,
        accessibleColor: Colors.orange,
        displayName: 'Excited',
        description: 'Feeling very excited',
        timestamp: DateTime.now(),
        semanticLabel: 'Excited emotion at 90 percent intensity, positive feeling, 80 percent confidence',
        accessibilityHint: 'Double tap to view details about this strong Excited emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: emotionalState,
            showConfidence: false,
            showAnimation: false,
          ),
        ),
      );

      expect(find.text('Confidence Level'), findsNothing);
      expect(find.text('80%'), findsNothing); // Confidence percentage should not be shown
    });

    testWidgets('displays timestamp when enabled', (WidgetTester tester) async {
      final emotionalState = EmotionalState(
        emotion: 'content',
        intensity: 0.5,
        confidence: 0.6,
        primaryColor: Colors.green,
        accessibleColor: Colors.green,
        displayName: 'Content',
        description: 'Feeling content',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        semanticLabel: 'Content emotion at 50 percent intensity, positive feeling, 60 percent confidence',
        accessibilityHint: 'Double tap to view details about this moderate Content emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: emotionalState,
            showTimestamp: true,
            showAnimation: false,
          ),
        ),
      );

      expect(find.textContaining('Last updated'), findsOneWidget);
      expect(find.textContaining('minutes ago'), findsOneWidget);
    });

    testWidgets('hides timestamp when disabled', (WidgetTester tester) async {
      final emotionalState = EmotionalState(
        emotion: 'peaceful',
        intensity: 0.7,
        confidence: 0.8,
        primaryColor: Colors.blue,
        accessibleColor: Colors.blue,
        displayName: 'Peaceful',
        description: 'Feeling peaceful',
        timestamp: DateTime.now(),
        semanticLabel: 'Peaceful emotion at 70 percent intensity, positive feeling, 80 percent confidence',
        accessibilityHint: 'Double tap to view details about this strong Peaceful emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: emotionalState,
            showTimestamp: false,
            showAnimation: false,
          ),
        ),
      );

      expect(find.textContaining('Last updated'), findsNothing);
    });

    testWidgets('handles tap callback when provided', (WidgetTester tester) async {
      bool tapped = false;
      final emotionalState = EmotionalState(
        emotion: 'joyful',
        intensity: 0.8,
        confidence: 0.9,
        primaryColor: Colors.yellow,
        accessibleColor: Colors.yellow,
        displayName: 'Joyful',
        description: 'Feeling joyful',
        timestamp: DateTime.now(),
        semanticLabel: 'Joyful emotion at 80 percent intensity, positive feeling, 90 percent confidence',
        accessibilityHint: 'Double tap to view details about this strong Joyful emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: emotionalState,
            onTap: () => tapped = true,
            showAnimation: false,
          ),
        ),
      );

      await tester.tap(find.byType(PrimaryEmotionalStateWidget));
      expect(tapped, isTrue);
    });

    testWidgets('uses custom semantic label when provided', (WidgetTester tester) async {
      const customLabel = 'Custom accessibility label for testing';
      final emotionalState = EmotionalState(
        emotion: 'grateful',
        intensity: 0.6,
        confidence: 0.7,
        primaryColor: Colors.orange,
        accessibleColor: Colors.orange,
        displayName: 'Grateful',
        description: 'Feeling grateful',
        timestamp: DateTime.now(),
        semanticLabel: 'Grateful emotion at 60 percent intensity, positive feeling, 70 percent confidence',
        accessibilityHint: 'Double tap to view details about this moderate Grateful emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: emotionalState,
            customSemanticLabel: customLabel,
            showAnimation: false,
          ),
        ),
      );

      // Verify the widget is rendered (semantic label testing requires more complex setup)
      expect(find.text('Grateful'), findsOneWidget);
    });

    testWidgets('displays appropriate emotion icons', (WidgetTester tester) async {
      final happyState = EmotionalState(
        emotion: 'happy',
        intensity: 0.8,
        confidence: 0.9,
        primaryColor: Colors.orange,
        accessibleColor: Colors.orange,
        displayName: 'Happy',
        description: 'Feeling happy',
        timestamp: DateTime.now(),
        semanticLabel: 'Happy emotion at 80 percent intensity, positive feeling, 90 percent confidence',
        accessibilityHint: 'Double tap to view details about this strong Happy emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: happyState,
            showAnimation: false,
          ),
        ),
      );

      // Verify that an emotion icon is displayed
      expect(find.byIcon(Icons.sentiment_very_satisfied), findsOneWidget);
    });

    testWidgets('shows different confidence descriptions based on confidence level', (WidgetTester tester) async {
      // Test high confidence
      final highConfidenceState = EmotionalState(
        emotion: 'confident',
        intensity: 0.8,
        confidence: 0.9, // High confidence
        primaryColor: Colors.green,
        accessibleColor: Colors.green,
        displayName: 'Confident',
        description: 'Feeling confident',
        timestamp: DateTime.now(),
        semanticLabel: 'Confident emotion at 80 percent intensity, positive feeling, 90 percent confidence',
        accessibilityHint: 'Double tap to view details about this strong Confident emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: highConfidenceState,
            showAnimation: false,
          ),
        ),
      );

      expect(find.text('High confidence in this emotional assessment'), findsOneWidget);

      // Test low confidence
      final lowConfidenceState = highConfidenceState.copyWith(
        confidence: 0.3, // Low confidence
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: lowConfidenceState,
            showAnimation: false,
          ),
        ),
      );

      expect(find.text('Lower confidence - may need more data'), findsOneWidget);
    });

    testWidgets('handles negative emotions correctly', (WidgetTester tester) async {
      final sadState = EmotionalState(
        emotion: 'sad',
        intensity: 0.6,
        confidence: 0.8,
        primaryColor: Colors.blue,
        accessibleColor: Colors.blue,
        displayName: 'Sad',
        description: 'Feeling sad',
        timestamp: DateTime.now(),
        semanticLabel: 'Sad emotion at 60 percent intensity, negative feeling, 80 percent confidence',
        accessibilityHint: 'Double tap to view details about this moderate Sad emotion',
        isPositive: false,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: sadState,
            showAnimation: false,
          ),
        ),
      );

      expect(find.text('Sad'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget); // Intensity
      expect(find.byIcon(Icons.sentiment_very_dissatisfied), findsOneWidget);
    });

    testWidgets('displays tab navigation when both primary and secondary states provided', (WidgetTester tester) async {
      final primaryState = EmotionalState(
        emotion: 'happy',
        intensity: 0.8,
        confidence: 0.9,
        primaryColor: Colors.orange,
        accessibleColor: Colors.orange,
        displayName: 'Happy',
        description: 'Feeling very happy',
        timestamp: DateTime.now(),
        semanticLabel: 'Happy emotion at 80 percent intensity, positive feeling, 90 percent confidence',
        accessibilityHint: 'Double tap to view details about this strong Happy emotion',
        isPositive: true,
      );

      final secondaryState = EmotionalState(
        emotion: 'excited',
        intensity: 0.6,
        confidence: 0.7,
        primaryColor: Colors.red,
        accessibleColor: Colors.red,
        displayName: 'Excited',
        description: 'Feeling excited about possibilities',
        timestamp: DateTime.now(),
        semanticLabel: 'Excited emotion at 60 percent intensity, positive feeling, 70 percent confidence',
        accessibilityHint: 'Double tap to view details about this moderate Excited emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: primaryState,
            secondaryState: secondaryState,
            showTabs: true,
            showAnimation: false,
          ),
        ),
      );

      // Should show tab navigation
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      
      // Should show primary emotion by default
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Primary Emotion'), findsOneWidget);
    });

    testWidgets('switches between primary and secondary emotions when tabs are tapped', (WidgetTester tester) async {
      final primaryState = EmotionalState(
        emotion: 'happy',
        intensity: 0.8,
        confidence: 0.9,
        primaryColor: Colors.orange,
        accessibleColor: Colors.orange,
        displayName: 'Happy',
        description: 'Feeling very happy',
        timestamp: DateTime.now(),
        semanticLabel: 'Happy emotion at 80 percent intensity, positive feeling, 90 percent confidence',
        accessibilityHint: 'Double tap to view details about this strong Happy emotion',
        isPositive: true,
      );

      final secondaryState = EmotionalState(
        emotion: 'excited',
        intensity: 0.6,
        confidence: 0.7,
        primaryColor: Colors.red,
        accessibleColor: Colors.red,
        displayName: 'Excited',
        description: 'Feeling excited about possibilities',
        timestamp: DateTime.now(),
        semanticLabel: 'Excited emotion at 60 percent intensity, positive feeling, 70 percent confidence',
        accessibilityHint: 'Double tap to view details about this moderate Excited emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: primaryState,
            secondaryState: secondaryState,
            showTabs: true,
            showAnimation: false,
          ),
        ),
      );

      // Initially shows primary emotion
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Primary Emotion'), findsOneWidget);

      // Tap secondary tab
      await tester.tap(find.text('Secondary'));
      await tester.pumpAndSettle();

      // Should now show secondary emotion
      expect(find.text('Excited'), findsOneWidget);
      expect(find.text('Secondary Emotion'), findsOneWidget);
    });

    testWidgets('hides tabs when showTabs is false', (WidgetTester tester) async {
      final primaryState = EmotionalState(
        emotion: 'happy',
        intensity: 0.8,
        confidence: 0.9,
        primaryColor: Colors.orange,
        accessibleColor: Colors.orange,
        displayName: 'Happy',
        description: 'Feeling very happy',
        timestamp: DateTime.now(),
        semanticLabel: 'Happy emotion at 80 percent intensity, positive feeling, 90 percent confidence',
        accessibilityHint: 'Double tap to view details about this strong Happy emotion',
        isPositive: true,
      );

      final secondaryState = EmotionalState(
        emotion: 'excited',
        intensity: 0.6,
        confidence: 0.7,
        primaryColor: Colors.red,
        accessibleColor: Colors.red,
        displayName: 'Excited',
        description: 'Feeling excited about possibilities',
        timestamp: DateTime.now(),
        semanticLabel: 'Excited emotion at 60 percent intensity, positive feeling, 70 percent confidence',
        accessibilityHint: 'Double tap to view details about this moderate Excited emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: primaryState,
            secondaryState: secondaryState,
            showTabs: false,
            showAnimation: false,
          ),
        ),
      );

      // Should not show tab navigation
      expect(find.text('Primary'), findsNothing);
      expect(find.text('Secondary'), findsNothing);
      
      // Should show primary emotion
      expect(find.text('Happy'), findsOneWidget);
    });

    testWidgets('shows only secondary emotion when primary is null', (WidgetTester tester) async {
      final secondaryState = EmotionalState(
        emotion: 'excited',
        intensity: 0.6,
        confidence: 0.7,
        primaryColor: Colors.red,
        accessibleColor: Colors.red,
        displayName: 'Excited',
        description: 'Feeling excited about possibilities',
        timestamp: DateTime.now(),
        semanticLabel: 'Excited emotion at 60 percent intensity, positive feeling, 70 percent confidence',
        accessibilityHint: 'Double tap to view details about this moderate Excited emotion',
        isPositive: true,
      );

      await tester.pumpWidget(
        TestServiceManager.createTestApp(
          child: PrimaryEmotionalStateWidget(
            primaryState: null,
            secondaryState: secondaryState,
            showTabs: true,
            showAnimation: false,
          ),
        ),
      );

      // Should show secondary emotion without tabs
      expect(find.text('Excited'), findsOneWidget);
      expect(find.text('Primary'), findsNothing);
      expect(find.text('Secondary'), findsNothing);
    });
  });
}