import 'dart:convert';
import 'journal_entry.dart';
import 'core.dart';
import 'user_preferences.dart';

/// Comprehensive data export model for Spiral Journal
/// 
/// This model encapsulates all user data for export functionality,
/// providing a complete snapshot of the user's journal data, settings,
/// and emotional core progress.
/// 
/// ## Key Features
/// - **Complete Data Export**: All journal entries, cores, and settings
/// - **Metadata Tracking**: Export timestamp and version information
/// - **JSON Serialization**: Efficient storage and transfer format
/// - **Data Integrity**: Validation and consistency checks
/// - **Privacy Aware**: Optional encryption support
/// 
/// ## Usage Example
/// ```dart
/// final exportData = ExportData(
///   journalEntries: entries,
///   emotionalCores: cores,
///   userPreferences: preferences,
/// );
/// 
/// // Convert to JSON for export
/// final json = exportData.toJson();
/// final jsonString = jsonEncode(json);
/// ```
class ExportData {
  /// All journal entries in the export
  final List<JournalEntry> journalEntries;
  
  /// All emotional cores and their progress
  final List<EmotionalCore> emotionalCores;
  
  /// User preferences and settings
  final UserPreferences userPreferences;
  
  /// Export metadata
  final ExportMetadata metadata;

  ExportData({
    required this.journalEntries,
    required this.emotionalCores,
    required this.userPreferences,
    ExportMetadata? metadata,
  }) : metadata = metadata ?? ExportMetadata.create();

  /// Create from JSON
  factory ExportData.fromJson(Map<String, dynamic> json) {
    return ExportData(
      journalEntries: (json['journalEntries'] as List<dynamic>?)
          ?.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      emotionalCores: (json['emotionalCores'] as List<dynamic>?)
          ?.map((e) => EmotionalCore.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      userPreferences: json['userPreferences'] != null
          ? UserPreferences.fromJson(json['userPreferences'] as Map<String, dynamic>)
          : UserPreferences.defaults,
      metadata: json['metadata'] != null
          ? ExportMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : ExportMetadata.create(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'journalEntries': journalEntries.map((e) => e.toJson()).toList(),
      'emotionalCores': emotionalCores.map((e) => e.toJson()).toList(),
      'userPreferences': userPreferences.toJson(),
      'metadata': metadata.toJson(),
    };
  }

  /// Get export statistics
  ExportStatistics get statistics {
    return ExportStatistics(
      totalEntries: journalEntries.length,
      analyzedEntries: journalEntries.where((e) => e.isAnalyzed).length,
      totalCores: emotionalCores.length,
      activeCores: emotionalCores.where((c) => c.currentLevel > 0).length,
      dateRange: journalEntries.isNotEmpty
          ? DateRange(
              start: journalEntries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b),
              end: journalEntries.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b),
            )
          : null,
      exportSize: _calculateSize(),
    );
  }

  /// Calculate approximate export size in bytes
  int _calculateSize() {
    final jsonString = jsonEncode(toJson());
    return utf8.encode(jsonString).length;
  }

  /// Validate export data integrity
  List<String> validate() {
    final errors = <String>[];

    // Check for duplicate journal entry IDs
    final entryIds = journalEntries.map((e) => e.id).toList();
    final uniqueEntryIds = entryIds.toSet();
    if (entryIds.length != uniqueEntryIds.length) {
      errors.add('Duplicate journal entry IDs found');
    }

    // Check for duplicate core IDs
    final coreIds = emotionalCores.map((c) => c.id).toList();
    final uniqueCoreIds = coreIds.toSet();
    if (coreIds.length != uniqueCoreIds.length) {
      errors.add('Duplicate emotional core IDs found');
    }

    // Validate journal entries
    for (final entry in journalEntries) {
      if (entry.id.isEmpty) {
        errors.add('Journal entry with empty ID found');
      }
      if (entry.content.isEmpty) {
        errors.add('Journal entry with empty content found: ${entry.id}');
      }
    }

    // Validate emotional cores
    for (final core in emotionalCores) {
      if (core.id.isEmpty) {
        errors.add('Emotional core with empty ID found');
      }
      if (core.currentLevel < 0 || core.currentLevel > 1) {
        errors.add('Invalid core level for ${core.name}: ${core.currentLevel}');
      }
    }

    return errors;
  }

