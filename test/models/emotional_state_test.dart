import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/models/emotional_state.dart';

void main() {
  group('EmotionalState', () {
    testWidgets('creates emotional state with accessibility properties', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            final emotionalState = EmotionalState.create(
              emotion: 'happy',
              intensity: 0.8,
              confidence: 0.9,
              context: context,
            );

            expect(emotionalState.emotion, equals('happy'));
            expect(emotionalState.intensity, equals(0.8));
            expect(emotionalState.confidence, equals(0.9));
            expect(emotionalState.displayName, equals('Happy'));
            expect(emotionalState.isPositive, isTrue);
            expect(emotionalState.semanticLabel, contains('Happy emotion'));
            expect(emotionalState.semanticLabel, contains('80 percent intensity'));
            expect(emotionalState.semanticLabel, contains('positive feeling'));
            expect(emotionalState.accessibilityHint, contains('Double tap to view details'));

            return Container();
          },
        ),
      ));
    });

    testWidgets('generates correct semantic labels through factory', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            final happyState = EmotionalState.create(
              emotion: 'happy',
              intensity: 0.7,
              confidence: 0.8,
              context: context,
            );

            expect(happyState.semanticLabel, contains('Happy emotion'));
            expect(happyState.semanticLabel, contains('70 percent intensity'));
            expect(happyState.semanticLabel, contains('positive feeling'));
            expect(happyState.semanticLabel, contains('80 percent confidence'));

            return Container();
          },
        ),
      ));
    });

    testWidgets('determines positive emotions correctly through factory', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            final happyState = EmotionalState.create(emotion: 'happy', intensity: 0.5, confidence: 0.5, context: context);
            final excitedState = EmotionalState.create(emotion: 'excited', intensity: 0.5, confidence: 0.5, context: context);
            final calmState = EmotionalState.create(emotion: 'calm', intensity: 0.5, confidence: 0.5, context: context);
            final sadState = EmotionalState.create(emotion: 'sad', intensity: 0.5, confidence: 0.5, context: context);
            final angryState = EmotionalState.create(emotion: 'angry', intensity: 0.5, confidence: 0.5, context: context);
            final anxiousState = EmotionalState.create(emotion: 'anxious', intensity: 0.5, confidence: 0.5, context: context);

            expect(happyState.isPositive, isTrue);
            expect(excitedState.isPositive, isTrue);
            expect(calmState.isPositive, isTrue);
            expect(sadState.isPositive, isFalse);
            expect(angryState.isPositive, isFalse);
            expect(anxiousState.isPositive, isFalse);

            return Container();
          },
        ),
      ));
    });

    test('serializes and deserializes correctly', () {
      final original = EmotionalState(
        emotion: 'happy',
        intensity: 0.8,
        confidence: 0.9,
        primaryColor: Colors.orange,
        accessibleColor: Colors.orange,
        displayName: 'Happy',
        description: 'Feeling very happy',
        timestamp: DateTime(2024, 1, 1),
        relatedEmotions: ['joyful', 'excited'],
        semanticLabel: 'Happy emotion at 80 percent intensity',
        accessibilityHint: 'Double tap to view details',
        isPositive: true,
      );

      final json = original.toJson();
      final deserialized = EmotionalState.fromJson(json);

      expect(deserialized.emotion, equals(original.emotion));
      expect(deserialized.intensity, equals(original.intensity));
      expect(deserialized.confidence, equals(original.confidence));
      expect(deserialized.displayName, equals(original.displayName));
      expect(deserialized.description, equals(original.description));
      expect(deserialized.isPositive, equals(original.isPositive));
      expect(deserialized.relatedEmotions, equals(original.relatedEmotions));
    });
  });

  group('EmotionColorPair', () {
    test('creates color pair with high contrast', () {
      const white = Colors.white;
      const black = Colors.black;

      final colorPair = EmotionColorPair.create(
        primary: black,
        background: white,
        textLabel: 'Test',
      );

      expect(colorPair.contrastRatio, greaterThan(20.0)); // Should be 21:1 for perfect contrast
    });

    test('creates accessible color pair', () {
      const primary = Colors.blue;
      const background = Colors.white;
      const textLabel = 'Happy';

      final colorPair = EmotionColorPair.create(
        primary: primary,
        background: background,
        textLabel: textLabel,
      );

      expect(colorPair.textLabel, equals(textLabel));
      expect(colorPair.contrastRatio, greaterThan(0.0));
      expect(colorPair.meetsWCAGAA, isTrue);
    });

    test('adjusts colors for high contrast mode', () {
      const primary = Colors.lightBlue;
      const background = Colors.white;
      const textLabel = 'Calm';

      final normalColorPair = EmotionColorPair.create(
        primary: primary,
        background: background,
        textLabel: textLabel,
        highContrastMode: false,
      );

      final highContrastColorPair = EmotionColorPair.create(
        primary: primary,
        background: background,
        textLabel: textLabel,
        highContrastMode: true,
      );

      expect(highContrastColorPair.contrastRatio, 
             greaterThanOrEqualTo(normalColorPair.contrastRatio));
    });
  });

  group('AccessibleEmotionColors', () {
    testWidgets('creates emotion colors for context', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            final emotionColors = AccessibleEmotionColors.forContext(context);

            expect(emotionColors.hasEmotion('happy'), isTrue);
            expect(emotionColors.hasEmotion('sad'), isTrue);
            expect(emotionColors.hasEmotion('nonexistent'), isFalse);

            final happyColors = emotionColors.getEmotionColors('happy');
            expect(happyColors.textLabel, equals('Happy'));
            expect(happyColors.meetsWCAGAA, isTrue);

            return Container();
          },
        ),
      ));
    });

    testWidgets('provides fallback for unknown emotions', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            final emotionColors = AccessibleEmotionColors.forContext(context);
            final unknownColors = emotionColors.getEmotionColors('unknown_emotion');

            // The fallback should use the 'content' emotion or create a fallback
            expect(unknownColors.textLabel, isNotEmpty);
            expect(unknownColors.contrastRatio, greaterThanOrEqualTo(4.5));

            return Container();
          },
        ),
      ));
    });

    testWidgets('creates emotion colors with brightness information', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            final emotionColors = AccessibleEmotionColors.forContext(context);
            
            // Should have a brightness value
            expect(emotionColors.brightness, isNotNull);
            
            // Should create valid color pairs
            final happyColors = emotionColors.getEmotionColors('happy');
            expect(happyColors.contrastRatio, greaterThan(0.0));
            
            return Container();
          },
        ),
      ));
    });
  });
}