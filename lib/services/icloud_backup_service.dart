import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/export_data.dart';
import '../services/data_export_service.dart';

/// Service for managing iCloud document backup and restore functionality.
/// 
/// This service provides cloud backup capabilities using iCloud Documents folder,
/// allowing users to securely backup and restore their journal data across devices.
class ICloudBackupService {
  static final ICloudBackupService _instance = ICloudBackupService._internal();
  factory ICloudBackupService() => _instance;
  ICloudBackupService._internal();

  final DataExportService _exportService = DataExportService();
  
  static const String _backupFileName = 'spiral_journal_backup.json';
  static const String _backupFolderName = 'SpiralJournal';

  /// Initialize the iCloud backup service
  Future<void> initialize() async {
    try {
      await _exportService.initialize();
    } catch (e) {
      debugPrint('ICloudBackupService initialize error: $e');
      rethrow;
    }
  }

  /// Create a backup to iCloud Documents
  Future<BackupResult> backupToICloud() async {
    try {
      // Export all data
      final exportData = await _exportService.exportAllData();

      // Get iCloud Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${documentsDir.path}/$_backupFolderName');
      
      // Create backup directory if it doesn't exist
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Create backup file
      final backupFile = File('${backupDir.path}/$_backupFileName');
      
      // Convert to JSON and save
      final jsonData = jsonEncode(exportData.toJson());
      await backupFile.writeAsString(jsonData);

      // Verify backup was created
      if (await backupFile.exists()) {
        debugPrint('ICloudBackupService: Backup created successfully at ${backupFile.path}');
        return BackupResult.success('Backup created successfully');
      } else {
        return BackupResult.failure('Failed to create backup file');
      }
    } catch (e) {
      debugPrint('ICloudBackupService backupToICloud error: $e');
      return BackupResult.failure('Backup failed: ${e.toString()}');
    }
  }

  /// Restore data from iCloud backup
  Future<BackupResult> restoreFromICloud() async {
    try {
      // Check if backup exists
      final hasBackup = await this.hasBackup();
      if (!hasBackup) {
        return BackupResult.failure('No backup found');
      }

      // Get backup file
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${documentsDir.path}/$_backupFolderName/$_backupFileName');

      // Read and parse backup data
      final jsonString = await backupFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Create ExportData from JSON
      final exportData = ExportData.fromJson(jsonData);

      // Import the data using the export service
      final importResult = await _exportService.importData(exportData);

      if (importResult.success) {
        return BackupResult.success('Data restored successfully');
      } else {
        return BackupResult.failure(importResult.error ?? 'Import failed');
      }
    } catch (e) {
      debugPrint('ICloudBackupService restoreFromICloud error: $e');
      return BackupResult.failure('Restore failed: ${e.toString()}');
    }
  }

  /// Check if a backup exists in iCloud
  Future<bool> hasBackup() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${documentsDir.path}/$_backupFolderName/$_backupFileName');
      return await backupFile.exists();
    } catch (e) {
      debugPrint('ICloudBackupService hasBackup error: $e');
      return false;
    }
  }

  /// Get backup information
  Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      if (!await hasBackup()) {
        return null;
      }

      final documentsDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${documentsDir.path}/$_backupFolderName/$_backupFileName');
      
      final stat = await backupFile.stat();
      final size = stat.size;
      final lastModified = stat.modified;

      return {
        'exists': true,
        'size': size,
        'lastModified': lastModified.toIso8601String(),
        'path': backupFile.path,
      };
    } catch (e) {
      debugPrint('ICloudBackupService getBackupInfo error: $e');
      return null;
    }
  }

  /// Delete backup from iCloud
  Future<bool> deleteBackup() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${documentsDir.path}/$_backupFolderName/$_backupFileName');
      
      if (await backupFile.exists()) {
        await backupFile.delete();
        
        // Try to delete the backup directory if it's empty
        final backupDir = Directory('${documentsDir.path}/$_backupFolderName');
        try {
          final contents = await backupDir.list().toList();
          if (contents.isEmpty) {
            await backupDir.delete();
          }
        } catch (e) {
          // Directory not empty or other error, ignore
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('ICloudBackupService deleteBackup error: $e');
      return false;
    }
  }

  /// Get formatted backup size
  Future<String> getBackupSize() async {
    try {
      final info = await getBackupInfo();
      if (info == null) {
        return 'No backup';
      }

      final size = info['size'] as int;
      if (size < 1024) {
        return '$size B';
      } else if (size < 1024 * 1024) {
        return '${(size / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown size';
    }
  }

  /// Get backup age in human readable format
  Future<String?> getBackupAge() async {
    try {
      final info = await getBackupInfo();
      if (info == null) {
        return null;
      }

      final lastModified = DateTime.parse(info['lastModified'] as String);
      final now = DateTime.now();
      final difference = now.difference(lastModified);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        final minutes = difference.inMinutes;
        return '$minutes minute${minutes == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 1) {
        final hours = difference.inHours;
        return '$hours hour${hours == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 30) {
        final days = difference.inDays;
        return '$days day${days == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).round();
        return '$months month${months == 1 ? '' : 's'} ago';
      } else {
        final years = (difference.inDays / 365).round();
        return '$years year${years == 1 ? '' : 's'} ago';
      }
    } catch (e) {
      return null;
    }
  }
}

/// Result of backup/restore operations
class BackupResult {
  final bool success;
  final String? message;
  final String? error;

  BackupResult._({
    required this.success,
    this.message,
    this.error,
  });

  factory BackupResult.success([String? message]) {
    return BackupResult._(
      success: true,
      message: message,
    );
  }

  factory BackupResult.failure(String error) {
    return BackupResult._(
      success: false,
      error: error,
    );
  }
}