  /// Create a copy with updated data
  ExportData copyWith({
    List<JournalEntry>? journalEntries,
    List<EmotionalCore>? emotionalCores,
    UserPreferences? userPreferences,
    ExportMetadata? metadata,
  }) {
    return ExportData(
      journalEntries: journalEntries ?? this.journalEntries,
      emotionalCores: emotionalCores ?? this.emotionalCores,
      userPreferences: userPreferences ?? this.userPreferences,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Export metadata for tracking export information
class ExportMetadata {
  /// When the export was created
  final DateTime exportedAt;
  
  /// App version that created the export
  final String appVersion;
  
  /// Export format version for compatibility
  final String exportVersion;
  
  /// Optional export description
  final String? description;
  
  /// Whether the export is encrypted
  final bool isEncrypted;

  ExportMetadata({
    required this.exportedAt,
    required this.appVersion,
    required this.exportVersion,
    this.description,
    this.isEncrypted = false,
  });

  /// Create metadata with current timestamp
  factory ExportMetadata.create({
    String? description,
    bool isEncrypted = false,
  }) {
    return ExportMetadata(
      exportedAt: DateTime.now(),
      appVersion: '1.0.0', // TODO: Get from package info
      exportVersion: '1.0',
      description: description,
      isEncrypted: isEncrypted,
    );
  }

  /// Create from JSON
  factory ExportMetadata.fromJson(Map<String, dynamic> json) {
    return ExportMetadata(
      exportedAt: DateTime.parse(json['exportedAt']),
      appVersion: json['appVersion'] ?? '1.0.0',
      exportVersion: json['exportVersion'] ?? '1.0',
      description: json['description'],
      isEncrypted: json['isEncrypted'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'exportedAt': exportedAt.toIso8601String(),
      'appVersion': appVersion,
      'exportVersion': exportVersion,
      'description': description,
      'isEncrypted': isEncrypted,
    };
  }
}

/// Statistics about the exported data
class ExportStatistics {
  final int totalEntries;
  final int analyzedEntries;
  final int totalCores;
  final int activeCores;
  final DateRange? dateRange;
  final int exportSize; // in bytes

  ExportStatistics({
    required this.totalEntries,
    required this.analyzedEntries,
    required this.totalCores,
    required this.activeCores,
    required this.dateRange,
    required this.exportSize,
  });

  /// Get human-readable export size
  String get formattedSize {
    if (exportSize < 1024) {
      return '$exportSize B';
    } else if (exportSize < 1024 * 1024) {
      return '${(exportSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(exportSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get analysis coverage percentage
  double get analysisCoverage {
    return totalEntries > 0 ? (analyzedEntries / totalEntries) * 100 : 0;
  }

  /// Get core activity percentage
  double get coreActivity {
    return totalCores > 0 ? (activeCores / totalCores) * 100 : 0;
  }
}

/// Date range for export statistics
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({
    required this.start,
    required this.end,
  });

  /// Get the duration of the date range
  Duration get duration => end.difference(start);

  /// Get human-readable duration
  String get formattedDuration {
    final days = duration.inDays;
    if (days < 30) {
      return '$days days';
    } else if (days < 365) {
      final months = (days / 30).round();
      return '$months months';
    } else {
      final years = (days / 365).round();
      return '$years years';
    }
  }

  /// Format date range as string
  String get formatted {
    final startStr = '${start.day}/${start.month}/${start.year}';
    final endStr = '${end.day}/${end.month}/${end.year}';
    return '$startStr - $endStr';
  }
}

/// Import result information
class ImportResult {
  final bool success;
  final String? error;
  final List<String> warnings;
  final ExportStatistics? statistics;

  ImportResult({
    required this.success,
    this.error,
    this.warnings = const [],
    this.statistics,
  });

  /// Create successful import result
  factory ImportResult.success({
    List<String> warnings = const [],
    ExportStatistics? statistics,
  }) {
    return ImportResult(
      success: true,
      warnings: warnings,
      statistics: statistics,
    );
  }

  /// Create failed import result
  factory ImportResult.failure(String error) {
    return ImportResult(
      success: false,
      error: error,
    );
  }

  /// Check if import has warnings
  bool get hasWarnings => warnings.isNotEmpty;
}