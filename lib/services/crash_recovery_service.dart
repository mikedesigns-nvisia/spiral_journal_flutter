import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';
import '../utils/app_error_handler.dart';

/// Service for handling crash recovery and draft preservation
class CrashRecoveryService {
  static final CrashRecoveryService _instance = CrashRecoveryService._internal();
  factory CrashRecoveryService() => _instance;
  CrashRecoveryService._internal();

  static const String _draftPrefix = 'draft_';
  static const String _crashLogKey = 'crash_log';
  static const String _lastActiveEntryKey = 'last_active_entry';

  /// Save draft content for crash recovery
  Future<void> saveDraft(String entryId, String content) async {
    return await AppErrorHandler().handleError(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final draftKey = '$_draftPrefix$entryId';
        
        final draftData = {
          'content': content,
          'timestamp': DateTime.now().toIso8601String(),
          'entryId': entryId,
        };
        
        await prefs.setString(draftKey, jsonEncode(draftData));
        await prefs.setString(_lastActiveEntryKey, entryId);
        
        if (kDebugMode) {
          debugPrint('Draft saved for entry: $entryId');
        }
      },
      operationName: 'saveDraft',
      component: 'CrashRecoveryService',
      context: {
        'entryId': entryId,
        'contentLength': content.length,
      },
      allowRetry: false,
      showUserMessage: false,
    );
  }

  /// Recover draft content after crash
  Future<DraftData?> recoverDraft(String entryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = '$_draftPrefix$entryId';
      final draftJson = prefs.getString(draftKey);
      
      if (draftJson == null) return null;
      
      final draftMap = jsonDecode(draftJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(draftMap['timestamp']);
      
      // Only return drafts from the last 24 hours
      if (DateTime.now().difference(timestamp) > const Duration(hours: 24)) {
        await clearDraft(entryId);
        return null;
      }
      
      return DraftData(
        entryId: draftMap['entryId'],
        content: draftMap['content'],
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Error recovering draft: $e');
      return null;
    }
  }

  /// Get all available drafts
  Future<List<DraftData>> getAllDrafts() async {
    return await AppErrorHandler().handleError(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((key) => key.startsWith(_draftPrefix));
        final drafts = <DraftData>[];
        
        for (final key in keys) {
          final draftJson = prefs.getString(key);
          if (draftJson != null) {
            try {
              final draftMap = jsonDecode(draftJson) as Map<String, dynamic>;
              final timestamp = DateTime.parse(draftMap['timestamp']);
              
              // Only include recent drafts
              if (DateTime.now().difference(timestamp) <= const Duration(hours: 24)) {
                drafts.add(DraftData(
                  entryId: draftMap['entryId'],
                  content: draftMap['content'],
                  timestamp: timestamp,
                ));
              } else {
                // Clean up old drafts
                await prefs.remove(key);
              }
            } catch (e) {
              // Remove corrupted draft data
              await prefs.remove(key);
            }
          }
        }
        
        // Sort by timestamp, most recent first
        drafts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return drafts;
      },
      operationName: 'getAllDrafts',
      component: 'CrashRecoveryService',
      allowRetry: false,
      showUserMessage: false,
    ) ?? [];
  }

  /// Clear draft after successful save
  Future<void> clearDraft(String entryId) async {
    return await AppErrorHandler().handleError(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final draftKey = '$_draftPrefix$entryId';
        await prefs.remove(draftKey);
        
        // Clear last active entry if it matches
        final lastActive = prefs.getString(_lastActiveEntryKey);
        if (lastActive == entryId) {
          await prefs.remove(_lastActiveEntryKey);
        }
        
        if (kDebugMode) {
          debugPrint('Draft cleared for entry: $entryId');
        }
      },
      operationName: 'clearDraft',
      component: 'CrashRecoveryService',
      context: {'entryId': entryId},
      allowRetry: false,
      showUserMessage: false,
    );
  }

  /// Clear all drafts
  Future<void> clearAllDrafts() async {
    return await AppErrorHandler().handleError(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((key) => key.startsWith(_draftPrefix));
        
        for (final key in keys) {
          await prefs.remove(key);
        }
        
        await prefs.remove(_lastActiveEntryKey);
        
        if (kDebugMode) {
          debugPrint('All drafts cleared');
        }
      },
      operationName: 'clearAllDrafts',
      component: 'CrashRecoveryService',
      allowRetry: false,
      showUserMessage: false,
    );
  }

  /// Get the last active entry ID
  Future<String?> getLastActiveEntry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastActiveEntryKey);
    } catch (e) {
      debugPrint('Error getting last active entry: $e');
      return null;
    }
  }

  /// Log crash information for debugging
  Future<void> logCrash(String error, StackTrace stackTrace) async {
    return await AppErrorHandler().handleError(
      () async {
        final prefs = await SharedPreferences.getInstance();
        
        final crashData = {
          'error': error,
          'stackTrace': stackTrace.toString(),
          'timestamp': DateTime.now().toIso8601String(),
          'platform': defaultTargetPlatform.name,
        };
        
        // Keep only the last 5 crash logs
        final existingLogs = prefs.getStringList(_crashLogKey) ?? [];
        existingLogs.insert(0, jsonEncode(crashData));
        
        if (existingLogs.length > 5) {
          existingLogs.removeRange(5, existingLogs.length);
        }
        
        await prefs.setStringList(_crashLogKey, existingLogs);
        
        if (kDebugMode) {
          debugPrint('Crash logged: $error');
        }
      },
      operationName: 'logCrash',
      component: 'CrashRecoveryService',
      allowRetry: false,
      showUserMessage: false,
    );
  }

  /// Get crash logs for debugging
  Future<List<CrashLog>> getCrashLogs() async {
    return await AppErrorHandler().handleError(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final logStrings = prefs.getStringList(_crashLogKey) ?? [];
        final logs = <CrashLog>[];
        
        for (final logString in logStrings) {
          try {
            final logMap = jsonDecode(logString) as Map<String, dynamic>;
            logs.add(CrashLog(
              error: logMap['error'],
              stackTrace: logMap['stackTrace'],
              timestamp: DateTime.parse(logMap['timestamp']),
              platform: logMap['platform'],
            ));
          } catch (e) {
            // Skip corrupted log entries
            continue;
          }
        }
        
        return logs;
      },
      operationName: 'getCrashLogs',
      component: 'CrashRecoveryService',
      allowRetry: false,
      showUserMessage: false,
    ) ?? [];
  }

  /// Check if there are any drafts to recover
  Future<bool> hasDraftsToRecover() async {
    final drafts = await getAllDrafts();
    return drafts.isNotEmpty;
  }

  /// Auto-save draft content periodically
  Future<void> autoSaveDraft(String entryId, String content) async {
    // Only auto-save if content has meaningful length
    if (content.trim().length < 10) return;
    
    await saveDraft(entryId, content);
  }

  /// Create a journal entry from draft data
  JournalEntry createEntryFromDraft(DraftData draft) {
    return JournalEntry(
      id: draft.entryId,
      userId: 'local_user', // Default for local-only mode
      date: draft.timestamp,
      content: draft.content,
      moods: [], // Will be set by user
      dayOfWeek: _getDayOfWeek(draft.timestamp),
      createdAt: draft.timestamp,
      updatedAt: DateTime.now(),
      draftContent: draft.content,
    );
  }

  String _getDayOfWeek(DateTime date) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[date.weekday - 1];
  }
}

/// Data class for draft information
class DraftData {
  final String entryId;
  final String content;
  final DateTime timestamp;

  DraftData({
    required this.entryId,
    required this.content,
    required this.timestamp,
  });

  bool get isRecent => DateTime.now().difference(timestamp) < const Duration(hours: 1);
  
  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

/// Data class for crash log information
class CrashLog {
  final String error;
  final String stackTrace;
  final DateTime timestamp;
  final String platform;

  CrashLog({
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    required this.platform,
  });
}
