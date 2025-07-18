import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/widgets/error_display_widget.dart';
import 'package:spiral_journal/utils/app_error_handler.dart';

// Helper function to pump a widget with theme
Future<void> pumpWidgetWithTheme(
  WidgetTester tester,
  Widget widget, {
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final app = MaterialApp(
    theme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
    themeMode: themeMode,
    home: widget,
  );

  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  group('ErrorDisplayWidget Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    late AppError testError;

    setUp(() {
      testError = AppError(
        type: ErrorType.network,
        category: ErrorCategory.connectivity,
        message: 'Network connection failed',
        userMessage: 'Unable to connect to the internet. Please check your connection.',
        stackTrace: StackTrace.current,
        timestamp: DateTime.now(),
        operationName: 'test_operation',
        component: 'test_component',
        isRecoverable: true,
      );
    });

    testWidgets('should display error message', (WidgetTester tester) async {
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(error: testError),
        ),
      );

      // Verify ErrorDisplayWidget is rendered properly
      expect(find.byType(ErrorDisplayWidget), findsOneWidget);

      // Verify error message is displayed with specific text matching
      expect(find.text(testError.userMessage), findsOneWidget);
    });

    testWidgets('should show retry button when onRetry is provided', (WidgetTester tester) async {
      bool retryCalled = false;
      
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(
            error: testError,
            onRetry: () {
              retryCalled = true;
            },
          ),
        ),
      );
      
      // Find the retry button
      final retryButton = find.text('Try Again');
      expect(retryButton, findsOneWidget, reason: 'Retry button with text "Try Again" should be visible');
      
      // Test retry functionality
      await tester.tap(retryButton);
      await tester.pumpAndSettle();
      
      // Verify callback was called
      expect(retryCalled, isTrue, reason: 'onRetry callback should be called when retry button is tapped');
    });

    testWidgets('should not show retry button when onRetry is null', (WidgetTester tester) async {
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(error: testError),
        ),
      );

      // Verify retry button is not displayed when onRetry is null
      final retryButton = find.text('Try Again');
      expect(retryButton, findsNothing, reason: 'Retry button should not be visible when onRetry callback is not provided');
    });

    testWidgets('should display appropriate icon for error category', (WidgetTester tester) async {
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(error: testError),
        ),
      );

      // Verify connectivity icon is displayed for network error
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('should work in both light and dark themes', (WidgetTester tester) async {
      // Test light theme
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(error: testError),
        ),
        themeMode: ThemeMode.light,
      );

      expect(find.text(testError.userMessage), findsOneWidget);

      // Test dark theme
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(error: testError),
        ),
        themeMode: ThemeMode.dark,
      );

      expect(find.text(testError.userMessage), findsOneWidget);
    });

    testWidgets('should handle different error categories', (WidgetTester tester) async {
      final storageError = AppError(
        type: ErrorType.database,
        category: ErrorCategory.storage,
        message: 'Database error',
        userMessage: 'Unable to save your data.',
        stackTrace: StackTrace.current,
        timestamp: DateTime.now(),
        isRecoverable: true,
      );

      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(error: storageError),
        ),
      );

      // Verify storage error message is displayed
      expect(find.text(storageError.userMessage), findsOneWidget);
      
      // Verify storage icon is displayed for database error category
      expect(find.byIcon(Icons.storage), findsOneWidget);
    });

    testWidgets('should show detailed error information when enabled', (WidgetTester tester) async {
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(
            error: testError,
            showDetails: true,
          ),
        ),
      );

      // Verify operation details are shown when showDetails is enabled
      expect(find.textContaining('Operation: test_operation'), findsOneWidget);
    });

    testWidgets('should handle dismissible errors', (WidgetTester tester) async {
      bool dismissCalled = false;
      
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(
            error: testError,
            onDismiss: () {
              dismissCalled = true;
            },
          ),
        ),
      );

      // Verify dismiss button is displayed
      final dismissButton = find.byIcon(Icons.close);
      expect(dismissButton, findsOneWidget);
      
      // Test dismiss functionality
      await tester.tap(dismissButton);
      await tester.pumpAndSettle();
      
      // Verify callback was called
      expect(dismissCalled, isTrue, reason: 'onDismiss callback should be called when dismiss button is tapped');
    });

    testWidgets('should handle non-recoverable errors', (WidgetTester tester) async {
      final nonRecoverableError = AppError(
        type: ErrorType.platform,
        category: ErrorCategory.system,
        message: 'System error',
        userMessage: 'A system error occurred.',
        stackTrace: StackTrace.current,
        timestamp: DateTime.now(),
        isRecoverable: false,
      );

      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(
            error: nonRecoverableError,
            onRetry: () {},
          ),
        ),
      );

      // Verify retry button is not shown for non-recoverable errors
      expect(find.text('Try Again'), findsNothing);
      
      // Verify OK button is shown instead for non-recoverable errors
      expect(find.text('OK'), findsOneWidget);
    });
    
    testWidgets('should show error title based on category', (WidgetTester tester) async {
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(error: testError),
        ),
      );

      // Verify the correct error title is displayed for connectivity errors
      expect(find.text('Connection Issue'), findsOneWidget);
      
      // Test with a different error category
      final securityError = AppError(
        type: ErrorType.authentication,
        category: ErrorCategory.security,
        message: 'Authentication failed',
        userMessage: 'Unable to authenticate. Please try again.',
        stackTrace: StackTrace.current,
        timestamp: DateTime.now(),
        isRecoverable: true,
      );
      
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(error: securityError),
        ),
      );
      
      // Verify the correct error title is displayed for security errors
      expect(find.text('Security Error'), findsOneWidget);
    });
    
    testWidgets('should use appropriate colors for different error categories', (WidgetTester tester) async {
      // This test verifies that different error categories use appropriate colors
      // We can't easily test colors directly in widget tests, but we can verify the widget builds correctly
      
      // Test with connectivity error
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(error: testError),
        ),
      );
      
      expect(find.byType(ErrorDisplayWidget), findsOneWidget);
      
      // Test with security error
      final securityError = AppError(
        type: ErrorType.authentication,
        category: ErrorCategory.security,
        message: 'Authentication failed',
        userMessage: 'Unable to authenticate. Please try again.',
        stackTrace: StackTrace.current,
        timestamp: DateTime.now(),
        isRecoverable: true,
      );
      
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(error: securityError),
        ),
      );
      
      expect(find.byType(ErrorDisplayWidget), findsOneWidget);
    });
    
    testWidgets('should handle errors with component information', (WidgetTester tester) async {
      final errorWithComponent = AppError(
        type: ErrorType.database,
        category: ErrorCategory.storage,
        message: 'Database error',
        userMessage: 'Unable to save your data.',
        stackTrace: StackTrace.current,
        timestamp: DateTime.now(),
        operationName: 'save_journal',
        component: 'JournalRepository',
        isRecoverable: true,
      );
      
      await pumpWidgetWithTheme(
        tester,
        Scaffold(
          body: ErrorDisplayWidget(
            error: errorWithComponent,
            showDetails: true,
          ),
        ),
      );
      
      // Verify operation details are shown
      expect(find.textContaining('Operation: save_journal'), findsOneWidget);
    });
  });
  
  group('ErrorSnackBar Tests', () {
    testWidgets('should show error snackbar with message', (WidgetTester tester) async {
      final error = AppError(
        type: ErrorType.network,
        category: ErrorCategory.connectivity,
        message: 'Network connection failed',
        userMessage: 'Connection error',
        stackTrace: StackTrace.current,
        timestamp: DateTime.now(),
        isRecoverable: true,
      );
      
      await pumpWidgetWithTheme(
        tester,
        Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    ErrorSnackBar.show(context, error);
                  },
                  child: const Text('Show Error'),
                ),
              ),
            );
          },
        ),
      );
      
      // Tap button to show snackbar
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();
      
      // Verify snackbar is shown with error message
      expect(find.text('Connection error'), findsOneWidget);
    });
  });
  
  group('ErrorDialog Tests', () {
    testWidgets('should show error dialog with message', (WidgetTester tester) async {
      final error = AppError(
        type: ErrorType.network,
        category: ErrorCategory.connectivity,
        message: 'Network connection failed',
        userMessage: 'Connection error',
        stackTrace: StackTrace.current,
        timestamp: DateTime.now(),
        isRecoverable: true,
      );
      
      await pumpWidgetWithTheme(
        tester,
        Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    ErrorDialog.show(context, error);
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            );
          },
        ),
      );
      
      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      // Verify dialog is shown with error message
      expect(find.text('Connection error'), findsOneWidget);
      expect(find.text('Connection Issue'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}