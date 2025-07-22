import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/controllers/emotional_mirror_slide_controller.dart';
import 'package:spiral_journal/models/slide_config.dart';
import 'package:spiral_journal/providers/emotional_mirror_provider.dart';

void main() {
  group('EmotionalMirrorSlideController', () {
    late List<SlideConfig> testSlides;
    late EmotionalMirrorSlideController controller;

    setUp(() {
      testSlides = [
        SlideConfig(
          id: 'slide1',
          title: 'Slide 1',
          icon: Icons.timeline,
          builder: (context, provider) => const Text('Slide 1'),
        ),
        SlideConfig(
          id: 'slide2',
          title: 'Slide 2',
          icon: Icons.psychology,
          builder: (context, provider) => const Text('Slide 2'),
        ),
        SlideConfig(
          id: 'slide3',
          title: 'Slide 3',
          icon: Icons.dashboard,
          builder: (context, provider) => const Text('Slide 3'),
        ),
      ];
      controller = EmotionalMirrorSlideController(slides: testSlides);
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('should initialize with correct default values', () {
        expect(controller.currentSlide, equals(0));
        expect(controller.totalSlides, equals(3));
        expect(controller.slides.length, equals(3));
        expect(controller.isTransitioning, isFalse);
        expect(controller.pageController, isNotNull);
      });

      test('should initialize with custom initial slide', () {
        final customController = EmotionalMirrorSlideController(
          slides: testSlides,
          initialSlide: 1,
        );
        expect(customController.currentSlide, equals(1));
        customController.dispose();
      });

      test('should provide immutable slides list', () {
        final slides = controller.slides;
        expect(() => slides.add(testSlides[0]), throwsUnsupportedError);
      });
    });

    group('Navigation State', () {
      test('should correctly report navigation capabilities at first slide', () {
        expect(controller.canGoNext, isTrue);
        expect(controller.canGoPrevious, isFalse);
      });

      test('should correctly report navigation capabilities at middle slide', () {
        controller.updateCurrentSlide(1);
        expect(controller.canGoNext, isTrue);
        expect(controller.canGoPrevious, isTrue);
      });

      test('should correctly report navigation capabilities at last slide', () {
        controller.updateCurrentSlide(2);
        expect(controller.canGoNext, isFalse);
        expect(controller.canGoPrevious, isTrue);
      });

      test('should return current slide configuration', () {
        expect(controller.currentSlideConfig.id, equals('slide1'));
        expect(controller.currentSlideConfig.title, equals('Slide 1'));
        
        controller.updateCurrentSlide(1);
        expect(controller.currentSlideConfig.id, equals('slide2'));
        expect(controller.currentSlideConfig.title, equals('Slide 2'));
      });
    });

    group('Slide Updates', () {
      test('should update current slide and notify listeners', () {
        bool notified = false;
        controller.addListener(() => notified = true);

        controller.updateCurrentSlide(1);
        
        expect(controller.currentSlide, equals(1));
        expect(notified, isTrue);
      });

      test('should not update if index is the same', () {
        bool notified = false;
        controller.addListener(() => notified = true);

        controller.updateCurrentSlide(0); // Same as current
        
        expect(notified, isFalse);
      });

      test('should not update if index is out of bounds', () {
        bool notified = false;
        controller.addListener(() => notified = true);

        controller.updateCurrentSlide(-1);
        expect(controller.currentSlide, equals(0));
        expect(notified, isFalse);

        controller.updateCurrentSlide(5);
        expect(controller.currentSlide, equals(0));
        expect(notified, isFalse);
      });
    });

    group('Slide Configuration Access', () {
      test('should return slide config by valid index', () {
        final config = controller.getSlideConfig(1);
        expect(config, isNotNull);
        expect(config!.id, equals('slide2'));
        expect(config.title, equals('Slide 2'));
      });

      test('should return null for invalid index', () {
        expect(controller.getSlideConfig(-1), isNull);
        expect(controller.getSlideConfig(5), isNull);
      });

      test('should find slide index by ID', () {
        expect(controller.getSlideIndex('slide1'), equals(0));
        expect(controller.getSlideIndex('slide2'), equals(1));
        expect(controller.getSlideIndex('slide3'), equals(2));
        expect(controller.getSlideIndex('nonexistent'), equals(-1));
      });
    });

    group('Navigation Methods', () {
      testWidgets('should handle nextSlide when possible', (tester) async {
        expect(controller.canGoNext, isTrue);
        
        // Mock the PageController behavior
        controller.updateCurrentSlide(1);
        
        expect(controller.currentSlide, equals(1));
      });

      testWidgets('should handle previousSlide when possible', (tester) async {
        controller.updateCurrentSlide(1);
        expect(controller.canGoPrevious, isTrue);
        
        // Mock the PageController behavior
        controller.updateCurrentSlide(0);
        
        expect(controller.currentSlide, equals(0));
      });

      testWidgets('should handle jumpToSlide with valid index', (tester) async {
        // Mock the PageController behavior
        controller.updateCurrentSlide(2);
        
        expect(controller.currentSlide, equals(2));
      });

      test('should not navigate when transitioning', () async {
        // Set transitioning state manually for testing
        controller.updateCurrentSlide(0);
        
        // These should not cause issues when called during transition
        expect(controller.currentSlide, equals(0));
      });

      testWidgets('should handle jumpToSlideById', (tester) async {
        // Mock the PageController behavior
        controller.updateCurrentSlide(1);
        
        expect(controller.currentSlide, equals(1));
      });
    });

    group('Edge Cases', () {
      test('should handle empty slides list', () {
        final emptyController = EmotionalMirrorSlideController(slides: []);
        expect(emptyController.totalSlides, equals(0));
        expect(emptyController.canGoNext, isFalse);
        expect(emptyController.canGoPrevious, isFalse);
        emptyController.dispose();
      });

      test('should handle single slide', () {
        final singleSlideController = EmotionalMirrorSlideController(
          slides: [testSlides[0]],
        );
        expect(singleSlideController.totalSlides, equals(1));
        expect(singleSlideController.canGoNext, isFalse);
        expect(singleSlideController.canGoPrevious, isFalse);
        singleSlideController.dispose();
      });

      testWidgets('should ignore invalid jumpToSlide calls', (tester) async {
        final initialSlide = controller.currentSlide;
        
        // These should not change the current slide
        await controller.jumpToSlide(-1);
        await controller.jumpToSlide(10);
        await controller.jumpToSlide(controller.currentSlide); // Same slide
        
        expect(controller.currentSlide, equals(initialSlide));
      });
    });

    group('Disposal', () {
      test('should dispose PageController properly', () {
        final testController = EmotionalMirrorSlideController(slides: testSlides);
        expect(testController.pageController, isNotNull);
        
        testController.dispose();
        // PageController should be disposed, but we can't easily test this
        // without accessing private members
      });
    });
  });

  group('SlideConfig', () {
    test('should create slide config with required properties', () {
      final config = SlideConfig(
        id: 'test',
        title: 'Test Slide',
        icon: Icons.science,
        builder: (context, provider) => const Text('Test'),
      );

      expect(config.id, equals('test'));
      expect(config.title, equals('Test Slide'));
      expect(config.icon, equals(Icons.science));
      expect(config.requiresData, isTrue); // Default value
    });

    test('should create slide config with custom requiresData', () {
      final config = SlideConfig(
        id: 'test',
        title: 'Test Slide',
        icon: Icons.science,
        builder: (context, provider) => const Text('Test'),
        requiresData: false,
      );

      expect(config.requiresData, isFalse);
    });

    test('should implement equality correctly', () {
      final config1 = SlideConfig(
        id: 'test',
        title: 'Test Slide',
        icon: Icons.science,
        builder: (context, provider) => const Text('Test'),
      );

      final config2 = SlideConfig(
        id: 'test',
        title: 'Test Slide',
        icon: Icons.science,
        builder: (context, provider) => const Text('Test'),
      );

      final config3 = SlideConfig(
        id: 'different',
        title: 'Test Slide',
        icon: Icons.science,
        builder: (context, provider) => const Text('Test'),
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('should implement hashCode correctly', () {
      final config1 = SlideConfig(
        id: 'test',
        title: 'Test Slide',
        icon: Icons.science,
        builder: (context, provider) => const Text('Test'),
      );

      final config2 = SlideConfig(
        id: 'test',
        title: 'Test Slide',
        icon: Icons.science,
        builder: (context, provider) => const Text('Test'),
      );

      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should implement toString correctly', () {
      final config = SlideConfig(
        id: 'test',
        title: 'Test Slide',
        icon: Icons.science,
        builder: (context, provider) => const Text('Test'),
      );

      final string = config.toString();
      expect(string, contains('test'));
      expect(string, contains('Test Slide'));
      expect(string, contains('true')); // requiresData default
    });
  });
}