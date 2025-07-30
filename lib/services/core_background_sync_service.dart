import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

/// Simple iCloud backup service for SQLite database
class CoreBackgroundSyncService {
  static final CoreBackgroundSyncService _instance = CoreBackgroundSyncService._internal();
  factory CoreBackgroundSyncService() => _instance;
  CoreBackgroundSyncService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Backup configuration
  static const Duration _backupInterval = Duration(hours: 24);
  static const String _backupFileName = 'spiral_journal_backup.db';
  static const String _backupMetadataFileName = 'backup_metadata.json';
  
  // Backup state
  Timer? _backupTimer;
  bool _isInitialized = false;
  bool _isBackingUp = false;
  DateTime? _lastSuccessfulBackup;
  
  final StreamController<BackupEvent> _backupEventController = StreamController<BackupEvent>.broadcast();

  /// Initialize the backup service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _databaseHelper.database;
      _startPeriodicBackup();
      _isInitialized = true;
      
      debugPrint('CoreBackgroundSyncService: Initialized as backup service');
      
      _broadcastBackupEvent(BackupEvent(
        type: BackupEventType.initialized,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('CoreBackgroundSyncService: Initialization failed: $e');
      _broadcastBackupEvent(BackupEvent(
        type: BackupEventType.error,
        timestamp: DateTime.now(),
        error: e.toString(),
      ));
    }
  }

  /// Get backup event stream
  Stream<BackupEvent> get backupEventStream => _backupEventController.stream;

  /// Perform manual backup to iCloud Documents
  Future<bool> performManualBackup() async {
    if (_isBackingUp) {
      debugPrint('CoreBackgroundSyncService: Backup already in progress');
      return false;
    }

    return await _performBackup(isManual: true);
  }

  /// Restore database from iCloud backup
  Future<bool> restoreFromBackup() async {
    if (_isBackingUp) {
      debugPrint('CoreBackgroundSyncService: Cannot restore during backup');
      return false;
    }

    return await _performRestore();
  }

  /// Check if backup is currently active
  bool get isBackingUp => _isBackingUp;

  /// Get last successful backup time
  DateTime? get lastSuccessfulBackup => _lastSuccessfulBackup;

  /// Get backup statistics
  BackupStatistics getBackupStatistics() {
    return BackupStatistics(
      lastSuccessfulBackup: _lastSuccessfulBackup,
      isActive: _isBackingUp,
      nextBackupEstimate: _getNextBackupEstimate(),
    );
  }

  // Private methods

  void _startPeriodicBackup() {
    _backupTimer?.cancel();
    
    _backupTimer = Timer.periodic(_backupInterval, (_) async {
      if (!_isBackingUp) {
        await _performBackup();
      }
    });
    
    debugPrint('CoreBackgroundSyncService: Started daily backup with ${_backupInterval.inHours}h interval');
  }

  DateTime _getNextBackupEstimate() {
    final lastAttempt = _lastSuccessfulBackup ?? DateTime.now();
    return lastAttempt.add(_backupInterval);
  }

  Future<bool> _performBackup({bool isManual = false}) async {
    if (_isBackingUp) return false;

    _isBackingUp = true;
    
    try {
      debugPrint('CoreBackgroundSyncService: Starting backup (manual: $isManual)');
      
      _broadcastBackupEvent(BackupEvent(
        type: BackupEventType.backupStarted,
        timestamp: DateTime.now(),
        data: {'isManual': isManual},
      ));

      // Get iCloud Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${documentsDir.path}/$_backupFileName');
      final metadataFile = File('${documentsDir.path}/$_backupMetadataFileName');

      // Get current database file
      final db = await _databaseHelper.database;
      final dbPath = db.path;
      final sourceFile = File(dbPath);

      if (!await sourceFile.exists()) {
        throw Exception('Database file not found');
      }

      // Copy database to iCloud Documents
      await sourceFile.copy(backupFile.path);

      // Create backup metadata
      final metadata = {
        'created': DateTime.now().toIso8601String(),
        'size': await sourceFile.length(),
        'version': '1.1.0',
        'isManual': isManual,
      };

      await metadataFile.writeAsString(jsonEncode(metadata));

      _lastSuccessfulBackup = DateTime.now();
      
      debugPrint('CoreBackgroundSyncService: Backup completed successfully');
      
      _broadcastBackupEvent(BackupEvent(
        type: BackupEventType.backupCompleted,
        timestamp: DateTime.now(),
        data: {
          'backupSize': await sourceFile.length(),
          'duration': DateTime.now().difference(_lastSuccessfulBackup!).inMilliseconds,
        },
      ));

      return true;
    } catch (e) {
      debugPrint('CoreBackgroundSyncService: Backup failed: $e');
      
      _broadcastBackupEvent(BackupEvent(
        type: BackupEventType.backupFailed,
        timestamp: DateTime.now(),
        error: e.toString(),
      ));
      
      return false;
    } finally {
      _isBackingUp = false;
    }
  }

