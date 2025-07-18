import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/loading_state_widget.dart';
import '../utils/test_setup_helper.dart';
import '../utils/widget_test_utils.dart';

void main() {
  group('LoadingStateWidget Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });
    testWidgets('should display loading indicator', (WidgetTester tester) async {
      // Use pump() instead of pumpAndSettle() to avoid timeout with CircularProgressIndicator
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(),
          ),
        ),
      );

      await tester.pump();

      // Verify LoadingStateWidget is rendered properly
      WidgetTestUtils.verifyWidgetState(
        find.byType(LoadingStateWidget),
        customMessage: 'LoadingStateWidget should be rendered and visible',
      );

      // Verify loading indicator is displayed
      WidgetTestUtils.verifyLoadingState(
        tester,
        shouldBeLoading: true,
        customMessage: 'CircularProgressIndicator should be visible in default loading state',
      );
    });

    testWidgets('should display custom message', (WidgetTester tester) async {
      const loadingMessage = 'Loading your journal...';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(
              message: loadingMessage,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify custom message is displayed with specific text matching
      WidgetTestUtils.verifyWidgetState(
        find.text(loadingMessage),
        customMessage: 'Custom loading message "$loadingMessage" should be displayed to user',
      );
    });

    testWidgets('should work in both light and dark themes', (WidgetTester tester) async {
      const testMessage = 'Loading...';
      
      // Test light theme
      await WidgetTestUtils.pumpWidgetWithThemeNoSettle(
        tester,
        const Scaffold(
          body: LoadingStateWidget(
            message: testMessage,
          ),
        ),
        themeMode: ThemeMode.light,
      );

      WidgetTestUtils.verifyLoadingState(
        tester,
        shouldBeLoading: true,
        customMessage: 'Loading indicator should be visible in light theme',
      );

      WidgetTestUtils.verifyWidgetState(
        find.text(testMessage),
        customMessage: 'Loading message should be displayed in light theme',
      );

      // Test dark theme
      await WidgetTestUtils.pumpWidgetWithThemeNoSettle(
        tester,
        const Scaffold(
          body: LoadingStateWidget(
            message: testMessage,
          ),
        ),
        themeMode: ThemeMode.dark,
      );

      WidgetTestUtils.verifyLoadingState(
        tester,
        shouldBeLoading: true,
        customMessage: 'Loading indicator should be visible in dark theme',
      );

      WidgetTestUtils.verifyWidgetState(
        find.text(testMessage),
        customMessage: 'Loading message should be displayed in dark theme',
      );

      // Verify that both themes render the widget correctly
      WidgetTestUtils.verifyWidgetState(
        find.byType(LoadingStateWidget),
        customMessage: 'LoadingStateWidget should render correctly in both themes',
      );
    });

    testWidgets('should show progress indicator when progress is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(
              message: 'Processing...',
              progress: 0.5,
              showProgress: true,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify linear progress indicator is displayed when progress is provided
      WidgetTestUtils.verifyWidgetState(
        find.byType(LinearProgressIndicator),
        customMessage: 'LinearProgressIndicator should be visible when progress value is provided',
      );
      
      // Verify progress percentage text is displayed
      WidgetTestUtils.verifyWidgetState(
        find.text('50%'),
        customMessage: 'Progress percentage "50%" should be displayed when progress is 0.5',
      );
    });

    testWidgets('should handle different loading types', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(
              message: 'Analyzing...',
              type: LoadingType.dots,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify dots loading type message is displayed
      WidgetTestUtils.verifyWidgetState(
        find.textContaining('Analyzing'),
        customMessage: 'Loading message "Analyzing..." should be displayed for dots loading type',
      );
      
      // Verify LoadingStateWidget is rendered with dots type
      WidgetTestUtils.verifyWidgetState(
        find.byType(LoadingStateWidget),
        customMessage: 'LoadingStateWidget should be rendered with dots loading type',
      );
    });

    testWidgets('should handle pulse loading type', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(
              type: LoadingType.pulse,
              message: 'Loading...',
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify LoadingStateWidget is rendered with pulse loading type
      WidgetTestUtils.verifyWidgetState(
        find.byType(LoadingStateWidget),
        customMessage: 'LoadingStateWidget should be rendered with pulse loading animation type',
      );
    });

    testWidgets('should handle wave loading type', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(
              type: LoadingType.wave,
              message: 'Processing...',
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify LoadingStateWidget is rendered with wave loading type
      WidgetTestUtils.verifyWidgetState(
        find.byType(LoadingStateWidget),
        customMessage: 'LoadingStateWidget should be rendered with wave loading animation type',
      );
    });

    testWidgets('should handle custom size and color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(
              size: 60.0,
              color: Colors.red,
              message: 'Custom loading...',
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify LoadingStateWidget is rendered with custom properties
      WidgetTestUtils.verifyWidgetState(
        find.byType(LoadingStateWidget),
        customMessage: 'LoadingStateWidget should be rendered with custom size and color properties',
      );
      
      // Verify custom loading message is displayed
      WidgetTestUtils.verifyWidgetState(
        find.text('Custom loading...'),
        customMessage: 'Custom loading message "Custom loading..." should be displayed with custom styling',
      );
    });
  });
}