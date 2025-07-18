import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/services/analytics_service.dart';
import 'package:spiral_journal/constants/app_constants.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/services/theme_service.dart';
import 'package:spiral_journal/screens/main_screen.dart';
import 'package:spiral_journal/screens/auth_screen.dart';
import 'package:spiral_journal/screens/splash_screen.dart';
import 'package:spiral_journal/screens/pin_setup_screen.dart';
import 'package:spiral_journal/screens/pin_entry_screen.dart';
import 'package:spiral_journal/screens/privacy_dashboard_screen.dart';
import 'package:spiral_journal/screens/data_export_screen.dart';
import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/pin_auth_service.dart';
import 'package:spiral_journal/services/app_initializer.dart';
import 'package:spiral_journal/controllers/splash_screen_controller.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/utils/app_error_handler.dart';
import 'package:spiral_journal/config/api_key_setup.dart';
import 'package:spiral_journal/config/local_config.dart';

void main() async {
  final startTime = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handling system first
  AppErrorHandler.initialize();
  
  // Initialize local configuration system (replaces Firebase)
  await LocalConfig.initialize();
  
  // Initialize API keys (critical)
  await ApiKeySetup.initializeApiKeys();
  
  // Initialize local analytics service
  final analyticsInitFuture = _initializeLocalAnalytics();
  
  // Initialize critical services in parallel
  final themeServiceFuture = ThemeService().initialize();
  
  // Start the app UI while other services initialize in the background
  runApp(const SpiralJournalApp());
  
  // Continue initializing non-critical services in the background
  await Future.wait([
    analyticsInitFuture,
    themeServiceFuture,
    _initializeBackgroundServices(),
  ]);
  
  // Log app launch time
  final launchTime = DateTime.now().difference(startTime);
  AnalyticsService().logAppLaunchTime(launchTime);
}

/// Initialize local analytics service
Future<void> _initializeLocalAnalytics() async {
  try {
    // Initialize local analytics service
    await AnalyticsService().initialize();
    
    // Set up local error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log errors locally instead of sending to external services
      AnalyticsService().logError(
        details.exception.toString(),
        context: 'Flutter Error',
        stackTrace: details.stack,
      );
      
      // Still print to console for debugging
      FlutterError.presentError(details);
    };
    
  } catch (e) {
    // Continue without analytics if initialization fails
    debugPrint('Local analytics initialization failed: $e');
  }
}

/// Initialize non-critical background services
Future<void> _initializeBackgroundServices() async {
  try {
    // Initialize services in parallel for better performance
    await Future.wait([
      JournalService().initialize(),
      AIServiceManager().initialize(),
    ]);
  } catch (e) {
    debugPrint('Background service initialization error: $e');
    // Log error but don't crash the app
    AnalyticsService().logError('background_init_error', context: e.toString());
  }
}

