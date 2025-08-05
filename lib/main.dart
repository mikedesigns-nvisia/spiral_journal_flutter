import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/services/analytics_service.dart';
import 'package:spiral_journal/core/app_constants.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/services/theme_service.dart';
import 'package:spiral_journal/screens/main_screen.dart';
import 'package:spiral_journal/screens/splash_screen.dart';
import 'package:spiral_journal/screens/profile_setup_screen.dart';
import 'package:spiral_journal/screens/privacy_dashboard_screen.dart';
import 'package:spiral_journal/screens/data_export_screen.dart';
import 'package:spiral_journal/screens/onboarding_screen.dart';
import 'package:spiral_journal/screens/core_library_screen.dart';

import 'package:spiral_journal/services/journal_service.dart';
import 'package:spiral_journal/services/ai_service_manager.dart';
import 'package:spiral_journal/services/ios_background_scheduler.dart';
import 'package:spiral_journal/services/profile_service.dart';
import 'package:spiral_journal/services/app_initializer.dart';
import 'package:spiral_journal/services/settings_service.dart';
// PIN auth service removed - using biometrics-only authentication
import 'package:spiral_journal/services/navigation_service.dart';
import 'package:spiral_journal/services/core_navigation_context_service.dart';
import 'package:spiral_journal/controllers/splash_screen_controller.dart';
import 'package:spiral_journal/controllers/onboarding_controller.dart';
import 'package:spiral_journal/providers/journal_provider.dart';
import 'package:spiral_journal/providers/core_provider_refactored.dart';
import 'package:spiral_journal/providers/emotional_mirror_provider.dart';
import 'package:spiral_journal/utils/app_error_handler.dart';
import 'package:spiral_journal/config/api_key_setup.dart';
import 'package:spiral_journal/config/local_config.dart';
import 'package:spiral_journal/services/production_environment_loader.dart';
// Debug services removed - using local fallback processing
import 'package:spiral_journal/widgets/app_background.dart';
import 'package:spiral_journal/utils/ios_theme_enforcer.dart';
import 'package:google_fonts/google_fonts.dart';
void main() async {
  final startTime = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handling system first
  AppErrorHandler.initialize();
  
  // CRITICAL: Load environment variables from .env file BEFORE any service initialization
  debugPrint('🔧 Loading environment variables from .env file...');
  await ProductionEnvironmentLoader.ensureLoaded();
  debugPrint('✅ Environment variables loaded successfully');
  
  // Initialize local configuration system (replaces Firebase)
  await LocalConfig.initialize();
  
  // Initialize API keys (critical)
  await ApiKeySetup.initializeApiKeys();
  
  // Preload Google Fonts to prevent network errors
  await _preloadGoogleFonts();
  
  // Initialize local analytics service
  final analyticsInitFuture = _initializeLocalAnalytics();
  
  // Initialize critical services in parallel
  final themeServiceFuture = ThemeService().initialize();
  
  // Initialize iOS theme enforcer synchronously
  iOSThemeEnforcer.initialize();
  
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
  
  debugPrint('App launch completed');
}

