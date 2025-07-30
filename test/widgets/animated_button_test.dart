import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/animated_button.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';

void main() {
  group('AnimatedButton Widget Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    testWidgets('should render animated button with child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              child: const Text('Test Button'),
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.byType(AnimatedButton),
        customMessage: 'AnimatedButton should render properly',
      );

      WidgetTestUtils.verifyWidgetState(
        find.text('Test Button'),
        customMessage: 'Button child text should be displayed',
      );
    });

    testWidgets('should handle tap down and up events', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              child: const Text('Test Button'),
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final buttonFinder = find.byType(AnimatedButton);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(buttonFinder),
      );
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();

      expect(buttonPressed, isTrue, reason: 'onPressed callback should be called');
    });

    testWidgets('should animate scale on press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              child: const Text('Test Button'),
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final buttonFinder = find.byType(AnimatedButton);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(buttonFinder),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final animatedBuilder = find.descendant(
        of: find.byType(AnimatedButton),
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedBuilder, findsOneWidget, reason: 'AnimatedBuilder should be present within AnimatedButton');

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('should handle tap cancel', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              child: const Text('Test Button'),
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final buttonFinder = find.byType(AnimatedButton);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(buttonFinder),
      );
      await tester.pump();

      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(buttonPressed, isFalse, reason: 'onPressed should not be called on cancel');
    });

    testWidgets('should respect enabled state', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              enabled: false,
              child: const Text('Disabled Button'),
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await WidgetTestUtils.tapButton(
        tester,
        find.byType(AnimatedButton),
        customMessage: 'Should be able to tap disabled button without triggering callback',
      );

      expect(buttonPressed, isFalse, reason: 'onPressed should not be called when disabled');
    });

    testWidgets('should work without onPressed callback', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              child: Text('No Callback Button'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.byType(AnimatedButton),
        customMessage: 'AnimatedButton should render without onPressed callback',
      );

      await tester.tap(find.byType(AnimatedButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'No exception should be thrown when tapping button without callback');
    });

    testWidgets('should apply custom styling properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              child: const Text('Styled Button'),
              onPressed: () {},
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(12),
              pressedScale: 0.8,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AnimatedButton),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.blue), reason: 'Background color should be applied');
      expect(container.padding, equals(const EdgeInsets.all(16)), reason: 'Padding should be applied');
    });

    testWidgets('should handle custom animation duration and curve', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              child: const Text('Custom Animation'),
              onPressed: () {},
              duration: const Duration(milliseconds: 500),
              curve: Curves.bounceOut,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      WidgetTestUtils.verifyWidgetState(
        find.byType(AnimatedButton),
        customMessage: 'AnimatedButton should handle custom animation properties',
      );
    });

    testWidgets('should work in both light and dark themes', (WidgetTester tester) async {
      await WidgetTestUtils.runThemeTest(
        tester,
        AnimatedButton(
          child: const Text('Theme Test'),
          onPressed: () {},
        ),
        testDescription: 'AnimatedButton',
        commonTest: (tester, themeMode) async {
          final themeDescription = themeMode == ThemeMode.light ? 'light' : 'dark';
          
          WidgetTestUtils.verifyWidgetState(
            find.byType(AnimatedButton),
            customMessage: 'AnimatedButton should render correctly in $themeDescription theme',
          );
          
          WidgetTestUtils.verifyWidgetState(
            find.text('Theme Test'),
            customMessage: 'Button text should be visible in $themeDescription theme',
          );
        },
      );
    });

    testWidgets('should handle rapid press and release', (WidgetTester tester) async {
      int pressCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              child: const Text('Rapid Test'),
              onPressed: () => pressCount++,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final buttonFinder = find.byType(AnimatedButton);

      for (int i = 0; i < 5; i++) {
        final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();

      expect(pressCount, equals(5), reason: 'All rapid presses should be registered');
    });

    testWidgets('should handle animation controller disposal', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              child: const Text('Disposal Test'),
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'No exception should be thrown on disposal');
    });

    testWidgets('should handle transform scale properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              child: const Text('Scale Test'),
              onPressed: () {},
              pressedScale: 0.5,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final transformFinder = find.descendant(
        of: find.byType(AnimatedButton),
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsAtLeastNWidgets(1), reason: 'Transform widget should be present for scaling within AnimatedButton');
    });
  });
}