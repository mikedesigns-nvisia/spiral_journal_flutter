import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/slide_indicators.dart';
import 'package:spiral_journal/models/slide_config.dart';
import 'package:spiral_journal/providers/emotional_mirror_provider.dart';

void main() {
  group('SlideIndicators', () {
    testWidgets('displays correct number of indicators', (WidgetTester tester) async {
      int tappedIndex = -1;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideIndicators(
              currentSlide: 0,
              totalSlides: 4,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      // Should display 4 indicators
      expect(find.byType(GestureDetector), findsNWidgets(4));
    });

    testWidgets('highlights current slide correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideIndicators(
              currentSlide: 2,
              totalSlides: 4,
              onTap: (index) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all animated containers (indicators)
      final indicators = find.byType(AnimatedContainer);
      expect(indicators, findsNWidgets(4));
    });

    testWidgets('calls onTap when indicator is tapped', (WidgetTester tester) async {
      int tappedIndex = -1;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideIndicators(
              currentSlide: 0,
              totalSlides: 4,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      // Tap the third indicator (index 2)
      await tester.tap(find.byType(GestureDetector).at(2));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(2));
    });

    testWidgets('does not call onTap when current slide is tapped', (WidgetTester tester) async {
      int tapCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideIndicators(
              currentSlide: 1,
              totalSlides: 4,
              onTap: (index) => tapCount++,
            ),
          ),
        ),
      );

      // Tap the current slide indicator
      await tester.tap(find.byType(GestureDetector).at(1));
      await tester.pumpAndSettle();

      expect(tapCount, equals(0));
    });

    testWidgets('shows nothing when totalSlides is 1 or less', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideIndicators(
              currentSlide: 0,
              totalSlides: 1,
              onTap: (index) {},
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('supports compact layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideIndicators(
              currentSlide: 0,
              totalSlides: 3,
              isCompact: true,
              onTap: (index) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(GestureDetector), findsNWidgets(3));
    });

    testWidgets('supports icon indicators with slide configs', (WidgetTester tester) async {
      final slides = [
        SlideConfig(
          id: 'journey',
          title: 'Journey',
          icon: Icons.timeline,
          builder: (context, provider) => Container(),
        ),
        SlideConfig(
          id: 'awareness',
          title: 'Awareness',
          icon: Icons.psychology,
          builder: (context, provider) => Container(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideIndicators(
              currentSlide: 0,
              totalSlides: 2,
              slides: slides,
              showIcons: true,
              onTap: (index) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Should show icons instead of dots
      expect(find.byType(Icon), findsNWidgets(2));
      expect(find.byIcon(Icons.timeline), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets('animates when currentSlide changes', (WidgetTester tester) async {
      int currentSlide = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    SlideIndicators(
                      currentSlide: currentSlide,
                      totalSlides: 3,
                      onTap: (index) {
                        setState(() {
                          currentSlide = index;
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentSlide = 1;
                        });
                      },
                      child: Text('Change to slide 1'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initial state
      await tester.pumpAndSettle();
      
      // Change slide
      await tester.tap(find.text('Change to slide 1'));
      await tester.pump(); // Start animation
      await tester.pumpAndSettle(); // Complete animation

      // Verify animation completed
      expect(currentSlide, equals(1));
    });
  });

  group('SlideProgressIndicator', () {
    testWidgets('displays progress correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideProgressIndicator(
              currentSlide: 2,
              totalSlides: 5,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Should show progress text
      expect(find.text('3 of 5'), findsOneWidget);
      
      // Should show progress bar
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('hides when totalSlides is 1', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideProgressIndicator(
              currentSlide: 0,
              totalSlides: 1,
            ),
          ),
        ),
      );

      expect(find.byType(FractionallySizedBox), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });

  group('MinimalSlideIndicators', () {
    testWidgets('displays minimal indicators', (WidgetTester tester) async {
      int tappedIndex = -1;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinimalSlideIndicators(
              currentSlide: 1,
              totalSlides: 3,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Should display 3 minimal indicators
      expect(find.byType(GestureDetector), findsNWidgets(3));
      
      // Tap an indicator
      await tester.tap(find.byType(GestureDetector).at(0));
      await tester.pumpAndSettle();
      
      expect(tappedIndex, equals(0));
    });

    testWidgets('hides when totalSlides is 1', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinimalSlideIndicators(
              currentSlide: 0,
              totalSlides: 1,
              onTap: (index) {},
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}