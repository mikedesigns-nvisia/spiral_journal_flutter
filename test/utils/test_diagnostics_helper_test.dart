import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/utils/app_error_handler.dart';
import 'test_diagnostics_helper.dart';
import 'test_setup_helper.dart';

void main() {
  group('TestDiagnosticsHelper Tests', () {
    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
    });

    test('getDetailedErrorMessage should format error message correctly', () {
      final message = TestDiagnosticsHelper.getDetailedErrorMessage(
        expectedBehavior: 'Button should be enabled',
        actualBehavior: 'Button is disabled',
        widgetName: 'SubmitButton',
        testContext: 'Form submission test',
        suggestion: 'Check if form validation is preventing button activation',
      );
      
      expect(message, contains('Expected: Button should be enabled'));
      expect(message, contains('Actual: Button is disabled'));
      expect(message, contains('Widget: SubmitButton'));
      expect(message, contains('Context: Form submission test'));
      expect(message, contains('Suggestion: Check if form validation is preventing button activation'));
    });

    test('getFinderErrorMessage should format finder error message correctly', () {
      final finder = find.byType(ElevatedButton);
      final message = TestDiagnosticsHelper.getFinderErrorMessage(
        finder: finder,
        shouldExist: true,
        expectedCount: 1,
        widgetDescription: 'Submit button',
        suggestion: 'Make sure the button is rendered in the widget tree',
      );
      
      expect(message, contains('Expected: 1 Submit button widget(s)'));
      expect(message, contains('Suggestion: Make sure the button is rendered in the widget tree'));
    });

    test('getCallbackErrorMessage should format callback error message correctly', () {
      final message = TestDiagnosticsHelper.getCallbackErrorMessage(
        callbackName: 'onPressed',
        expectedBehavior: 'Callback should be triggered when button is pressed',
        actualBehavior: 'Callback was not triggered',
        widgetName: 'SubmitButton',
        suggestion: 'Check if button is properly connected to the callback',
      );
      
      expect(message, contains('Callback: onPressed'));
      expect(message, contains('Expected: Callback should be triggered when button is pressed'));
      expect(message, contains('Actual: Callback was not triggered'));
      expect(message, contains('Widget: SubmitButton'));
      expect(message, contains('Suggestion: Check if button is properly connected to the callback'));
    });

    test('getStateVerificationErrorMessage should format state verification error message correctly', () {
      final message = TestDiagnosticsHelper.getStateVerificationErrorMessage(
        stateName: 'isLoading',
        expectedState: 'true',
        actualState: 'false',
        widgetName: 'LoadingIndicator',
        suggestion: 'Check if loading state is properly updated',
      );
      
      expect(message, contains('State: isLoading'));
      expect(message, contains('Expected: true'));
      expect(message, contains('Actual: false'));
      expect(message, contains('Widget: LoadingIndicator'));
      expect(message, contains('Suggestion: Check if loading state is properly updated'));
    });

    test('getThemeVerificationErrorMessage should format theme verification error message correctly', () {
      final message = TestDiagnosticsHelper.getThemeVerificationErrorMessage(
        expectedThemeMode: ThemeMode.dark,
        actualBrightness: Brightness.light,
        widgetName: 'ThemeableWidget',
        suggestion: 'Check if theme mode is properly applied',
      );
      
      expect(message, contains('Expected theme mode: dark'));
      expect(message, contains('Actual brightness: light'));
      expect(message, contains('Widget: ThemeableWidget'));
      expect(message, contains('Suggestion: Check if theme mode is properly applied'));
    });

    test('getChartDataValidationErrorMessage should format chart data validation error message correctly', () {
      final message = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
        dataType: 'EmotionalTrendPoint',
        issue: 'Invalid data points',
        invalidPointCount: 2,
        specificIssues: ['Point 1 has NaN intensity', 'Point 3 has invalid date'],
        suggestion: 'Validate data points before rendering chart',
      );
      
      expect(message, contains('Data type: EmotionalTrendPoint'));
      expect(message, contains('Issue: Invalid data points'));
      expect(message, contains('Invalid points: 2'));
      expect(message, contains('Point 1 has NaN intensity'));
      expect(message, contains('Point 3 has invalid date'));
      expect(message, contains('Suggestion: Validate data points before rendering chart'));
    });

    test('getTimeoutErrorMessage should format timeout error message correctly', () {
      final message = TestDiagnosticsHelper.getTimeoutErrorMessage(
        operation: 'Loading data',
        timeout: const Duration(seconds: 5),
        widgetName: 'DataLoader',
        suggestion: 'Check if data loading is taking too long',
      );
      
      expect(message, contains('Operation: Loading data'));
      expect(message, contains('Timeout: 5000ms'));
      expect(message, contains('Widget: DataLoader'));
      expect(message, contains('Suggestion: Check if data loading is taking too long'));
    });

    test('getPlatformServiceErrorMessage should format platform service error message correctly', () {
      final message = TestDiagnosticsHelper.getPlatformServiceErrorMessage(
        serviceName: 'LocalAuthService',
        expectedBehavior: 'Authentication should succeed',
        actualBehavior: 'Authentication failed',
        suggestion: 'Mock platform channel response for authentication',
      );
      
      expect(message, contains('Service: LocalAuthService'));
      expect(message, contains('Expected: Authentication should succeed'));
      expect(message, contains('Actual: Authentication failed'));
      expect(message, contains('Suggestion: Mock platform channel response for authentication'));
    });

    test('getBindingErrorMessage should format binding error message correctly', () {
      final message = TestDiagnosticsHelper.getBindingErrorMessage(
        expectedBehavior: 'Flutter binding should be initialized',
        actualBehavior: 'Flutter binding is not initialized',
        suggestion: 'Call TestWidgetsFlutterBinding.ensureInitialized() before the test',
      );
      
      expect(message, contains('Expected: Flutter binding should be initialized'));
      expect(message, contains('Actual: Flutter binding is not initialized'));
      expect(message, contains('Suggestion: Call TestWidgetsFlutterBinding.ensureInitialized() before the test'));
    });

    test('getAppErrorHandlingMessage should format app error handling message correctly', () {
      final error = AppError(
        type: ErrorType.network,
        category: ErrorCategory.connectivity,
        message: 'Network connection failed',
        userMessage: 'Unable to connect to the internet',
        stackTrace: StackTrace.current,
        timestamp: DateTime.now(),
        operationName: 'fetchData',
        component: 'DataService',
        isRecoverable: true,
      );
      
      final message = TestDiagnosticsHelper.getAppErrorHandlingMessage(
        error: error,
        expectedBehavior: 'Error should be handled with retry',
        actualBehavior: 'Error was not handled',
        suggestion: 'Implement proper error handling with retry mechanism',
      );
      
      expect(message, contains('Error type: network'));
      expect(message, contains('Error category: connectivity'));
      expect(message, contains('Expected: Error should be handled with retry'));
      expect(message, contains('Actual: Error was not handled'));
      expect(message, contains('Operation: fetchData'));
      expect(message, contains('Component: DataService'));
      expect(message, contains('Suggestion: Implement proper error handling with retry mechanism'));
    });

    test('createDiagnosticContext should create context with required fields', () {
      final context = TestDiagnosticsHelper.createDiagnosticContext(
        testName: 'MyTest',
        failureReason: 'Widget not found',
        additionalContext: {'widgetType': 'Button'},
      );
      
      expect(context['testName'], equals('MyTest'));
      expect(context['failureReason'], equals('Widget not found'));
      expect(context['timestamp'], isNotNull);
      expect(context['widgetType'], equals('Button'));
    });

    testWidgets('DiagnosticWidgetTester extension methods should not throw', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Test'),
          ),
        ),
      );
      
      // These should not throw exceptions
      tester.printCurrentWidgetTree(message: 'Test widget tree');
      
      // Test tap with diagnostics on existing widget
      await tester.tapWithDiagnostics(
        find.text('Test'),
        widgetDescription: 'Text widget',
      );
      
      // Test enter text with diagnostics
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(),
          ),
        ),
      );
      
      await tester.enterTextWithDiagnostics(
        find.byType(TextField),
        'Test input',
        widgetDescription: 'Text field',
      );
    });
  });
}