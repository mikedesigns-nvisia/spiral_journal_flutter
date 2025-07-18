import '../models/journal_entry.dart';

/// Repository interface for journal entry operations
/// 
/// This interface defines the contract for journal data access operations,
/// providing a clean abstraction layer between the service layer and data layer.
/// It supports advanced search, filtering, and pagination capabilities.
abstract class JournalRepository {
  // Basic CRUD operations
  Future<String> createEntry(JournalEntry entry);
  Future<JournalEntry?> getEntryById(String id);
  Future<void> updateEntry(JournalEntry entry);
  Future<void> deleteEntry(String id);
  
  // Batch operations
  Future<List<String>> createMultipleEntries(List<JournalEntry> entries);
  Future<void> updateMultipleEntries(List<JournalEntry> entries);
  Future<void> deleteMultipleEntries(List<String> ids);
  
  // Query operations
  Future<List<JournalEntry>> getAllEntries({int? limit, int? offset});
  Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime startDate, 
    DateTime endDate,
    {int? limit, int? offset}
  );
  
  // Search operations
  Future<List<JournalEntry>> searchEntries(
    String query, 
    {int? limit, int? offset}
  );
  Future<List<JournalEntry>> searchEntriesFullText(
    String query,
    {int? limit, int? offset}
  );
  
  // Filter operations
  Future<List<JournalEntry>> getEntriesByMood(
    String mood,
    {int? limit, int? offset}
  );
  Future<List<JournalEntry>> getEntriesByAIMood(
    String mood,
    {int? limit, int? offset}
  );
  Future<List<JournalEntry>> getEntriesByTheme(
    String theme,
    {int? limit, int? offset}
  );
  Future<List<JournalEntry>> getEntriesByIntensityRange(
    double minIntensity,
    double maxIntensity,
    {int? limit, int? offset}
  );
  Future<List<JournalEntry>> getAnalyzedEntries(
    {bool analyzed = true, int? limit, int? offset}
  );
  
  // Advanced search with multiple filters
  Future<List<JournalEntry>> searchEntriesAdvanced({
    String? textQuery,
    List<String>? moods,
    List<String>? aiMoods,
    DateTime? startDate,
    DateTime? endDate,
    double? minIntensity,
    double? maxIntensity,
    bool? isAnalyzed,
    List<String>? themes,
    int? limit,
    int? offset,
  });
  
  // Statistics and analytics
  Future<int> getEntryCount();
  Future<Map<String, int>> getMonthlyEntryCounts(int year);
  Future<Map<String, int>> getMoodFrequency();
  Future<List<JournalEntry>> getEntriesWithDrafts();
  
  // Data management
  Future<void> clearAllEntries();
  Future<Map<String, dynamic>> exportAllEntries();
}

/// Search filters for advanced journal entry queries
class JournalSearchFilters {
  final String? textQuery;
  final List<String>? moods;
  final List<String>? aiMoods;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minIntensity;
  final double? maxIntensity;
  final bool? isAnalyzed;
  final List<String>? themes;
  final int? limit;
  final int? offset;

  const JournalSearchFilters({
    this.textQuery,
    this.moods,
    this.aiMoods,
    this.startDate,
    this.endDate,
    this.minIntensity,
    this.maxIntensity,
    this.isAnalyzed,
    this.themes,
    this.limit,
    this.offset,
  });

  /// Create a copy with updated filters
  JournalSearchFilters copyWith({
    String? textQuery,
    List<String>? moods,
    List<String>? aiMoods,
    DateTime? startDate,
    DateTime? endDate,
    double? minIntensity,
    double? maxIntensity,
    bool? isAnalyzed,
    List<String>? themes,
    int? limit,
    int? offset,
  }) {
    return JournalSearchFilters(
      textQuery: textQuery ?? this.textQuery,
      moods: moods ?? this.moods,
      aiMoods: aiMoods ?? this.aiMoods,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minIntensity: minIntensity ?? this.minIntensity,
      maxIntensity: maxIntensity ?? this.maxIntensity,
      isAnalyzed: isAnalyzed ?? this.isAnalyzed,
      themes: themes ?? this.themes,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Check if any filters are applied
  bool get hasFilters {
    return textQuery != null ||
        (moods != null && moods!.isNotEmpty) ||
        (aiMoods != null && aiMoods!.isNotEmpty) ||
        startDate != null ||
        endDate != null ||
        minIntensity != null ||
        maxIntensity != null ||
        isAnalyzed != null ||
        (themes != null && themes!.isNotEmpty);
  }
}

/// Pagination information for journal entry queries
class JournalPagination {
  final int limit;
  final int offset;
  final int? totalCount;

  const JournalPagination({
    required this.limit,
    required this.offset,
    this.totalCount,
  });

  /// Get the current page number (1-based)
  int get currentPage => (offset ~/ limit) + 1;

  /// Get the total number of pages
  int? get totalPages => totalCount != null ? (totalCount! / limit).ceil() : null;

  /// Check if there are more pages
  bool get hasNextPage => totalCount != null ? offset + limit < totalCount! : true;

  /// Check if there are previous pages
  bool get hasPreviousPage => offset > 0;

  /// Get pagination for the next page
  JournalPagination get nextPage {
    return JournalPagination(
      limit: limit,
      offset: offset + limit,
      totalCount: totalCount,
    );
  }

  /// Get pagination for the previous page
  JournalPagination get previousPage {
    return JournalPagination(
      limit: limit,
      offset: (offset - limit).clamp(0, double.infinity).toInt(),
      totalCount: totalCount,
    );
  }
}