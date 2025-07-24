import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../lib/services/settings_service.dart';
import '../../lib/services/journal_service.dart';
import '../../lib/services/theme_service.dart';
import '../../lib/main.dart';

/// Test utility class for managing service lifecycle in tests
class TestServiceManager {
  static final Map<String, dynamic> _activeServices = {};
  static final List<String> _disposedServices = [];

  /// Creates a test-scoped SettingsService instance
  static SettingsService createTestSettingsService() {
    final service = SettingsService();
    _activeServices['settings'] = service;
    return service;
  }

  /// Creates a test-scoped JournalService instance
  static JournalService createTestJournalService() {
    final service = JournalService();
    _activeServices['journal'] = service;
    return service;
  }

  /// Creates a test-scoped ThemeService instance
  static ThemeService createTestThemeService() {
    final service = ThemeService();
    _activeServices['theme'] = service;
    return service;
  }

  /// Disposes all test services properly
  static void disposeTestServices() {
    for (final entry in _activeServices.entries) {
      try {
        if (entry.value is ChangeNotifier) {
          final notifier = entry.value as ChangeNotifier;
          if (!_disposedServices.contains(entry.key)) {
            notifier.dispose();
            _disposedServices.add(entry.key);
          }
        }
      } catch (e) {
        // Service already disposed, ignore
        debugPrint('Service ${entry.key} already disposed: $e');
      }
    }
    _activeServices.clear();
  }

  /// Creates a test app with proper provider setup
  static Widget createTestApp({required Widget child}) {
    return MaterialApp(
      home: child,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    );
  }

  /// Creates a test app with providers for integration tests
  static Widget createTestAppWithProviders({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>(
          create: (_) => createTestSettingsService(),
          lazy: false,
        ),
        Provider<JournalService>(
          create: (_) => createTestJournalService(),
        ),
        ChangeNotifierProvider<ThemeService>(
          create: (_) => createTestThemeService(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        home: child,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      ),
    );
  }

  /// Checks if a service is still active and not disposed
  static bool isServiceActive(String serviceId) {
    return _activeServices.containsKey(serviceId) && 
           !_disposedServices.contains(serviceId);
  }

  /// Clears all service tracking (for test cleanup)
  static void clearServiceTracking() {
    _activeServices.clear();
    _disposedServices.clear();
  }
}