/// Preload Google Fonts to prevent network errors during runtime
Future<void> _preloadGoogleFonts() async {
  try {
    debugPrint('Preloading Google Fonts...');
    
    // Preload the Noto Sans JP font family and Lora serif font
    await GoogleFonts.pendingFonts([
      // Noto Sans JP for body text and UI elements
      GoogleFonts.notoSansJp(),
      GoogleFonts.notoSansJp(fontWeight: FontWeight.w300),
      GoogleFonts.notoSansJp(fontWeight: FontWeight.w400),
      GoogleFonts.notoSansJp(fontWeight: FontWeight.w500),
      GoogleFonts.notoSansJp(fontWeight: FontWeight.w600),
      GoogleFonts.notoSansJp(fontWeight: FontWeight.w700),
      // Lora serif for headings and display text
      GoogleFonts.lora(),
      GoogleFonts.lora(fontWeight: FontWeight.w300),
      GoogleFonts.lora(fontWeight: FontWeight.w400),
      GoogleFonts.lora(fontWeight: FontWeight.w500),
      GoogleFonts.lora(fontWeight: FontWeight.w600),
      GoogleFonts.lora(fontWeight: FontWeight.w700),
    ]);
    
    debugPrint('Google Fonts preloaded successfully');
  } catch (e) {
    debugPrint('Failed to preload Google Fonts (will use fallback): $e');
    // Continue with app initialization - fallbacks will handle this
  }
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
    // Initialize services sequentially to ensure proper dependency order
    debugPrint('🔧 Initializing background services...');
    
    // Initialize JournalService first (no dependencies)
    debugPrint('📋 Initializing JournalService...');
    await JournalService().initialize();
    debugPrint('✅ JournalService initialized');
    
    // Initialize AIServiceManager (depends on environment being loaded)
    debugPrint('📋 Initializing AIServiceManager...');
    try {
      await AIServiceManager().initialize();
      debugPrint('✅ AIServiceManager initialized successfully');
    } catch (e) {
      debugPrint('⚠️  AIServiceManager initialization failed: $e');
      debugPrint('   App will continue with fallback AI analysis');
      // Don't rethrow - app can continue without AI
    }
    
    // BatchAIAnalysisService initialization removed - using local fallback processing
    debugPrint('📋 Local fallback processing prioritized - batch AI analysis disabled');
    debugPrint('✅ Local processing is active and ready');
    
    // Initialize IOSBackgroundScheduler (independent)
    debugPrint('📋 Initializing IOSBackgroundScheduler...');
    try {
      await IOSBackgroundScheduler().initialize();
      debugPrint('✅ IOSBackgroundScheduler initialized');
    } catch (e) {
      debugPrint('⚠️  IOSBackgroundScheduler initialization failed: $e');
      // Don't rethrow - app can continue without background scheduling
    }
    
    // Debug Command Service initialization removed - using local fallback processing
    debugPrint('📋 Debug services disabled - local fallback processing prioritized');
    debugPrint('✅ Production-ready local processing active');
    
    // Troubleshooting Guide Service initialization removed - using local fallback processing
    debugPrint('📋 Troubleshooting services disabled - local fallback processing prioritized');
    debugPrint('✅ Streamlined initialization complete');
    
    debugPrint('✅ Background services initialization completed');
  } catch (e) {
    debugPrint('❌ Critical background service initialization error: $e');
    // Log error but don't crash the app
    AnalyticsService().logError('background_init_error', context: e.toString());
  }
}

class SpiralJournalApp extends StatelessWidget {
  const SpiralJournalApp({super.key});