class SpiralJournalApp extends StatelessWidget {
  const SpiralJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => JournalProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => CoreProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return FutureBuilder<ThemeMode>(
            future: themeService.getThemeMode(),
            builder: (context, snapshot) {
              final themeMode = snapshot.data ?? ThemeMode.system;
              return MaterialApp(
                title: 'Spiral Journal',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                home: const AuthWrapper(),
                routes: {
                  '/auth': (context) => const AuthScreen(),
                  '/main': (context) => const MainScreen(),
                  '/pin-setup': (context) => const PinSetupScreen(),
                  '/pin-entry': (context) => const PinEntryScreen(),
                  '/privacy-dashboard': (context) => const PrivacyDashboardScreen(),
                  '/data-export': (context) => const DataExportScreen(),
                },
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Focused manager classes
  final PinAuthService _pinAuthService = PinAuthService();
  final SplashScreenController _splashController = SplashScreenController();
  final AppInitializer _appInitializer = AppInitializer();
  
  // Simplified state management
  bool _showSplash = true;
  bool _isLoading = true;
  bool _needsPinSetup = false;
  bool _needsPinEntry = false;
  String? _initializationError;
  
  // Initialization state
  InitializationResult? _initializationResult;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Simplified initialization using the new architecture
  Future<void> _initializeApp() async {
    debugPrint('AuthWrapper: Starting app initialization');
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _initializationError = null;
    });

    try {
      // Step 1: Initialize the application
      debugPrint('AuthWrapper: Step 1 - Initializing application');
      final initResult = await _appInitializer.initialize();
      _initializationResult = initResult;
      debugPrint('AuthWrapper: App initialization result: ${initResult.success}');

      if (!initResult.success) {
        debugPrint('AuthWrapper: App initialization failed: ${initResult.errorMessage}');
        _handleInitializationFailure(initResult);
        return;
      }

      // Step 2: Check PIN authentication state
      debugPrint('AuthWrapper: Step 2 - Checking PIN authentication state');
      final pinAuthStatus = await _pinAuthService.getAuthStatus();
      debugPrint('AuthWrapper: PIN status - hasPinSet: ${pinAuthStatus.hasPinSet}, isFirstLaunch: ${pinAuthStatus.isFirstLaunch}');

      // Step 3: Check splash screen settings
      debugPrint('AuthWrapper: Step 3 - Checking splash screen settings');
      final shouldShowSplash = await _splashController.shouldShowSplash();
      debugPrint('AuthWrapper: Should show splash: $shouldShowSplash');

      // Step 4: Update UI state based on results
      if (mounted) {
        final needsPinSetup = !pinAuthStatus.hasPinSet || pinAuthStatus.isFirstLaunch;
        final needsPinEntry = pinAuthStatus.hasPinSet && !pinAuthStatus.isFirstLaunch;
        
        debugPrint('AuthWrapper: Final state - needsPinSetup: $needsPinSetup, needsPinEntry: $needsPinEntry, showSplash: $shouldShowSplash');
        
        setState(() {
          _needsPinSetup = needsPinSetup;
          _needsPinEntry = needsPinEntry;
          _showSplash = shouldShowSplash;
          _isLoading = false;
        });
      }

    } catch (e) {
      debugPrint('AuthWrapper: Initialization error: $e');
      _appInitializer.handleInitializationError(e);
      
      if (mounted) {
        setState(() {
          _initializationError = e.toString();
          _needsPinSetup = true; // Safe default
          _needsPinEntry = false; // Safe default
          _showSplash = true; // Safe default
          _isLoading = false;
        });
      }
    }
  }

  /// Handle initialization failure with appropriate UI state
  void _handleInitializationFailure(InitializationResult result) {
    if (mounted) {
      setState(() {
        _initializationError = result.errorMessage;
        _needsPinSetup = true; // Safe default
        _needsPinEntry = false; // Safe default
        _showSplash = true; // Safe default
        _isLoading = false;
      });
    }
  }

  /// Called when splash screen completes
  void _onSplashComplete() {
    debugPrint('AuthWrapper: Splash screen completed, transitioning to main app');
    _splashController.onSplashComplete();
    
    if (mounted) {
      debugPrint('AuthWrapper: Setting _showSplash to false');
      setState(() {
        _showSplash = false;
      });
    } else {
      debugPrint('AuthWrapper: Widget not mounted, cannot update splash state');
    }
  }

  /// Retry initialization after failure
  void _retryInitialization() {
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper: Building widget - showSplash: $_showSplash, isLoading: $_isLoading, hasError: ${_initializationError != null}');
    
    // Show splash screen if enabled and needed
    if (_showSplash) {
      debugPrint('AuthWrapper: Displaying splash screen');
      return SplashScreen(
        onComplete: _onSplashComplete,
        displayDuration: const Duration(seconds: 2), // Shorter duration
      );
    }

    // Show loading indicator during initialization
    if (_isLoading) {
      debugPrint('AuthWrapper: Displaying loading screen');
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundPrimary(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.getPrimaryColor(context),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state with retry option if initialization failed
    if (_initializationError != null) {
      debugPrint('AuthWrapper: Displaying error screen');
      return _buildErrorScreen();
    }

    // Navigate to appropriate screen based on PIN authentication state
    // In debug mode, skip PIN authentication to allow easy access for development
    if (kDebugMode) {
      debugPrint('AuthWrapper: Debug mode - displaying MainScreen');
      return const MainScreen();
    }
    
    if (_needsPinSetup) {
      debugPrint('AuthWrapper: Displaying PIN setup screen');
      return const PinSetupScreen();
    } else if (_needsPinEntry) {
      debugPrint('AuthWrapper: Displaying PIN entry screen');
      return const PinEntryScreen();
    } else {
      debugPrint('AuthWrapper: Displaying main screen');
      return const MainScreen();
    }
  }

  /// Builds the error screen with retry functionality
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundPrimary(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: AppConstants.largeIconSize,
                color: AppTheme.getPrimaryColor(context),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Initialization Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.getTextPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                _initializationResult?.timedOut == true
                    ? 'The app took too long to start. This might be due to a slow connection or system issue.'
                    : 'There was a problem starting the app. This might be due to a temporary issue.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton(
                onPressed: _retryInitialization,
                child: const Text('Retry'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextButton(
                onPressed: () {
                  // Skip to auth screen as fallback
                  Navigator.of(context).pushReplacementNamed('/auth');
                },
                child: Text(
                  'Continue Anyway',
                  style: AppTheme.getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.getTextSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
