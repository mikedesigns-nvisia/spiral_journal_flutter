import '../database/journal_dao.dart';
import '../models/journal_entry.dart';
import '../utils/database_exceptions.dart';
import '../utils/app_error_handler.dart';
import 'journal_repository.dart';

/// Implementation of JournalRepository using JournalDao
/// 
/// This class provides a unified interface for journal entry operations,
/// wrapping the existing JournalDao with enhanced search, filtering, and
/// pagination capabilities. It implements comprehensive error handling
/// and provides a clean abstraction layer for the service layer.
/// 
/// ## Key Features
/// - **Unified Interface**: Single point of access for all journal operations
/// - **Enhanced Search**: Full-text search across content, insights, and themes
/// - **Advanced Filtering**: Filter by moods, AI analysis, date ranges, and intensity
/// - **Efficient Pagination**: Support for large journal collections
/// - **Error Handling**: Comprehensive error handling with meaningful messages
/// - **Performance Optimization**: Efficient database queries with proper indexing
/// 
/// ## Usage Example
/// ```dart
/// final repository = JournalRepositoryImpl();
/// 
/// // Create entry
/// final entryId = await repository.createEntry(entry);
/// 
/// // Advanced search
/// final results = await repository.searchEntriesAdvanced(
///   textQuery: "grateful",
///   moods: ["happy", "content"],
///   startDate: DateTime.now().subtract(Duration(days: 30)),
///   limit: 20,
/// );
/// 
/// // Pagination
/// final pagination = JournalPagination(limit: 20, offset: 0);
/// final entries = await repository.getAllEntries(
///   limit: pagination.limit,
///   offset: pagination.offset,
/// );
/// ```
class JournalRepositoryImpl implements JournalRepository {
  final JournalDao _journalDao;

  JournalRepositoryImpl({JournalDao? journalDao}) 
      : _journalDao = journalDao ?? JournalDao();

  @override
  Future<String> createEntry(JournalEntry entry) async {
    return await AppErrorHandler().handleError(
      () async => await _journalDao.insertJournalEntry(entry),
      operationName: 'createEntry',
      component: 'JournalRepository',
      context: {
        'entryId': entry.id,
        'contentLength': entry.content.length,
        'moodCount': entry.moods.length,
      },
      allowRetry: true,
    ) ?? '';
  }

