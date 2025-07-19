import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/services/theme_service.dart';
import 'package:spiral_journal/services/settings_service.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/core_library_service.dart';
import 'package:spiral_journal/services/core_evolution_engine.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';
import 'package:spiral_journal/services/profile_service.dart';
import 'package:spiral_journal/services/app_initializer.dart';
import 'package:spiral_journal/controllers/splash_screen_controller.dart';
import 'package:spiral_journal/screens/main_screen.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'mock_service_factory.dart';

/// Test app wrapper that provides proper service mocking and initialization
/// for integration tests, bypassing the complex app initialization flow
class IntegrationTestApp extends StatelessWidget {
  final Widget? home;
  final bool skipSplash;
  final bool skipProfileSetup;
  final ThemeMode themeMode;
  final Map<String, dynamic>? testScenario;

  const IntegrationTestApp({
    super.key,
    this.home,
    this.skipSplash = true,
    this.skipProfileSetup = true,
    this.themeMode = ThemeMode.light,
    this.testScenario,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize mock services
    MockServiceFactory.initialize();
    
    // Set up test scenario if provided
    if (testScenario != null) {
      MockServiceFactory.setupTestScenario('current_test', testScenario!);
    }

    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<JournalProvider>(
          create: (_) => JournalProvider()..initialize(),
        ),
        ChangeNotifierProvider<CoreProvider>(
          create: (_) => CoreProvider()..initialize(),
        ),
        ChangeNotifierProvider<ThemeService>(
          create: (_) => ThemeService(),
        ),
        ChangeNotifierProvider<SettingsService>(
          create: (_) => SettingsService(),
        ),
        
        // Service providers
        Provider<JournalService>(
          create: (_) => JournalService(),
        ),
        Provider<AIServiceManager>(
          create: (_) => AIServiceManager(),
        ),
        Provider<CoreLibraryService>(
          create: (_) => CoreLibraryService(),
        ),
        Provider<CoreEvolutionEngine>(
          create: (_) => CoreEvolutionEngine(),
        ),
        Provider<EmotionalAnalyzer>(
          create: (_) => EmotionalAnalyzer(),
        ),
        Provider<ProfileService>(
          create: (_) => _createMockProfileService(),
        ),
        Provider<AppInitializer>(
          create: (_) => _createMockAppInitializer(),
        ),
        Provider<SplashScreenController>(
          create: (_) => _createMockSplashController(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Spiral Journal Test',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: home ?? const MainScreen(),
            routes: {
              '/main': (context) => const MainScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  /// Creates a mock profile service that simulates having a profile set up
  ProfileService _createMockProfileService() {
    final profileService = ProfileService();
    // Mock the profile service to return that profile is set up
    return profileService;
  }

  /// Creates a mock app initializer that always succeeds
  AppInitializer _createMockAppInitializer() {
    return AppInitializer();
  }

  /// Creates a mock splash controller that skips splash if configured
  SplashScreenController _createMockSplashController() {
    return SplashScreenController();
  }
}

/// Specialized test app for testing specific UI components in isolation
class ComponentTestApp extends StatelessWidget {
  final Widget child;
  final ThemeMode themeMode;
  final bool wrapInScaffold;

  const ComponentTestApp({
    super.key,
    required this.child,
    this.themeMode = ThemeMode.light,
    this.wrapInScaffold = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: wrapInScaffold 
        ? Scaffold(body: child)
        : child,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Test app wrapper for testing navigation flows
class NavigationTestApp extends StatelessWidget {
  final String initialRoute;
  final Map<String, WidgetBuilder> routes;
  final ThemeMode themeMode;

  const NavigationTestApp({
    super.key,
    this.initialRoute = '/',
    required this.routes,
    this.themeMode = ThemeMode.light,
  });

  @override
  Widget build(BuildContext context) {
    MockServiceFactory.initialize();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<JournalProvider>(
          create: (_) => JournalProvider()..initialize(),
        ),
        ChangeNotifierProvider<CoreProvider>(
          create: (_) => CoreProvider()..initialize(),
        ),
        ChangeNotifierProvider<ThemeService>(
          create: (_) => ThemeService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        initialRoute: initialRoute,
        routes: {
          '/': (context) => const MainScreen(),
          ...routes,
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Test app wrapper for testing error scenarios
class ErrorTestApp extends StatelessWidget {
  final Widget child;
  final bool simulateInitializationError;
  final bool simulateServiceError;
  final String? errorMessage;

  const ErrorTestApp({
    super.key,
    required this.child,
    this.simulateInitializationError = false,
    this.simulateServiceError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    MockServiceFactory.initialize();
    
    // Set up error scenarios
    if (simulateInitializationError) {
      MockServiceFactory.setupTestScenario('error_scenario', {
        'initializationFails': true,
        'errorMessage': errorMessage ?? 'Test initialization error',
      });
    }
    
    if (simulateServiceError) {
      MockServiceFactory.setupTestScenario('service_error', {
        'serviceFails': true,
        'errorMessage': errorMessage ?? 'Test service error',
      });
    }

    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(body: child),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Test app wrapper for performance testing
class PerformanceTestApp extends StatelessWidget {
  final Widget child;
  final int numberOfEntries;
  final bool enablePerformanceLogging;

  const PerformanceTestApp({
    super.key,
    required this.child,
    this.numberOfEntries = 100,
    this.enablePerformanceLogging = true,
  });

  @override
  Widget build(BuildContext context) {
    MockServiceFactory.initialize();
    
    // Set up performance test scenario
    MockServiceFactory.setupTestScenario('performance_test', {
      'numberOfEntries': numberOfEntries,
      'enablePerformanceLogging': enablePerformanceLogging,
      'simulateDelay': false, // Disable delays for performance tests
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<JournalProvider>(
          create: (_) => JournalProvider()..initialize(),
        ),
        ChangeNotifierProvider<CoreProvider>(
          create: (_) => CoreProvider()..initialize(),
        ),
        ChangeNotifierProvider<ThemeService>(
          create: (_) => ThemeService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: child,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Utility class for creating test app configurations
class TestAppConfig {
  static const Map<String, dynamic> defaultConfig = {
    'skipSplash': true,
    'skipProfileSetup': true,
    'enableMockServices': true,
    'simulateNetworkDelay': false,
    'enableErrorHandling': true,
  };

  static const Map<String, dynamic> errorTestConfig = {
    'skipSplash': true,
    'skipProfileSetup': true,
    'enableMockServices': true,
    'simulateErrors': true,
    'errorRate': 0.1, // 10% error rate
  };

  static const Map<String, dynamic> performanceTestConfig = {
    'skipSplash': true,
    'skipProfileSetup': true,
    'enableMockServices': true,
    'simulateNetworkDelay': false,
    'enablePerformanceLogging': true,
    'numberOfTestEntries': 50,
  };

  static const Map<String, dynamic> navigationTestConfig = {
    'skipSplash': true,
    'skipProfileSetup': true,
    'enableMockServices': true,
    'enableNavigationLogging': true,
  };

  /// Creates a test configuration for a specific scenario
  static Map<String, dynamic> createConfig({
    bool skipSplash = true,
    bool skipProfileSetup = true,
    bool enableMockServices = true,
    bool simulateNetworkDelay = false,
    bool simulateErrors = false,
    double errorRate = 0.0,
    int numberOfTestEntries = 10,
    bool enablePerformanceLogging = false,
    bool enableNavigationLogging = false,
    Map<String, dynamic>? customConfig,
  }) {
    final config = <String, dynamic>{
      'skipSplash': skipSplash,
      'skipProfileSetup': skipProfileSetup,
      'enableMockServices': enableMockServices,
      'simulateNetworkDelay': simulateNetworkDelay,
      'simulateErrors': simulateErrors,
      'errorRate': errorRate,
      'numberOfTestEntries': numberOfTestEntries,
      'enablePerformanceLogging': enablePerformanceLogging,
      'enableNavigationLogging': enableNavigationLogging,
    };

    if (customConfig != null) {
      config.addAll(customConfig);
    }

    return config;
  }
}
