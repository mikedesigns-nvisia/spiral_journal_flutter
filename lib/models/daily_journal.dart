import 'dart:convert';

/// Daily Journal Model
/// 
/// Represents a single day's journal entry that can be continuously updated
/// throughout the day and automatically processed at midnight.
class DailyJournal {
  final String id;
  final DateTime date; // Date only (no time component)
  final String content;
  final List<String> moods;
  final bool isProcessed;
  final DateTime? processedAt;
  final Map<String, dynamic>? aiAnalysis;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyJournal({
    required this.id,
    required this.date,
    this.content = '',
    this.moods = const [],
    this.isProcessed = false,
    this.processedAt,
    this.aiAnalysis,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new daily journal for today
  factory DailyJournal.forToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return DailyJournal(
      id: _generateId(today),
      date: today,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a daily journal for a specific date
  factory DailyJournal.forDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    
    return DailyJournal(
      id: _generateId(dateOnly),
      date: dateOnly,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Generate a consistent ID for a date
  static String _generateId(DateTime date) {
    return 'journal_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted date string
  String get formattedDate {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Get short formatted date
  String get shortFormattedDate {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Get date key for database storage
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if this journal has content
  bool get hasContent => content.trim().isNotEmpty || moods.isNotEmpty;

  /// Get word count
  int get wordCount => content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

  /// Get character count
  int get characterCount => content.length;

  /// Check if this journal is from today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAtSameMomentAs(today);
  }

  /// Check if this journal is from yesterday
  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return date.isAtSameMomentAs(yesterday);
  }

  /// Check if processing is overdue (should have been processed by now)
  bool get isProcessingOverdue {
    if (isProcessed) return false;
    if (isToday) return false; // Today's journal shouldn't be processed yet
    
    final now = DateTime.now();
    final processingDeadline = DateTime(date.year, date.month, date.day + 1, 1, 0); // 1 AM next day
    
    return now.isAfter(processingDeadline);
  }

  /// Get preview text (first 100 characters)
  String get preview {
    if (content.isEmpty) return 'No content yet...';
    return content.length <= 100 ? content : '${content.substring(0, 100)}...';
  }

  /// Copy with updated fields
  DailyJournal copyWith({
    String? id,
    DateTime? date,
    String? content,
    List<String>? moods,
    bool? isProcessed,
    DateTime? processedAt,
    Map<String, dynamic>? aiAnalysis,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyJournal(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      moods: moods ?? this.moods,
      isProcessed: isProcessed ?? this.isProcessed,
      processedAt: processedAt ?? this.processedAt,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': dateKey,
      'content': content,
      'moods': jsonEncode(moods),
      'is_processed': isProcessed ? 1 : 0,
      'processed_at': processedAt?.toIso8601String(),
      'ai_analysis': aiAnalysis != null ? jsonEncode(aiAnalysis) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON (database row)
  factory DailyJournal.fromJson(Map<String, dynamic> json) {
    return DailyJournal(
      id: json['id'],
      date: DateTime.parse(json['date']),
      content: json['content'] ?? '',
      moods: json['moods'] != null 
          ? List<String>.from(jsonDecode(json['moods']))
          : [],
      isProcessed: (json['is_processed'] ?? 0) == 1,
      processedAt: json['processed_at'] != null 
          ? DateTime.parse(json['processed_at'])
          : null,
      aiAnalysis: json['ai_analysis'] != null 
          ? jsonDecode(json['ai_analysis'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  String toString() {
    return 'DailyJournal(id: $id, date: $dateKey, hasContent: $hasContent, isProcessed: $isProcessed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyJournal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Processing status for daily journals
enum ProcessingStatus {
  pending,     // Not yet processed
  processing,  // Currently being processed
  completed,   // Successfully processed
  failed,      // Processing failed
  skipped,     // Skipped due to limits or other reasons
}

/// Extension to get processing status
extension DailyJournalProcessingStatus on DailyJournal {
  ProcessingStatus get processingStatus {
    if (isProcessed) {
      return aiAnalysis != null ? ProcessingStatus.completed : ProcessingStatus.skipped;
    }
    
    if (isProcessingOverdue) {
      return ProcessingStatus.failed;
    }
    
    return ProcessingStatus.pending;
  }
}
