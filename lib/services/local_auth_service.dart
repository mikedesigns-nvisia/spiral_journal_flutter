import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class LocalAuthService {
  static final LocalAuthService _instance = LocalAuthService._internal();
  factory LocalAuthService() => _instance;
  LocalAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _authEnabledKey = 'auth_enabled';
  static const String _passwordHashKey = 'password_hash';
  static const String _userIdKey = 'user_id';
  static const String _firstLaunchKey = 'first_launch';

  /// Check if this is the first time the app is launched with timeout and error handling
  Future<bool> isFirstLaunch() async {
    try {
      final firstLaunch = await _secureStorage.read(key: _firstLaunchKey)
          .timeout(const Duration(seconds: 5));
      return firstLaunch == null;
    } catch (error) {
      debugPrint('LocalAuthService isFirstLaunch error: $error');
      // If we can't read the first launch flag, assume it's first launch for safety
      return true;
    }
  }

  /// Mark that the app has been launched before
  Future<void> markFirstLaunchComplete() async {
    try {
      await _secureStorage.write(key: _firstLaunchKey, value: 'false');
    } catch (e) {
      debugPrint('LocalAuthService markFirstLaunchComplete error: $e');
      rethrow;
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (error) {
      debugPrint('LocalAuthService isBiometricAvailable error: $error');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (error) {
      debugPrint('LocalAuthService getAvailableBiometrics error: $error');
      return <BiometricType>[];
    }
  }

  /// Check if any authentication is set up
  Future<bool> isAuthenticationEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _authEnabledKey);
      return enabled == 'true';
    } catch (error) {
      debugPrint('LocalAuthService isAuthenticationEnabled error: $error');
      return false;
    }
  }

  /// Set up password authentication
  Future<bool> setupPasswordAuth(String password) async {
    try {
      final hashedPassword = _hashPassword(password);
      await _secureStorage.write(key: _passwordHashKey, value: hashedPassword);
      await _secureStorage.write(key: _authEnabledKey, value: 'true');
      await _generateUserId();
      return true;
    } catch (error) {
      debugPrint('LocalAuthService setupPasswordAuth error: $error');
      return false;
    }
  }

  /// Authenticate with password
  Future<bool> authenticateWithPassword(String password) async {
    try {
      final storedHash = await _secureStorage.read(key: _passwordHashKey);
      if (storedHash == null) return false;
      
      return _verifyPassword(password, storedHash);
    } catch (error) {
      debugPrint('LocalAuthService authenticateWithPassword error: $error');
      return false;
    }
  }

  /// Authenticate with biometrics with improved timeout handling
  Future<AuthResult> authenticateWithBiometrics({Duration timeout = const Duration(seconds: 20)}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return AuthResult.failed('Biometric authentication is not available on this device');
      }

      // Use Future.timeout for cleaner timeout handling
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your journal',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false, // Changed to false to prevent hanging
        ),
      ).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Biometric authentication timed out', timeout);
        },
      );

      return didAuthenticate ? AuthResult.success() : AuthResult.biometricFailed();
    } catch (error) {
      debugPrint('LocalAuthService authenticateWithBiometrics error: $error');
      
      if (error is TimeoutException) {
        return AuthResult.timeout('Biometric authentication timed out. Please try again or use password.');
      }
      
      // Handle specific error types for better fallback
      final errorMessage = error.toString().toLowerCase();
      if (errorMessage.contains('user_cancel') || errorMessage.contains('cancelled')) {
        return AuthResult.cancelled('Authentication was cancelled');
      } else if (errorMessage.contains('not_available') || errorMessage.contains('unavailable')) {
        return AuthResult.unavailable('Biometric authentication is not available');
      } else if (errorMessage.contains('too_many_attempts')) {
        return AuthResult.lockedOut('Too many failed attempts. Please wait before trying again.');
      } else {
        return AuthResult.failed('Biometric authentication error: ${error.toString()}');
      }
    }
  }

  /// Authenticate with either biometrics or password fallback
  Future<AuthResult> authenticate({String? password, Duration biometricTimeout = const Duration(seconds: 30)}) async {
    try {
      // First try biometrics if available and no password provided
      final biometricAvailable = await isBiometricAvailable();
      if (biometricAvailable && password == null) {
        return await authenticateWithBiometrics(timeout: biometricTimeout);
      }

      // Fall back to password if provided
      if (password != null) {
        final passwordResult = await authenticateWithPassword(password);
        if (passwordResult) {
          return AuthResult.success();
        } else {
          return AuthResult.passwordFailed();
        }
      }

      return AuthResult.failed('No authentication method available');
    } catch (error) {
      debugPrint('LocalAuthService authenticate error: $error');
      return AuthResult.failed('Authentication error: $error');
    }
  }

  /// Get the current user ID (generated locally)
  Future<String?> getCurrentUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (error) {
      debugPrint('LocalAuthService getCurrentUserId error: $error');
      return null;
    }
  }

  /// Generate a unique user ID for local storage
  Future<void> _generateUserId() async {
    final existingId = await _secureStorage.read(key: _userIdKey);
    if (existingId == null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final randomBytes = List.generate(16, (i) => timestamp.hashCode + i);
      final userId = sha256.convert(randomBytes).toString().substring(0, 16);
      await _secureStorage.write(key: _userIdKey, value: 'local_$userId');
    }
  }

  /// Hash password using SHA-256 with salt (temporary - should use bcrypt)
  /// TODO: Replace with bcrypt or Argon2 for production
  String _hashPassword(String password) {
    // Generate a random salt
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = List.generate(16, (i) => (timestamp.hashCode * i) % 256);
    final saltBytes = sha256.convert(random).bytes.take(16).toList();
    final salt = base64Encode(saltBytes);
    
    // Hash password with salt
    final saltedPassword = '$password$salt';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    
    // Return salt:hash format
    return '$salt:${digest.toString()}';
  }
  
  /// Verify password against stored hash
  bool _verifyPassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) {
      // Legacy hash format (no salt) - still verify for backward compatibility
      final bytes = utf8.encode(password);
      final digest = sha256.convert(bytes);
      return digest.toString() == storedHash;
    }
    
    final salt = parts[0];
    final expectedHash = parts[1];
    
    final saltedPassword = '$password$salt';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    
    return digest.toString() == expectedHash;
  }

  /// Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final isValid = await authenticateWithPassword(oldPassword);
      if (!isValid) return false;

      return await setupPasswordAuth(newPassword);
    } catch (error) {
      debugPrint('LocalAuthService changePassword error: $error');
      return false;
    }
  }

  /// Disable authentication (for testing or user preference)
  Future<void> disableAuthentication() async {
    try {
      await _secureStorage.delete(key: _authEnabledKey);
      await _secureStorage.delete(key: _passwordHashKey);
    } catch (e) {
      debugPrint('LocalAuthService disableAuthentication error: $e');
      rethrow;
    }
  }

  /// Clear all authentication data (for app reset)
  Future<void> clearAllAuthData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('LocalAuthService clearAllAuthData error: $e');
      rethrow;
    }
  }

  /// Get authentication status info with timeout and error handling
  Future<AuthStatus> getAuthStatus() async {
    try {
      final results = await Future.wait([
        isAuthenticationEnabled(),
        isBiometricAvailable(),
        getAvailableBiometrics(),
        getCurrentUserId(),
      ]).timeout(const Duration(seconds: 10));

      return AuthStatus(
        isEnabled: results[0] as bool,
        biometricAvailable: results[1] as bool,
        availableBiometrics: results[2] as List<BiometricType>,
        userId: results[3] as String?,
      );
    } catch (e) {
      // Return safe defaults if status check fails
      return AuthStatus(
        isEnabled: false,
        biometricAvailable: false,
        availableBiometrics: [],
        userId: null,
      );
    }
  }

  /// Emergency reset for when authentication is completely broken
  Future<bool> emergencyReset() async {
    try {
      await clearAllAuthData();
      await markFirstLaunchComplete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if the authentication system is in a healthy state
  Future<bool> isAuthSystemHealthy() async {
    try {
      // Try to read a simple value to test storage access
      await _secureStorage.read(key: _authEnabledKey).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Authentication result class
class AuthResult {
  final bool success;
  final String? error;
  final AuthResultType type;

  AuthResult._(this.success, this.error, this.type);

  factory AuthResult.success() => AuthResult._(true, null, AuthResultType.success);
  factory AuthResult.biometricFailed() => AuthResult._(false, 'Biometric authentication failed', AuthResultType.biometricFailed);
  factory AuthResult.passwordFailed() => AuthResult._(false, 'Password authentication failed', AuthResultType.passwordFailed);
  factory AuthResult.failed(String error) => AuthResult._(false, error, AuthResultType.failed);
  factory AuthResult.timeout(String error) => AuthResult._(false, error, AuthResultType.timeout);
  factory AuthResult.cancelled(String error) => AuthResult._(false, error, AuthResultType.cancelled);
  factory AuthResult.unavailable(String error) => AuthResult._(false, error, AuthResultType.unavailable);
  factory AuthResult.lockedOut(String error) => AuthResult._(false, error, AuthResultType.lockedOut);
}

enum AuthResultType {
  success,
  biometricFailed,
  passwordFailed,
  failed,
  timeout,
  cancelled,
  unavailable,
  lockedOut,
}

/// Authentication status class
class AuthStatus {
  final bool isEnabled;
  final bool biometricAvailable;
  final List<BiometricType> availableBiometrics;
  final String? userId;

  AuthStatus({
    required this.isEnabled,
    required this.biometricAvailable,
    required this.availableBiometrics,
    required this.userId,
  });

  String get biometricTypeString {
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Touch ID';
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }

  bool get hasFaceId => availableBiometrics.contains(BiometricType.face);
  bool get hasTouchId => availableBiometrics.contains(BiometricType.fingerprint);
}