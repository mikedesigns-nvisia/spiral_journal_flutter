import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'environment.dart';

/// Local-first configuration for Spiral Journal
/// Replaces Firebase with local-only services for privacy and performance
class LocalConfig {
  static bool _initialized = false;
  static String? _localDataPath;
  static String? _localCachePath;
  static String? _localBackupPath;

  /// Initialize local-only configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Set up local data paths
      await _initializeLocalPaths();
      
      // Initialize local services
      await _initializeLocalServices();
      
      _initialized = true;
      
      if (EnvironmentConfig.enableDebugLogging) {
        debugPrint('✅ Local configuration initialized successfully for ${EnvironmentConfig.current}');
        debugPrint('📁 Local data path: $_localDataPath');
        debugPrint('💾 Local cache path: $_localCachePath');
        debugPrint('🔄 Local backup path: $_localBackupPath');
      }
    } catch (e) {
      debugPrint('❌ Local configuration initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize local file system paths
  static Future<void> _initializeLocalPaths() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final appSupportDir = await getApplicationSupportDirectory();
      
      _localDataPath = '${appDocDir.path}/spiral_journal_data';
      _localCachePath = '${appSupportDir.path}/spiral_journal_cache';
      _localBackupPath = '${appDocDir.path}/spiral_journal_backups';
      
      // Create directories if they don't exist
      await Directory(_localDataPath!).create(recursive: true);
      await Directory(_localCachePath!).create(recursive: true);
      await Directory(_localBackupPath!).create(recursive: true);
      
    } catch (e) {
      debugPrint('❌ Failed to initialize local paths: $e');
      rethrow;
    }
  }

  /// Initialize local services (analytics, crash reporting, etc.)
  static Future<void> _initializeLocalServices() async {
    try {
      // Initialize local analytics (no external services)
      if (EnvironmentConfig.enableLocalAnalytics) {
        await _initializeLocalAnalytics();
      }
      
      // Initialize local crash reporting
      if (EnvironmentConfig.enableLocalCrashReporting) {
        await _initializeLocalCrashReporting();
      }
      
      // Set up local backup system
      await _initializeLocalBackupSystem();
      
    } catch (e) {
      debugPrint('❌ Failed to initialize local services: $e');
      rethrow;
    }
  }

  /// Initialize local analytics system
  static Future<void> _initializeLocalAnalytics() async {
    try {
      // Create analytics directory
      final analyticsDir = Directory('$_localDataPath/analytics');
      await analyticsDir.create(recursive: true);
      
      if (EnvironmentConfig.enableDebugLogging) {
        debugPrint('📊 Local analytics initialized');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize local analytics: $e');
    }
  }

  /// Initialize local crash reporting system
  static Future<void> _initializeLocalCrashReporting() async {
    try {
      // Create crash reports directory
      final crashDir = Directory('$_localDataPath/crash_reports');
      await crashDir.create(recursive: true);
      
      if (EnvironmentConfig.enableDebugLogging) {
        debugPrint('🛡️ Local crash reporting initialized');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize local crash reporting: $e');
    }
  }

  /// Initialize local backup system
  static Future<void> _initializeLocalBackupSystem() async {
    try {
      // Create backup metadata file if it doesn't exist
      final backupMetaFile = File('$_localBackupPath/backup_metadata.json');
      if (!await backupMetaFile.exists()) {
        await backupMetaFile.writeAsString('{"last_backup": null, "backup_count": 0}');
      }
      
      if (EnvironmentConfig.enableDebugLogging) {
        debugPrint('🔄 Local backup system initialized');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize local backup system: $e');
    }
  }

  // Getters for local paths
  static String get localDataPath {
    if (!_initialized || _localDataPath == null) {
      throw StateError('LocalConfig not initialized. Call LocalConfig.initialize() first.');
    }
    return _localDataPath!;
  }

  static String get localCachePath {
    if (!_initialized || _localCachePath == null) {
      throw StateError('LocalConfig not initialized. Call LocalConfig.initialize() first.');
    }
    return _localCachePath!;
  }

  static String get localBackupPath {
    if (!_initialized || _localBackupPath == null) {
      throw StateError('LocalConfig not initialized. Call LocalConfig.initialize() first.');
    }
    return _localBackupPath!;
  }

  // Local database configuration
  static String get localDatabasePath => '$localDataPath/spiral_journal.db';
  static String get localAnalyticsPath => '$localDataPath/analytics';
  static String get localCrashReportsPath => '$localDataPath/crash_reports';

  // Local backup configuration
  static Duration get localBackupInterval => const Duration(hours: 24);
  static int get maxLocalBackups => 7; // Keep 7 days of backups
  static String get backupFilePrefix => 'spiral_journal_backup';

  // Local analytics configuration
  static bool get enableLocalMetrics => true;
  static bool get enablePerformanceTracking => EnvironmentConfig.isDevelopment;
  static Duration get analyticsFlushInterval => const Duration(minutes: 5);

  // Local cache configuration
  static Duration get defaultCacheExpiration => const Duration(hours: 24);
  static int get maxCacheSize => 100 * 1024 * 1024; // 100MB
  static Duration get cacheCleanupInterval => const Duration(hours: 6);

  /// Check if local configuration is initialized
  static bool get isInitialized => _initialized;

  /// Get local configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'initialized': _initialized,
      'environment': EnvironmentConfig.current.toString(),
      'local_data_path': _localDataPath,
      'local_cache_path': _localCachePath,
      'local_backup_path': _localBackupPath,
      'enable_local_analytics': EnvironmentConfig.enableLocalAnalytics,
      'enable_local_crash_reporting': EnvironmentConfig.enableLocalCrashReporting,
      'enable_debug_logging': EnvironmentConfig.enableDebugLogging,
    };
  }

  /// Reset local configuration (for testing)
  @visibleForTesting
  static void reset() {
    _initialized = false;
    _localDataPath = null;
    _localCachePath = null;
    _localBackupPath = null;
  }
}
