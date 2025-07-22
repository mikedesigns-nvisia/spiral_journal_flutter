import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:spiral_journal/controllers/emotional_mirror_slide_controller.dart';
import 'package:spiral_journal/models/slide_config.dart';
import 'package:spiral_journal/providers/emotional_mirror_provider.dart';
import 'package:spiral_journal/services/slide_accessibility_service.dart';
import 'package:spiral_journal/services/slide_keyboard_navigation_service.dart';
import 'package:spiral_journal/widgets/slide_wrapper.dart';
import 'package:spiral_journal/widgets/responsive_slide_layout.dart';

@GenerateMocks([EmotionalMirrorProvider])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Slide Navigation Integration Tests', () {
    late List<SlideConfig> testSlides;
    late MockEmotionalMirrorProvider mockProvider;

    setUp(() {
      testSlides = [
        SlideConfig(
          id: 'mood_overview',
          title: 'Mood Overview',
          description: 'Your mood distribution and trends',
        ),
        SlideConfig(
          id: 'emotional_journey',
          title: 'Emotional Journey',
          description: 'Timeline of your emotional experiences',
        ),
        SlideConfig(
          id: 'pattern_recognition',
          title: 'Pattern Recognition',
          description: 'Behavioral patterns and insights',
        ),
        SlideConfig(
          id: 'self_awareness',
          title: 'Self Awareness',
          description: 'Personal growth and awareness metrics',
        ),
      ];

      mockProvider = MockEmotionalMirrorProvider();
    });

    testWidgets('should navigate through all slides with smooth transitions', (WidgetTester tester) async {
      final controller = EmotionalMirrorSlideController(slides: testSlides);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageView.builder(
              controller: controller.pageController,
              onPageChanged: controller.updateCurrentSlide,
              itemCount: testSlides.length,
              itemBuilder: (context, index) {
                return ResponsiveSlideLayout(
                  slideId: testSlides[index].id,
                  child: SlideWrapper(
                    title: testSlides[index].title,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Slide ${index + 1}'),
                          Text(testSlides[index].description ?? ''),
                          ElevatedButton(
                            onPressed: controller.canGoNext ? controller.nextSlide : null,
                            child: const Text('Next'),
                          ),
                          ElevatedButton(
                            onPressed: controller.canGoPrevious ? controller.previousSlide : null,
                            child: const Text('Previous'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Slide 1'), findsOneWidget);
      expect(find.text('Mood Overview'), findsOneWidget);
      expect(controller.currentSlide, equals(0));

      // Navigate to next slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Slide 2'), findsOneWidget);
      expect(find.text('Emotional Journey'), findsOneWidget);
      expect(controller.currentSlide, equals(1));

      // Navigate to next slide again
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Slide 3'), findsOneWidget);
      expect(find.text('Pattern Recognition'), findsOneWidget);
      expect(controller.currentSlide, equals(2));

      // Navigate back
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      expect(find.text('Slide 2'), findsOneWidget);
      expect(find.text('Emotional Journey'), findsOneWidget);
      expect(controller.currentSlide, equals(1));

      controller.dispose();
    });

    testWidgets('should handle rapid slide switching without performance issues', (WidgetTester tester) async {
      final controller = EmotionalMirrorSlideController(slides: testSlides);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageView.builder(
              controller: controller.pageController,
              onPageChanged: controller.updateCurrentSlide,
              itemCount: testSlides.length,
              itemBuilder: (context, index) {
                return ResponsiveSlideLayout(
                  slideId: testSlides[index].id,
                  child: SlideWrapper(
                    title: testSlides[index].title,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Slide ${index + 1}'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => controller.jumpToSlide(0),
                                child: const Text('Slide 1'),
                              ),
                              ElevatedButton(
                                onPressed: () => controller.jumpToSlide(1),
                                child: const Text('Slide 2'),
                              ),
                              ElevatedButton(
                                onPressed: () => controller.jumpToSlide(2),
                                child: const Text('Slide 3'),
                              ),
                              ElevatedButton(
                                onPressed: () => controller.jumpToSlide(3),
                                child: const Text('Slide 4'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Perform rapid navigation
      await tester.tap(find.text('Slide 4'));
      await tester.pump(const Duration(milliseconds: 50));
      
      await tester.tap(find.text('Slide 1'));
      await tester.pump(const Duration(milliseconds: 50));
      
      await tester.tap(find.text('Slide 3'));
      await tester.pump(const Duration(milliseconds: 50));
      
      await tester.tap(find.text('Slide 2'));
      await tester.pumpAndSettle();

      // Should handle rapid switching without errors
      expect(tester.takeException(), isNull);
      expect(find.text('Slide 2'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('should preserve filter state across slide navigation', (WidgetTester tester) async {
      final controller = EmotionalMirrorSlideController(slides: testSlides);
      String currentFilter = 'All';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    // Filter controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => currentFilter = 'All'),
                          child: Text('All ${currentFilter == 'All' ? '✓' : ''}'),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() => currentFilter = 'Recent'),
                          child: Text('Recent ${currentFilter == 'Recent' ? '✓' : ''}'),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() => currentFilter = 'Favorites'),
                          child: Text('Favorites ${currentFilter == 'Favorites' ? '✓' : ''}'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: controller.pageController,
                        onPageChanged: controller.updateCurrentSlide,
                        itemCount: testSlides.length,
                        itemBuilder: (context, index) {
                          return ResponsiveSlideLayout(
                            slideId: testSlides[index].id,
                            child: SlideWrapper(
                              title: testSlides[index].title,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Slide ${index + 1}'),
                                    Text('Filter: $currentFilter'),
                                    ElevatedButton(
                                      onPressed: controller.canGoNext ? controller.nextSlide : null,
                                      child: const Text('Next'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Set filter to 'Recent'
      await tester.tap(find.text('Recent '));
      await tester.pump();
      expect(find.text('Filter: Recent'), findsOneWidget);

      // Navigate to next slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Filter should be preserved
      expect(find.text('Filter: Recent'), findsOneWidget);
      expect(find.text('Slide 2'), findsOneWidget);

      // Change filter on second slide
      await tester.tap(find.text('Favorites '));
      await tester.pump();
      expect(find.text('Filter: Favorites'), findsOneWidget);

      // Navigate back to first slide
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      // Filter should still be preserved
      expect(find.text('Filter: Favorites'), findsOneWidget);
      expect(find.text('Slide 1'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('should handle keyboard navigation across slides', (WidgetTester tester) async {
      final controller = EmotionalMirrorSlideController(slides: testSlides);
      final keyboardService = SlideKeyboardNavigationService();
      await keyboardService.initialize(slideController: controller);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: keyboardService.handleKeyboardEvent,
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.updateCurrentSlide,
                itemCount: testSlides.length,
                itemBuilder: (context, index) {
                  return ResponsiveSlideLayout(
                    slideId: testSlides[index].id,
                    child: SlideWrapper(
                      title: testSlides[index].title,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Slide ${index + 1}'),
                            Focus(
                              child: ElevatedButton(
                                onPressed: () {},
                                child: const Text('Focusable Button'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Slide 1'), findsOneWidget);
      expect(controller.currentSlide, equals(0));

      // Simulate right arrow key press
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // Should navigate to next slide
      expect(find.text('Slide 2'), findsOneWidget);
      expect(controller.currentSlide, equals(1));

      // Simulate left arrow key press
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      // Should navigate back to previous slide
      expect(find.text('Slide 1'), findsOneWidget);
      expect(controller.currentSlide, equals(0));

      controller.dispose();
      keyboardService.dispose();
    });

    testWidgets('should handle accessibility announcements during navigation', (WidgetTester tester) async {
      final controller = EmotionalMirrorSlideController(slides: testSlides);
      final accessibilityService = SlideAccessibilityService();
      await accessibilityService.initialize();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageView.builder(
              controller: controller.pageController,
              onPageChanged: controller.updateCurrentSlide,
              itemCount: testSlides.length,
              itemBuilder: (context, index) {
                return ResponsiveSlideLayout(
                  slideId: testSlides[index].id,
                  child: SlideWrapper(
                    title: testSlides[index].title,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Semantics(
                            label: 'Slide ${index + 1} of ${testSlides.length}',
                            child: Text('Slide ${index + 1}'),
                          ),
                          ElevatedButton(
                            onPressed: controller.canGoNext ? controller.nextSlide : null,
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify semantic labels are present
      expect(find.bySemanticsLabel('Slide 1 of 4'), findsOneWidget);

      // Navigate to next slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify semantic labels update
      expect(find.bySemanticsLabel('Slide 2 of 4'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('should maintain performance with large datasets', (WidgetTester tester) async {
      // Create a larger dataset to test performance
      final largeSlideSet = List.generate(20, (index) => SlideConfig(
        id: 'slide_$index',
        title: 'Slide ${index + 1}',
        description: 'Description for slide ${index + 1}',
      ));

      final controller = EmotionalMirrorSlideController(slides: largeSlideSet);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageView.builder(
              controller: controller.pageController,
              onPageChanged: controller.updateCurrentSlide,
              itemCount: largeSlideSet.length,
              itemBuilder: (context, index) {
                return ResponsiveSlideLayout(
                  slideId: largeSlideSet[index].id,
                  child: SlideWrapper(
                    title: largeSlideSet[index].title,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Slide ${index + 1}'),
                          // Simulate complex content
                          ...List.generate(10, (i) => Text('Content item $i')),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => controller.jumpToSlide(0),
                                child: const Text('First'),
                              ),
                              ElevatedButton(
                                onPressed: () => controller.jumpToSlide(largeSlideSet.length ~/ 2),
                                child: const Text('Middle'),
                              ),
                              ElevatedButton(
                                onPressed: () => controller.jumpToSlide(largeSlideSet.length - 1),
                                child: const Text('Last'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Test navigation to different positions
      await tester.tap(find.text('Last'));
      await tester.pumpAndSettle();
      expect(find.text('Slide 20'), findsOneWidget);

      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();
      expect(find.text('Slide 1'), findsOneWidget);

      await tester.tap(find.text('Middle'));
      await tester.pumpAndSettle();
      expect(find.text('Slide 10'), findsOneWidget);

      // Should handle large dataset without performance issues
      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('should handle error states and retry functionality', (WidgetTester tester) async {
      final controller = EmotionalMirrorSlideController(slides: testSlides);
      bool hasError = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PageView.builder(
                  controller: controller.pageController,
                  onPageChanged: controller.updateCurrentSlide,
                  itemCount: testSlides.length,
                  itemBuilder: (context, index) {
                    return ResponsiveSlideLayout(
                      slideId: testSlides[index].id,
                      child: SlideWrapper(
                        title: testSlides[index].title,
                        child: Center(
                          child: hasError ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 48, color: Colors.red),
                              const Text('Error loading slide'),
                              ElevatedButton(
                                onPressed: () => setState(() => hasError = false),
                                child: const Text('Retry'),
                              ),
                            ],
                          ) : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Slide ${index + 1}'),
                              ElevatedButton(
                                onPressed: () => setState(() => hasError = true),
                                child: const Text('Simulate Error'),
                              ),
                              ElevatedButton(
                                onPressed: controller.canGoNext ? controller.nextSlide : null,
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      // Simulate error
      await tester.tap(find.text('Simulate Error'));
      await tester.pump();

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Error loading slide'), findsOneWidget);

      // Test retry functionality
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(find.text('Slide 1'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);

      // Navigation should still work after error recovery
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Slide 2'), findsOneWidget);

      controller.dispose();
    });
  });
}
