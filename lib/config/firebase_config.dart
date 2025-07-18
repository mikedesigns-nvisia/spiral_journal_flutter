import 'package:flutter/foundation.dart';
import 'local_config.dart';
import 'environment.dart';

/// Local configuration service that replaces Firebase
/// This maintains API compatibility while using local-only services
@Deprecated('Use LocalConfig instead. This class is kept for compatibility only.')
class FirebaseConfig {
  /// Initialize local configuration (replaces Firebase initialization)
  static Future<void> initialize() async {
    try {
      // Initialize local configuration instead of Firebase
      await LocalConfig.initialize();
      
      if (EnvironmentConfig.enableDebugLogging) {
        debugPrint('✅ Local configuration initialized successfully (Firebase replacement)');
        debugPrint('🔒 Using local-first architecture for privacy and performance');
      }
    } catch (e) {
      debugPrint('❌ Local configuration initialization failed: $e');
      rethrow;
    }
  }
}