  @override
  Future<JournalEntry?> getEntryById(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw DatabaseValidationException('Entry ID cannot be empty');
      }
      return await _journalDao.getJournalEntryById(id);
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get journal entry by ID',
        operation: 'getEntryById',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateEntry(JournalEntry entry) async {
    try {
      await _journalDao.updateJournalEntry(entry);
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to update journal entry',
        operation: 'updateEntry',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw DatabaseValidationException('Entry ID cannot be empty');
      }
      await _journalDao.deleteJournalEntry(id);
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to delete journal entry',
        operation: 'deleteEntry',
        originalError: e,
      );
    }
  }

  @override
  Future<List<String>> createMultipleEntries(List<JournalEntry> entries) async {
    try {
      if (entries.isEmpty) {
        return [];
      }
      return await _journalDao.insertMultipleJournalEntries(entries);
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to create multiple journal entries',
        operation: 'createMultipleEntries',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateMultipleEntries(List<JournalEntry> entries) async {
    try {
      if (entries.isEmpty) {
        return;
      }
      await _journalDao.updateMultipleJournalEntries(entries);
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to update multiple journal entries',
        operation: 'updateMultipleEntries',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteMultipleEntries(List<String> ids) async {
    try {
      if (ids.isEmpty) {
        return;
      }
      
      // Validate all IDs
      for (final id in ids) {
        if (id.trim().isEmpty) {
          throw DatabaseValidationException('Entry ID cannot be empty');
        }
      }
      
      await _journalDao.deleteMultipleJournalEntries(ids);
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to delete multiple journal entries',
        operation: 'deleteMultipleEntries',
        originalError: e,
      );
    }
  }

  @override
  Future<List<JournalEntry>> getAllEntries({int? limit, int? offset}) async {
    try {
      final allEntries = await _journalDao.getAllJournalEntries();
      
      // Apply pagination if specified
      if (offset != null || limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = limit != null ? startIndex + limit : allEntries.length;
        
        if (startIndex >= allEntries.length) {
          return [];
        }
        
        return allEntries.sublist(
          startIndex,
          endIndex.clamp(0, allEntries.length),
        );
      }
      
      return allEntries;
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get all journal entries',
        operation: 'getAllEntries',
        originalError: e,
      );
    }
  }

  @override
  Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? limit,
    int? offset,
  }) async {
    try {
      if (startDate.isAfter(endDate)) {
        throw DatabaseValidationException('Start date must be before end date');
      }
      
      final entries = await _journalDao.getJournalEntriesByDateRange(startDate, endDate);
      
      // Apply pagination if specified
      if (offset != null || limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = limit != null ? startIndex + limit : entries.length;
        
        if (startIndex >= entries.length) {
          return [];
        }
        
        return entries.sublist(
          startIndex,
          endIndex.clamp(0, entries.length),
        );
      }
      
      return entries;
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get journal entries by date range',
        operation: 'getEntriesByDateRange',
        originalError: e,
      );
    }
  }

  @override
  Future<List<JournalEntry>> searchEntries(
    String query, {
    int? limit,
    int? offset,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return getAllEntries(limit: limit, offset: offset);
      }
      
      final entries = await _journalDao.searchJournalEntries(query);
      
      // Apply pagination if specified
      if (offset != null || limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = limit != null ? startIndex + limit : entries.length;
        
        if (startIndex >= entries.length) {
          return [];
        }
        
        return entries.sublist(
          startIndex,
          endIndex.clamp(0, entries.length),
        );
      }
      
      return entries;
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to search journal entries',
        operation: 'searchEntries',
        originalError: e,
      );
    }
  }

  @override
  Future<List<JournalEntry>> searchEntriesFullText(
    String query, {
    int? limit,
    int? offset,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return getAllEntries(limit: limit, offset: offset);
      }
      
      final entries = await _journalDao.searchJournalEntriesFullText(query);
      
      // Apply pagination if specified
      if (offset != null || limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = limit != null ? startIndex + limit : entries.length;
        
        if (startIndex >= entries.length) {
          return [];
        }
        
        return entries.sublist(
          startIndex,
          endIndex.clamp(0, entries.length),
        );
      }
      
      return entries;
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to perform full-text search on journal entries',
        operation: 'searchEntriesFullText',
        originalError: e,
      );
    }
  }

  @override
  Future<List<JournalEntry>> getEntriesByMood(
    String mood, {
    int? limit,
    int? offset,
  }) async {
    try {
      if (mood.trim().isEmpty) {
        throw DatabaseValidationException('Mood cannot be empty');
      }
      
      final entries = await _journalDao.getJournalEntriesByMood(mood);
      
      // Apply pagination if specified
      if (offset != null || limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = limit != null ? startIndex + limit : entries.length;
        
        if (startIndex >= entries.length) {
          return [];
        }
        
        return entries.sublist(
          startIndex,
          endIndex.clamp(0, entries.length),
        );
      }
      
      return entries;
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get journal entries by mood',
        operation: 'getEntriesByMood',
        originalError: e,
      );
    }
  }

  @override
  Future<List<JournalEntry>> getEntriesByAIMood(
    String mood, {
    int? limit,
    int? offset,
  }) async {
    try {
      if (mood.trim().isEmpty) {
        throw DatabaseValidationException('AI mood cannot be empty');
      }
      
      final entries = await _journalDao.getJournalEntriesByAIMood(mood);
      
      // Apply pagination if specified
      if (offset != null || limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = limit != null ? startIndex + limit : entries.length;
        
        if (startIndex >= entries.length) {
          return [];
        }
        
        return entries.sublist(
          startIndex,
          endIndex.clamp(0, entries.length),
        );
      }
      
      return entries;
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get journal entries by AI mood',
        operation: 'getEntriesByAIMood',
        originalError: e,
      );
    }
  }

  @override
  Future<List<JournalEntry>> getEntriesByTheme(
    String theme, {
    int? limit,
    int? offset,
  }) async {
    try {
      if (theme.trim().isEmpty) {
        throw DatabaseValidationException('Theme cannot be empty');
      }
      
      final entries = await _journalDao.getJournalEntriesByTheme(theme);
      
      // Apply pagination if specified
      if (offset != null || limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = limit != null ? startIndex + limit : entries.length;
        
        if (startIndex >= entries.length) {
          return [];
        }
        
        return entries.sublist(
          startIndex,
          endIndex.clamp(0, entries.length),
        );
      }
      
      return entries;
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get journal entries by theme',
        operation: 'getEntriesByTheme',
        originalError: e,
      );
    }
  }

  @override
  Future<List<JournalEntry>> getEntriesByIntensityRange(
    double minIntensity,
    double maxIntensity, {
    int? limit,
    int? offset,
  }) async {
    try {
      if (minIntensity < 0.0 || minIntensity > 1.0) {
        throw DatabaseValidationException('Minimum intensity must be between 0.0 and 1.0');
      }
      if (maxIntensity < 0.0 || maxIntensity > 1.0) {
        throw DatabaseValidationException('Maximum intensity must be between 0.0 and 1.0');
      }
      if (minIntensity > maxIntensity) {
        throw DatabaseValidationException('Minimum intensity must be less than or equal to maximum intensity');
      }
      
      final entries = await _journalDao.getJournalEntriesByIntensityRange(minIntensity, maxIntensity);
      
      // Apply pagination if specified
      if (offset != null || limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = limit != null ? startIndex + limit : entries.length;
        
        if (startIndex >= entries.length) {
          return [];
        }
        
        return entries.sublist(
          startIndex,
          endIndex.clamp(0, entries.length),
        );
      }
      
      return entries;
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get journal entries by intensity range',
        operation: 'getEntriesByIntensityRange',
        originalError: e,
      );
    }
  }

  @override
  Future<List<JournalEntry>> getAnalyzedEntries({
    bool analyzed = true,
    int? limit,
    int? offset,
  }) async {
    try {
      final entries = await _journalDao.getAnalyzedEntries(analyzed: analyzed);
      
      // Apply pagination if specified
      if (offset != null || limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = limit != null ? startIndex + limit : entries.length;
        
        if (startIndex >= entries.length) {
          return [];
        }
        
        return entries.sublist(
          startIndex,
          endIndex.clamp(0, entries.length),
        );
      }
      
      return entries;
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get analyzed journal entries',
        operation: 'getAnalyzedEntries',
        originalError: e,
      );
    }
  }

  @override
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
  }) async {
    try {
      // Validate date range
      if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
        throw DatabaseValidationException('Start date must be before end date');
      }
      
      // Validate intensity range
      if (minIntensity != null && (minIntensity < 0.0 || minIntensity > 1.0)) {
        throw DatabaseValidationException('Minimum intensity must be between 0.0 and 1.0');
      }
      if (maxIntensity != null && (maxIntensity < 0.0 || maxIntensity > 1.0)) {
        throw DatabaseValidationException('Maximum intensity must be between 0.0 and 1.0');
      }
      if (minIntensity != null && maxIntensity != null && minIntensity > maxIntensity) {
        throw DatabaseValidationException('Minimum intensity must be less than or equal to maximum intensity');
      }
      
      return await _journalDao.searchJournalEntriesAdvanced(
        textQuery: textQuery,
        moods: moods,
        aiMoods: aiMoods,
        startDate: startDate,
        endDate: endDate,
        minIntensity: minIntensity,
        maxIntensity: maxIntensity,
        isAnalyzed: isAnalyzed,
        themes: themes,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to perform advanced search on journal entries',
        operation: 'searchEntriesAdvanced',
        originalError: e,
      );
    }
  }

  @override
  Future<int> getEntryCount() async {
    try {
      final entries = await _journalDao.getAllJournalEntries();
      return entries.length;
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get journal entry count',
        operation: 'getEntryCount',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, int>> getMonthlyEntryCounts(int year) async {
    try {
      if (year < 1900 || year > 2100) {
        throw DatabaseValidationException('Year must be between 1900 and 2100');
      }
      return await _journalDao.getMonthlyEntryCounts(year);
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get monthly entry counts',
        operation: 'getMonthlyEntryCounts',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, int>> getMoodFrequency() async {
    try {
      return await _journalDao.getMoodFrequency();
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get mood frequency',
        operation: 'getMoodFrequency',
        originalError: e,
      );
    }
  }

  @override
  Future<List<JournalEntry>> getEntriesWithDrafts() async {
    try {
      return await _journalDao.getEntriesWithDrafts();
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to get entries with drafts',
        operation: 'getEntriesWithDrafts',
        originalError: e,
      );
    }
  }

  @override
  Future<void> clearAllEntries() async {
    try {
      final allEntries = await _journalDao.getAllJournalEntries();
      final entryIds = allEntries.map((entry) => entry.id).toList();
      
      if (entryIds.isNotEmpty) {
        await _journalDao.deleteMultipleJournalEntries(entryIds);
      }
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to clear all journal entries',
        operation: 'clearAllEntries',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> exportAllEntries() async {
    try {
      final entries = await _journalDao.getAllJournalEntries();
      
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
        'totalEntries': entries.length,
        'entries': entries.map((entry) => entry.toJson()).toList(),
      };
    } catch (e) {
      throw DatabaseOperationException(
        'Failed to export all journal entries',
        operation: 'exportAllEntries',
        originalError: e,
      );
    }
  }

  /// Search entries using filters object
  Future<List<JournalEntry>> searchWithFilters(JournalSearchFilters filters) async {
    return searchEntriesAdvanced(
      textQuery: filters.textQuery,
      moods: filters.moods,
      aiMoods: filters.aiMoods,
      startDate: filters.startDate,
      endDate: filters.endDate,
      minIntensity: filters.minIntensity,
      maxIntensity: filters.maxIntensity,
      isAnalyzed: filters.isAnalyzed,
      themes: filters.themes,
      limit: filters.limit,
      offset: filters.offset,
    );
  }

  /// Get entries with pagination information
  Future<({List<JournalEntry> entries, JournalPagination pagination})> getEntriesWithPagination(
    JournalPagination pagination, {
    JournalSearchFilters? filters,
  }) async {
    final entries = filters != null && filters.hasFilters
        ? await searchWithFilters(filters.copyWith(
            limit: pagination.limit,
            offset: pagination.offset,
          ))
        : await getAllEntries(
            limit: pagination.limit,
            offset: pagination.offset,
          );

    // Get total count for pagination info
    final totalCount = filters != null && filters.hasFilters
        ? (await searchWithFilters(filters)).length
        : await getEntryCount();

    final updatedPagination = JournalPagination(
      limit: pagination.limit,
      offset: pagination.offset,
      totalCount: totalCount,
    );

    return (entries: entries, pagination: updatedPagination);
  }
}