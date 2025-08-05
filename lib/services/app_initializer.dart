import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:spiral_journal/core/app_constants.dart';
import 'package:spiral_journal/services/authentication_manager.dart';
import 'package:spiral_journal/services/settings_service.dart';
import 'package:spiral_journal/services/local_auth_service.dart';
import 'package:spiral_journal/utils/app_error_handler.dart';
import 'package:spiral_journal/services/crash_recovery_service.dart';
import 'package:spiral_journal/services/production_environment_loader.dart';

/// Orchestrates application initialization and system health verification.
/// 
/// This class manages the complex initialization process that was previously
/// handled in AuthWrapper, providing timeout management, health checks,
/// and coordinated startup of all application systems.
/// 
/// ## Usage Example
/// ```dart
/// final initializer = AppInitializer();
/// final result = await initializer.initialize();
/// 
/// if (result.success) {
///   // App is ready for normal operation
///   debugPrint('Initialization completed in ${result.initializationTime.inMilliseconds}ms');
/// } else {
///   // Handle initialization failure
///   debugPrint('Initialization failed: ${result.errorMessage}');
///   initializer.handleInitializationError(result.errorMessage);
/// }
/// 
/// // Perform health check independently
/// final healthResult = await initializer.verifySystemHealth();
/// if (!healthResult.isHealthy) {
///   debugPrint('Unhealthy components: ${healthResult.unhealthyComponents}');
/// }
/// ```
/// 
/// ## Integration Pattern
/// This class is designed to be used by:
/// - AuthWrapper for coordinated app startup
/// - Main app entry point for system verification
/// - Error recovery systems for health monitoring
/// 
/// The class implements timeout protection and graceful failure handling
/// to ensure the app can start even if some components fail to initialize.
class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  final AuthenticationManager _authManager = AuthenticationManager();
  final SettingsService _settingsService = SettingsService();
  final LocalAuthService _authService = LocalAuthService();

  bool _isInitializing = false;
  final Completer<InitializationResult> _initializationCompleter = Completer<InitializationResult>();
  Timer? _initializationTimeout;

  /// Initializes the application with comprehensive error handling and timeout management.
  /// 
  /// Returns an [InitializationResult] indicating success or failure with detailed
  /// information about what went wrong. This method is safe to call multiple times
  /// and will return the same result if initialization is already in progress.
  /// 
  /// The initialization process includes:
  /// - Authentication system verification
  /// - Settings service health check
  /// - System component coordination
  /// - Timeout management
  /// - Crash recovery check
  Future<InitializationResult> initialize() async {
    return await AppErrorHandler().handleError(
      () async {
        // Prevent multiple initialization attempts
        if (_isInitializing) {
          return await _initializationCompleter.future;
        }
        
        _isInitializing = true;
        final startTime = DateTime.now();
        
        // Set up timeout protection
        _initializationTimeout = Timer(AppConstants.initializationTimeout, () {
          if (!_initializationCompleter.isCompleted) {
            _handleInitializationTimeout();
          }
        });

        try {
          // Perform initialization steps sequentially to avoid race conditions
          final systemStatus = <String, dynamic>{};
          
          // Step 0: Ensure environment variables are loaded
          debugPrint('AppInitializer: Step 0 - Loading environment variables');
          await ProductionEnvironmentLoader.ensureLoaded();
          final envStatus = ProductionEnvironmentLoader.getStatus();
          systemStatus['environment'] = envStatus.toJson();
          debugPrint('AppInitializer: Environment loaded - API key available: ${envStatus.hasClaudeApiKey}');
          
          // Step 1: Check for crash recovery
          final crashRecoveryResult = await _checkCrashRecovery();
          systemStatus['crashRecovery'] = crashRecoveryResult;
          
          // Step 2: Verify authentication system
          final authResult = await _initializeAuthenticationSystem();
          systemStatus['authentication'] = authResult;
          
          // Step 3: Verify settings system
          final settingsResult = await _initializeSettingsSystem();
          systemStatus['settings'] = settingsResult;
          
          // Step 4: Perform comprehensive health check
          final healthResult = await verifySystemHealth();
          systemStatus['health'] = healthResult;
          
          // Step 5: Finalize initialization
          final initializationTime = DateTime.now().difference(startTime);
          
          final result = InitializationResult(
            success: true,
            errorMessage: null,
            systemStatus: systemStatus,
            initializationTime: initializationTime,
            timestamp: DateTime.now(),
          );
          
          if (!_initializationCompleter.isCompleted) {
            _initializationCompleter.complete(result);
          }
          
          return result;
          
        } catch (e) {
          // Log crash for future recovery
          await CrashRecoveryService().logCrash(e.toString(), StackTrace.current);
          
          final result = _createFailureResult(e, DateTime.now().difference(startTime));
          
          if (!_initializationCompleter.isCompleted) {
            _initializationCompleter.complete(result);
          }
          
          return result;
        } finally {
          _initializationTimeout?.cancel();
          _isInitializing = false;
        }
      },
      operationName: 'initialize',
      component: 'AppInitializer',
      allowRetry: true,
      fallbackValue: InitializationResult(
        success: false,
        errorMessage: 'Initialization failed with fallback',
        systemStatus: {'fallback': true},
        initializationTime: Duration.zero,
        timestamp: DateTime.now(),
      ),
    ) ?? InitializationResult(
      success: false,
      errorMessage: 'Critical initialization failure',
      systemStatus: {'critical': true},
      initializationTime: Duration.zero,
      timestamp: DateTime.now(),
    );
  }

  /// Verifies the health of all critical system components.
  /// 
  /// Returns a [SystemHealthResult] containing detailed information about
  /// the status of each system component. This method can be called
  /// independently of the main initialization process.
  Future<SystemHealthResult> verifySystemHealth() async {
    try {
      final healthChecks = <String, bool>{};
      final healthDetails = <String, dynamic>{};
      
      // Check authentication system health
      try {
        final authHealthy = await _authService.isAuthSystemHealthy()
            .timeout(AppConstants.healthCheckTimeout);
        healthChecks['authentication'] = authHealthy;
        healthDetails['authentication'] = {'healthy': authHealthy};
      } catch (e) {
        healthChecks['authentication'] = false;
        healthDetails['authentication'] = {'healthy': false, 'error': e.toString()};
      }
      
      // Check settings system health
      try {
        await _settingsService.isSplashScreenEnabled()
            .timeout(AppConstants.healthCheckTimeout);
        healthChecks['settings'] = true;
        healthDetails['settings'] = {'healthy': true};
      } catch (e) {
        healthChecks['settings'] = false;
        healthDetails['settings'] = {'healthy': false, 'error': e.toString()};
      }
      
      // Basic system check
      healthChecks['system'] = true;
      healthDetails['system'] = {'healthy': true};
      
      final overallHealthy = healthChecks.values.every((healthy) => healthy);
      
      return SystemHealthResult(
        isHealthy: overallHealthy,
        componentStatus: healthChecks,
        details: healthDetails,
        checkTime: DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('System health check error: $e');
      
      return SystemHealthResult(
        isHealthy: false,
        componentStatus: {'overall': false},
        details: {'error': e.toString()},
        checkTime: DateTime.now(),
      );
    }
  }

  /// Handles initialization errors with appropriate logging and recovery.
  /// 
  /// This method processes initialization failures, logs them appropriately,
  /// and determines if recovery is possible or if the app should fail safely.
  void handleInitializationError(dynamic error) {
    try {
      // Log additional context for initialization failures
      debugPrint('Initialization failed: $error');
      debugPrint('App will attempt to continue with safe defaults');
      
    } catch (e) {
      // If even error handling fails, fall back to basic logging
      debugPrint('Critical error in initialization error handling: $e');
      debugPrint('Original error: $error');
    }
  }

  /// Resets the initializer state for testing or recovery purposes.
  /// 
  /// This method clears any cached state and allows initialization to be
  /// attempted again. Should only be used in testing or error recovery scenarios.
  void reset() {
    _initializationTimeout?.cancel();
    _isInitializing = false;
    
    if (!_initializationCompleter.isCompleted) {
      _initializationCompleter.complete(
        InitializationResult(
          success: false,
          errorMessage: 'Initialization was reset',
          systemStatus: {},
          initializationTime: Duration.zero,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Initializes the authentication system component.
  Future<Map<String, dynamic>> _initializeAuthenticationSystem() async {
    try {
      final authState = await _authManager.checkAuthenticationStatus();
      return {
        'success': true,
        'enabled': authState.isEnabled,
        'healthy': authState.isHealthy,
        'requiresSetup': authState.requiresSetup,
        'isFirstLaunch': authState.isFirstLaunch,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'enabled': false,
        'healthy': false,
        'requiresSetup': true,
        'isFirstLaunch': true,
      };
    }
  }

  /// Initializes the settings system component.
  Future<Map<String, dynamic>> _initializeSettingsSystem() async {
    try {
      final splashEnabled = await _settingsService.isSplashScreenEnabled();
      return {
        'success': true,
        'splashEnabled': splashEnabled,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'splashEnabled': true, // Safe default
      };
    }
  }

  /// Handles initialization timeout scenarios.
  void _handleInitializationTimeout() {
    final result = InitializationResult(
      success: false,
      errorMessage: 'Initialization timed out after ${AppConstants.initializationTimeout.inSeconds} seconds',
      systemStatus: {'timeout': true},
      initializationTime: AppConstants.initializationTimeout,
      timestamp: DateTime.now(),
    );
    
    if (!_initializationCompleter.isCompleted) {
      _initializationCompleter.complete(result);
    }
  }

  /// Check for crash recovery data and available drafts.
  Future<Map<String, dynamic>> _checkCrashRecovery() async {
    try {
      final crashRecoveryService = CrashRecoveryService();
      
      // Check for available drafts
      final hasDrafts = await crashRecoveryService.hasDraftsToRecover();
      final drafts = await crashRecoveryService.getAllDrafts();
      
      // Check for recent crash logs
      final crashLogs = await crashRecoveryService.getCrashLogs();
      final recentCrashes = crashLogs.where((log) => 
        DateTime.now().difference(log.timestamp) < const Duration(hours: 24)
      ).length;
      
      return {
        'success': true,
        'hasDrafts': hasDrafts,
        'draftCount': drafts.length,
        'recentCrashes': recentCrashes,
        'lastActiveEntry': await crashRecoveryService.getLastActiveEntry(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'hasDrafts': false,
        'draftCount': 0,
        'recentCrashes': 0,
      };
    }
  }

  /// Creates a failure result from an exception.
  InitializationResult _createFailureResult(dynamic error, Duration initializationTime) {
    return InitializationResult(
      success: false,
      errorMessage: error.toString(),
      systemStatus: {'error': error.toString()},
      initializationTime: initializationTime,
      timestamp: DateTime.now(),
    );
  }
}

/// Result of application initialization process.
class InitializationResult {
  /// Whether initialization was successful
  final bool success;
  
  /// Error message if initialization failed
  final String? errorMessage;
  
  /// Status of individual system components
  final Map<String, dynamic> systemStatus;
  
  /// How long initialization took
  final Duration initializationTime;
  
  /// When initialization completed
  final DateTime timestamp;

  const InitializationResult({
    required this.success,
    required this.errorMessage,
    required this.systemStatus,
    required this.initializationTime,
    required this.timestamp,
  });

  /// Whether the app is ready for normal operation
  bool get isReadyForOperation => success && errorMessage == null;

  /// Whether initialization timed out
  bool get timedOut => systemStatus['timeout'] == true;

  @override
  String toString() {
    return 'InitializationResult('
        'success: $success, '
        'errorMessage: $errorMessage, '
        'initializationTime: ${initializationTime.inMilliseconds}ms, '
        'timestamp: $timestamp'
        ')';
  }
}

/// Result of system health verification.
class SystemHealthResult {
  /// Whether all systems are healthy
  final bool isHealthy;
  
  /// Status of individual components
  final Map<String, bool> componentStatus;
  
  /// Detailed information about each component
  final Map<String, dynamic> details;
  
  /// When the health check was performed
  final DateTime checkTime;

  const SystemHealthResult({
    required this.isHealthy,
    required this.componentStatus,
    required this.details,
    required this.checkTime,
  });

  /// Gets the list of unhealthy components
  List<String> get unhealthyComponents {
    return componentStatus.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Gets the list of healthy components
  List<String> get healthyComponents {
    return componentStatus.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  String toString() {
    return 'SystemHealthResult('
        'isHealthy: $isHealthy, '
        'healthyComponents: ${healthyComponents.length}, '
        'unhealthyComponents: ${unhealthyComponents.length}, '
        'checkTime: $checkTime'
        ')';
  }
}