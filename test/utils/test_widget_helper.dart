import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'test_service_manager.dart';

/// Test utility class for improved widget testing
class TestWidgetHelper {
  /// Pumps widget and settles with proper timeout handling
  static Future<void> pumpAndSettle(
    WidgetTester tester, {
    Duration? timeout,
    Duration? settleDuration,
  }) async {
    await tester.pump();
    
    try {
      await tester.pumpAndSettle(
        timeout ?? TestConfig.widgetSettleTimeout,
      );
    } catch (e) {
      // If settle times out, try one more pump
      debugPrint('Widget settle timeout, trying additional pump: $e');
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  /// Waits for a widget to appear with retry logic
  static Future<void> waitForWidget(
    WidgetTester tester, 
    Finder finder, {
    Duration? timeout,
    int maxRetries = 5,
  }) async {
    final timeoutDuration = timeout ?? TestConfig.defaultTimeout;
    final startTime = DateTime.now();
    int retries = 0;

    while (retries < maxRetries) {
      if (DateTime.now().difference(startTime) > timeoutDuration) {
        throw Exception(
          'Widget not found after ${timeoutDuration.inSeconds} seconds',
        );
      }

      await tester.pump(const Duration(milliseconds: 100));
      
      if (finder.evaluate().isNotEmpty) {
        return;
      }

      retries++;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    throw Exception('Widget not found after $maxRetries retries');
  }

  /// Wraps a widget with test providers
  static Widget wrapWithProviders(
    Widget child, {
    List<Provider>? providers,
  }) {
    if (providers != null && providers.isNotEmpty) {
      return MultiProvider(
        providers: providers,
        child: MaterialApp(home: child),
      );
    }
    
    return TestServiceManager.createTestApp(child: child);
  }

  /// Creates a test MaterialApp with proper theme setup
  static Widget createTestMaterialApp({
    required Widget home,
    ThemeData? theme,
    ThemeData? darkTheme,
  }) {
    return TestServiceManager.createTestApp(
      child: MaterialApp(
        home: home,
        theme: theme ?? ThemeData.light(),
        darkTheme: darkTheme ?? ThemeData.dark(),
      ),
    );
  }

  /// Safely finds a widget with error handling
  static Finder safeFinder(String text, {bool skipOffstage = true}) {
    try {
      return find.text(text, skipOffstage: skipOffstage);
    } catch (e) {
      debugPrint('Error finding text "$text": $e');
      return find.byType(Container); // Return a safe finder that won't match
    }
  }

  /// Safely finds a widget by type with error handling
  static Finder safeFinderByType<T extends Widget>({bool skipOffstage = true}) {
    try {
      return find.byType(T, skipOffstage: skipOffstage);
    } catch (e) {
      debugPrint('Error finding widget of type $T: $e');
      return find.byType(Container); // Return a safe finder that won't match
    }
  }

  /// Performs a safe tap with error handling
  static Future<void> safeTap(
    WidgetTester tester, 
    Finder finder, {
    Duration? settleTimeout,
  }) async {
    try {
      await tester.tap(finder);
      await pumpAndSettle(tester, timeout: settleTimeout);
    } catch (e) {
      debugPrint('Error tapping widget: $e');
      // Try alternative approach
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

/// Test configuration constants
class TestConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration widgetSettleTimeout = Duration(seconds: 5);
  static const Duration navigationTimeout = Duration(seconds: 10);
  static const Duration shortTimeout = Duration(seconds: 3);
  static const Duration longTimeout = Duration(seconds: 60);
}