  /// Builds core detail route with navigation context
  static Widget _buildCoreDetailRoute(BuildContext context) {
    final args = CoreNavigationContextService.extractNavigationArguments(
      ModalRoute.of(context)?.settings ?? const RouteSettings(),
    );
    
    final coreId = args?['coreId'] as String?;
    // Note: navigationContext will be used when we implement dedicated core detail screen
    
    if (coreId == null) {
      // Fallback to core library if no core ID provided
      return iOSThemeEnforcer.needsEnforcement()
          ? const CoreLibraryScreen().withiOSThemeEnforcement(context)
          : const CoreLibraryScreen();
    }
    
    // For now, navigate to core library with the specific core highlighted
    // This will be enhanced when we implement the dedicated core detail screen
    return iOSThemeEnforcer.needsEnforcement()
        ? const CoreLibraryScreen().withiOSThemeEnforcement(context)
        : const CoreLibraryScreen();
  }

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
          create: (context) => EmotionalMirrorProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsService()..initialize(),
        ),
        // PIN auth service provider removed - using biometrics-only authentication
        Provider<NavigationService>(
          create: (context) => NavigationService(),
        ),
        Provider<CoreNavigationContextService>(
          create: (context) => CoreNavigationContextService(),
        ),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settingsService, child) {
          return FutureBuilder<ThemeMode>(
            future: settingsService.getThemeMode(),
            builder: (context, snapshot) {
              final themeMode = snapshot.data ?? ThemeMode.system;
              return MaterialApp(
                title: 'Spiral Journal',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                builder: (context, child) {
                  // Enforce iOS theme
                  iOSThemeEnforcer.updateSystemUIOverlay(context);
                  return iOSThemeEnforcer.enforceTheme(
                    context,
                    child ?? const SizedBox.shrink(),
                  );
                },
                home: const AuthWrapper(),
                navigatorKey: NavigationService.navigatorKey,
                routes: {
                  '/main': (context) => iOSThemeEnforcer.needsEnforcement() 
                    ? const MainScreen().withiOSThemeEnforcement(context)
                    : const MainScreen(),
                  '/onboarding': (context) => iOSThemeEnforcer.needsEnforcement()
                    ? const OnboardingScreen().withiOSThemeEnforcement(context)
                    : const OnboardingScreen(),
                  '/profile-setup': (context) => iOSThemeEnforcer.needsEnforcement()
                    ? const ProfileSetupScreen().withiOSThemeEnforcement(context)
                    : const ProfileSetupScreen(),

                  '/privacy-dashboard': (context) => iOSThemeEnforcer.needsEnforcement()
                    ? const PrivacyDashboardScreen().withiOSThemeEnforcement(context)
                    : const PrivacyDashboardScreen(),
                  '/data-export': (context) => iOSThemeEnforcer.needsEnforcement()
                    ? const DataExportScreen().withiOSThemeEnforcement(context)
                    : const DataExportScreen(),
                  '/core-library': (context) => iOSThemeEnforcer.needsEnforcement()
                    ? const CoreLibraryScreen().withiOSThemeEnforcement(context)
                    : const CoreLibraryScreen(),
                  '/core-detail': (context) => _buildCoreDetailRoute(context),
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
  // Services for TestFlight version
  final ProfileService _profileService = ProfileService();
  final SplashScreenController _splashController = SplashScreenController();
  final AppInitializer _appInitializer = AppInitializer();
  
  // Simplified state management
  bool _showSplash = true;
  bool _isLoading = true;
  bool _needsProfileSetup = false;
  String? _initializationError;
  
  // Initialization state
  InitializationResult? _initializationResult;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Simplified initialization for TestFlight version
  Future<void> _initializeApp() async {
    debugPrint('AuthWrapper: Starting TestFlight app initialization');
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

      // Step 2: Check if onboarding has been completed
      debugPrint('AuthWrapper: Step 2 - Checking onboarding status');
      final hasCompletedOnboarding = await OnboardingController.hasCompletedOnboarding();
      debugPrint('AuthWrapper: User has completed onboarding: $hasCompletedOnboarding');

      if (!hasCompletedOnboarding) {
        // Navigate to onboarding
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
        return;
      }

      // Step 3: Initialize profile service
      debugPrint('AuthWrapper: Step 3 - Initializing profile service');
      await _profileService.initialize();

      // Step 4: Check if user has completed profile setup
      debugPrint('AuthWrapper: Step 4 - Checking profile setup status');
      final hasProfile = await _profileService.hasProfile();
      debugPrint('AuthWrapper: User has profile: $hasProfile');

      // Step 5: Check splash screen settings
      debugPrint('AuthWrapper: Step 5 - Checking splash screen settings');
      final shouldShowSplash = await _splashController.shouldShowSplash();
      debugPrint('AuthWrapper: Should show splash: $shouldShowSplash');

      // Step 6: Update UI state based on results
      if (mounted) {
        setState(() {
          _needsProfileSetup = !hasProfile;
          _showSplash = shouldShowSplash;
          _isLoading = false;
        });
        
        debugPrint('AuthWrapper: Final state - needsProfileSetup: $_needsProfileSetup, showSplash: $_showSplash');
        debugPrint('AuthWrapper: Next screen will be: ${_needsProfileSetup ? 'ProfileSetupScreen' : 'MainScreen'}');
      }

    } catch (e) {
      debugPrint('AuthWrapper: Initialization error: $e');
      _appInitializer.handleInitializationError(e);
      
      if (mounted) {
        setState(() {
          _initializationError = e.toString();
          _needsProfileSetup = true; // Safe default
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
        _needsProfileSetup = true; // Safe default
        _showSplash = true; // Safe default
        _isLoading = false;
      });
    }
  }

  /// Called when splash screen completes
  void _onSplashComplete() {
    debugPrint('AuthWrapper: Splash screen completed, transitioning to next screen');
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
        displayDuration: const Duration(seconds: 2),
        showFreshInstallIndicator: false,
      );
    }

    // Show loading indicator during initialization
    if (_isLoading) {
      debugPrint('AuthWrapper: Displaying loading screen');
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
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
        ),
      );
    }

    // Show error state with retry option if initialization failed
    if (_initializationError != null) {
      debugPrint('AuthWrapper: Displaying error screen');
      return _buildErrorScreen();
    }

    // Navigate to appropriate screen based on profile setup status
    if (_needsProfileSetup) {
      debugPrint('AuthWrapper: Displaying profile setup screen');
      return const ProfileSetupScreen();
    } else {
      debugPrint('AuthWrapper: Displaying main screen');
      return const MainScreen();
    }
  }

  /// Builds the error screen with retry functionality
  Widget _buildErrorScreen() {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                    // Skip to profile setup as fallback
                    Navigator.of(context).pushReplacementNamed('/profile-setup');
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
      ),
    );
  }
}
