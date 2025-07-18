import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:spiral_journal/constants/app_constants.dart';
import 'package:spiral_journal/services/local_auth_service.dart';

/// Manages authentication state and operations for the application.
/// 
/// This class centralizes authentication logic that was previously scattered
/// throughout the AuthWrapper, providing a clean interface for authentication
/// status checking, first launch detection, and system health verification.
/// 
/// ## Usage Example
/// ```dart
/// final authManager = AuthenticationManager();
/// final authState = await authManager.checkAuthenticationStatus();
/// 
/// if (authState.needsAuthentication) {
///   // Show authentication setup or login
/// } else if (authState.isReadyForOperation) {
///   // Proceed with normal app flow
/// }
/// ```
/// 
/// ## Integration Pattern
/// This class is designed to be used by:
/// - AuthWrapper for determining authentication flow
/// - AppInitializer for system health verification
/// - Settings screens for authentication configuration
/// 
/// The class follows the singleton pattern to ensure consistent state
/// across the application and prevent multiple authentication checks.
class AuthenticationManager {
  static final AuthenticationManager _instance = AuthenticationManager._internal();
  factory AuthenticationManager() => _instance;
  AuthenticationManager._internal();

  final LocalAuthService _authService = LocalAuthService();

  /// Checks the current authentication status of the application.
  /// 
  /// Returns an [AuthenticationState] containing information about whether
  /// authentication is enabled, healthy, and if setup is required.
  /// 
  /// Throws [AuthenticationException] if the check fails critically.
  Future<AuthenticationState> checkAuthenticationStatus() async {
    try {
      // Check authentication status and first launch with individual timeouts
      final authStatusFuture = _authService.getAuthStatus()
          .timeout(AppConstants.authTimeout);
      final firstLaunchFuture = _authService.isFirstLaunch()
          .timeout(AppConstants.firstLaunchTimeout);
      final healthCheckFuture = _authService.isAuthSystemHealthy()
          .timeout(AppConstants.healthCheckTimeout);

      final results = await Future.wait([
        authStatusFuture,
        firstLaunchFuture,
        healthCheckFuture,
      ]);

      final authStatus = results[0] as AuthStatus;
      final isFirstLaunch = results[1] as bool;
      final isHealthy = results[2] as bool;

      return AuthenticationState(
        isEnabled: authStatus.isEnabled,
        isHealthy: isHealthy,
        requiresSetup: !authStatus.isEnabled || isFirstLaunch,
        lastCheck: DateTime.now(),
        authStatus: authStatus,
        isFirstLaunch: isFirstLaunch,
      );
    } catch (e, stackTrace) {
      debugPrint('AuthenticationManager checkAuthenticationStatus error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Return safe defaults if check fails
      return AuthenticationState(
        isEnabled: false,
        isHealthy: false,
        requiresSetup: true,
        lastCheck: DateTime.now(),
        authStatus: null,
        isFirstLaunch: true,
      );
    }
  }

  /// Determines if this is the first time the application is being launched.
  /// 
  /// Returns true if this is the first launch, false otherwise.
  /// In case of errors, returns true for safety (assumes first launch).
  Future<bool> isFirstLaunch() async {
    try {
      return await _authService.isFirstLaunch()
          .timeout(AppConstants.firstLaunchTimeout);
    } catch (e, stackTrace) {
      debugPrint('AuthenticationManager isFirstLaunch error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Return true for safety if we can't determine first launch status
      return true;
    }
  }

  /// Checks if the authentication system is in a healthy state.
  /// 
  /// Returns true if the authentication system is functioning properly,
  /// false if there are issues that need to be addressed.
  Future<bool> isAuthSystemHealthy() async {
    try {
      return await _authService.isAuthSystemHealthy()
          .timeout(AppConstants.healthCheckTimeout);
    } catch (e, stackTrace) {
      debugPrint('AuthenticationManager isAuthSystemHealthy error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Return false if we can't verify system health
      return false;
    }
  }

  /// Marks the first launch as complete.
  /// 
  /// This should be called after successful app initialization to prevent
  /// the first launch flow from being triggered again.
  Future<void> markFirstLaunchComplete() async {
    try {
      await _authService.markFirstLaunchComplete();
    } catch (e, stackTrace) {
      debugPrint('AuthenticationManager markFirstLaunchComplete error: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - this is not critical for app functionality
    }
  }

  /// Performs an emergency reset of the authentication system.
  /// 
  /// This should only be used when the authentication system is in an
  /// unrecoverable state. Returns true if the reset was successful.
  Future<bool> performEmergencyReset() async {
    try {
      return await _authService.emergencyReset();
    } catch (e, stackTrace) {
      debugPrint('AuthenticationManager performEmergencyReset error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}

/// Represents the current state of authentication in the application.
class AuthenticationState {
  /// Whether authentication is enabled
  final bool isEnabled;
  
  /// Whether the authentication system is healthy
  final bool isHealthy;
  
  /// Whether authentication setup is required
  final bool requiresSetup;
  
  /// When this state was last checked
  final DateTime lastCheck;
  
  /// The detailed authentication status from LocalAuthService
  final AuthStatus? authStatus;
  
  /// Whether this is the first launch of the application
  final bool isFirstLaunch;

  const AuthenticationState({
    required this.isEnabled,
    required this.isHealthy,
    required this.requiresSetup,
    required this.lastCheck,
    required this.authStatus,
    required this.isFirstLaunch,
  });

  /// Whether authentication is needed based on current state
  bool get needsAuthentication => !isEnabled || isFirstLaunch || !isHealthy;

  /// Whether the system is ready for normal operation
  bool get isReadyForOperation => isEnabled && isHealthy && !requiresSetup;

  @override
  String toString() {
    return 'AuthenticationState('
        'isEnabled: $isEnabled, '
        'isHealthy: $isHealthy, '
        'requiresSetup: $requiresSetup, '
        'isFirstLaunch: $isFirstLaunch, '
        'lastCheck: $lastCheck'
        ')';
  }
}

/// Exception thrown when authentication operations fail critically.
class AuthenticationException implements Exception {
  final String message;
  final dynamic originalError;

  const AuthenticationException(this.message, [this.originalError]);

  @override
  String toString() => 'AuthenticationException: $message';
}