  Future<bool> _performRestore() async {
    try {
      debugPrint('CoreBackgroundSyncService: Starting restore from backup');
      
      _broadcastBackupEvent(BackupEvent(
        type: BackupEventType.restoreStarted,
        timestamp: DateTime.now(),
      ));

      // Get iCloud Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${documentsDir.path}/$_backupFileName');
      final metadataFile = File('${documentsDir.path}/$_backupMetadataFileName');

      if (!await backupFile.exists()) {
        throw Exception('No backup file found in iCloud Documents');
      }

      // Read backup metadata
      Map<String, dynamic>? metadata;
      if (await metadataFile.exists()) {
        final metadataJson = await metadataFile.readAsString();
        metadata = jsonDecode(metadataJson);
      }

      // Close current database connection
      await _databaseHelper.closeDatabase();

      // Get current database path
      final db = await _databaseHelper.database;
      final dbPath = db.path;
      
      // Backup current database first
      final currentBackup = File('${dbPath}.restore_backup');
      if (await File(dbPath).exists()) {
        await File(dbPath).copy(currentBackup.path);
      }

      try {
        // Restore from backup
        await backupFile.copy(dbPath);
        
        // Verify restored database
        await _databaseHelper.database;
        
        debugPrint('CoreBackgroundSyncService: Restore completed successfully');
        
        _broadcastBackupEvent(BackupEvent(
          type: BackupEventType.restoreCompleted,
          timestamp: DateTime.now(),
          data: metadata ?? {},
        ));

        return true;
      } catch (e) {
        // Restore original database on failure
        if (await currentBackup.exists()) {
          await currentBackup.copy(dbPath);
        }
        rethrow;
      } finally {
        // Clean up temporary backup
        if (await currentBackup.exists()) {
          await currentBackup.delete();
        }
      }
    } catch (e) {
      debugPrint('CoreBackgroundSyncService: Restore failed: $e');
      
      _broadcastBackupEvent(BackupEvent(
        type: BackupEventType.restoreFailed,
        timestamp: DateTime.now(),
        error: e.toString(),
      ));
      
      return false;
    }
  }

  void _broadcastBackupEvent(BackupEvent event) {
    _backupEventController.add(event);
  }

  /// Check if backup file exists in iCloud Documents
  Future<bool> hasBackupAvailable() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${documentsDir.path}/$_backupFileName');
      return await backupFile.exists();
    } catch (e) {
      debugPrint('CoreBackgroundSyncService: Error checking backup availability: $e');
      return false;
    }
  }

  /// Get backup metadata if available
  Future<Map<String, dynamic>?> getBackupMetadata() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final metadataFile = File('${documentsDir.path}/$_backupMetadataFileName');
      
      if (!await metadataFile.exists()) {
        return null;
      }
      
      final metadataJson = await metadataFile.readAsString();
      return jsonDecode(metadataJson);
    } catch (e) {
      debugPrint('CoreBackgroundSyncService: Error reading backup metadata: $e');
      return null;
    }
  }

  /// Stop the backup service
  void stop() {
    _backupTimer?.cancel();
    _backupTimer = null;
    _isInitialized = false;
    
    debugPrint('CoreBackgroundSyncService: Stopped backup service');
  }

  /// Dispose resources
  void dispose() {
    stop();
    _backupEventController.close();
  }
}

/// Backup event types
enum BackupEventType {
  initialized,
  backupStarted,
  backupCompleted,
  backupFailed,
  restoreStarted,
  restoreCompleted,
  restoreFailed,
  error,
}

/// Backup event model
class BackupEvent {
  final BackupEventType type;
  final DateTime timestamp;
  final String? error;
  final Map<String, dynamic> data;

  BackupEvent({
    required this.type,
    required this.timestamp,
    this.error,
    this.data = const {},
  });
}

/// Backup statistics
class BackupStatistics {
  final DateTime? lastSuccessfulBackup;
  final bool isActive;
  final DateTime nextBackupEstimate;

  BackupStatistics({
    this.lastSuccessfulBackup,
    required this.isActive,
    required this.nextBackupEstimate,
  });
}