import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../repositories/journal_repository.dart';
import '../repositories/journal_repository_impl.dart';
import '../services/performance_optimization_service.dart';
import '../services/background_ai_processor.dart';
import '../services/emotional_analyzer.dart';
import '../services/core_library_service.dart';

class JournalProvider with ChangeNotifier {
  final JournalService _journalService = JournalService();
  final JournalRepository _repository = JournalRepositoryImpl();
  final PerformanceOptimizationService _perfService = PerformanceOptimizationService();
  final BackgroundAIProcessor _aiProcessor = BackgroundAIProcessor();
  
  List<JournalEntry> _entries = [];
  List<JournalEntry> _filteredEntries = [];
  List<String> _availableYears = [];
  String _selectedYear = '';
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  
  // Search and filter state
  String _searchQuery = '';
  List<String> _selectedMoods = [];
  List<String> _selectedAIMoods = [];
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minIntensity;
  double? _maxIntensity;
  bool? _isAnalyzedFilter;
  List<String> _selectedThemes = [];
  
  // Pagination state
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;

  // Getters
  List<JournalEntry> get entries => hasActiveFilters ? _filteredEntries : _entries;
  List<JournalEntry> get allEntries => _entries;
  List<JournalEntry> get filteredEntries => _filteredEntries;
  List<String> get availableYears => _availableYears;
  String get selectedYear => _selectedYear;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMorePages => _hasMorePages;
  String? get error => _error;
  
  // Search and filter getters
  String get searchQuery => _searchQuery;
  List<String> get selectedMoods => _selectedMoods;
  List<String> get selectedAIMoods => _selectedAIMoods;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  double? get minIntensity => _minIntensity;
  double? get maxIntensity => _maxIntensity;
  bool? get isAnalyzedFilter => _isAnalyzedFilter;
  List<String> get selectedThemes => _selectedThemes;
  
  bool get hasActiveFilters => 
      _searchQuery.isNotEmpty ||
      _selectedMoods.isNotEmpty ||
      _selectedAIMoods.isNotEmpty ||
      _startDate != null ||
      _endDate != null ||
      _minIntensity != null ||
      _maxIntensity != null ||
      _isAnalyzedFilter != null ||
      _selectedThemes.isNotEmpty;

  // Get entries for current selected year
  List<JournalEntry> get currentYearEntries => entries;

  // Get entries grouped by month
  Map<String, List<JournalEntry>> get entriesByMonth {
    final Map<String, List<JournalEntry>> grouped = {};
    for (final entry in entries) {
      final monthKey = entry.monthYear;
      grouped[monthKey] = (grouped[monthKey] ?? [])..add(entry);
    }
    return grouped;
  }

  // Initialize data
  Future<void> initialize() async {
    // Initialize performance services
    await _perfService.initialize(repository: _repository);
    await _aiProcessor.initialize();
    
    await loadAvailableYears();
    if (_availableYears.isNotEmpty) {
      await loadEntriesForYear(_availableYears.first);
    }
    
    // Preload next few pages for better performance
    _perfService.preloadEntries(pages: 2, pageSize: _pageSize);
  }

  // Load available years
  Future<void> loadAvailableYears() async {
    try {
      _setLoading(true);
      _error = null;
      
      final years = await _journalService.getAvailableYears();
      _availableYears = years;
      
      if (years.isNotEmpty && _selectedYear.isEmpty) {
        _selectedYear = years.first;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load entries for specific year
  Future<void> loadEntriesForYear(String year) async {
    try {
      _setLoading(true);
      _error = null;
      
      final entries = await _journalService.getEntriesByYear(int.parse(year));
      _entries = entries;
      _selectedYear = year;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Create new journal entry
  Future<bool> createEntry({
    required String content,
    required List<String> moods,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      debugPrint('JournalProvider: Creating new journal entry');
      final entryId = await _journalService.createJournalEntry(
        content: content,
        moods: moods,
      );
      debugPrint('JournalProvider: Created entry with ID: $entryId');
      
      // Refresh entries for current year immediately
      await loadEntriesForYear(_selectedYear);
      
      // Note: AI analysis is now handled by batch processing service
      debugPrint('JournalProvider: Entry created successfully. AI analysis will be handled in batch.');
      
      return true;
    } catch (e) {
      debugPrint('JournalProvider: Error creating entry: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing entry
  Future<bool> updateEntry(JournalEntry entry) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _journalService.updateEntry(entry);
      
      // Update local list
      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = entry;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete entry
  Future<bool> deleteEntry(String entryId) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _journalService.deleteEntry(entryId);
      
      // Remove from local list
      _entries.removeWhere((entry) => entry.id == entryId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search and filter methods
  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query) return;
    
    _searchQuery = query;
    _currentPage = 0;
    _hasMorePages = true;
    
    await _performSearch();
  }

  Future<void> setMoodFilter(List<String> moods) async {
    if (_selectedMoods.length == moods.length && 
        _selectedMoods.every((mood) => moods.contains(mood))) {
      return;
    }
    
    _selectedMoods = List.from(moods);
    _currentPage = 0;
    _hasMorePages = true;
    
    await _performSearch();
  }

  Future<void> setAIMoodFilter(List<String> aiMoods) async {
    if (_selectedAIMoods.length == aiMoods.length && 
        _selectedAIMoods.every((mood) => aiMoods.contains(mood))) {
      return;
    }
    
    _selectedAIMoods = List.from(aiMoods);
    _currentPage = 0;
    _hasMorePages = true;
    
    await _performSearch();
  }

  Future<void> setDateRangeFilter(DateTime? start, DateTime? end) async {
    if (_startDate == start && _endDate == end) return;
    
    _startDate = start;
    _endDate = end;
    _currentPage = 0;
    _hasMorePages = true;
    
    await _performSearch();
  }

  Future<void> setIntensityFilter(double? min, double? max) async {
    if (_minIntensity == min && _maxIntensity == max) return;
    
    _minIntensity = min;
    _maxIntensity = max;
    _currentPage = 0;
    _hasMorePages = true;
    
    await _performSearch();
  }

  Future<void> setAnalyzedFilter(bool? isAnalyzed) async {
    if (_isAnalyzedFilter == isAnalyzed) return;
    
    _isAnalyzedFilter = isAnalyzed;
    _currentPage = 0;
    _hasMorePages = true;
    
    await _performSearch();
  }

  Future<void> setThemeFilter(List<String> themes) async {
    if (_selectedThemes.length == themes.length && 
        _selectedThemes.every((theme) => themes.contains(theme))) {
      return;
    }
    
    _selectedThemes = List.from(themes);
    _currentPage = 0;
    _hasMorePages = true;
    
    await _performSearch();
  }

  Future<void> clearAllFilters() async {
    _searchQuery = '';
    _selectedMoods.clear();
    _selectedAIMoods.clear();
    _startDate = null;
    _endDate = null;
    _minIntensity = null;
    _maxIntensity = null;
    _isAnalyzedFilter = null;
    _selectedThemes.clear();
    _currentPage = 0;
    _hasMorePages = true;
    _filteredEntries.clear();
    
    notifyListeners();
  }

  Future<void> loadMoreEntries() async {
    if (!_hasMorePages || _isLoadingMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      _currentPage++;
      await _performSearch(append: true);
    } catch (e) {
      _currentPage--; // Revert page increment on error
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _performSearch({bool append = false}) async {
    if (!hasActiveFilters) {
      if (!append) {
        _filteredEntries.clear();
        notifyListeners();
      }
      return;
    }

    try {
      _isSearching = true;
      if (!append) {
        _error = null;
      }
      notifyListeners();

      // Use performance optimization service for lazy loading with caching
      final filters = {
        'textQuery': _searchQuery.isNotEmpty ? _searchQuery : null,
        'moods': _selectedMoods.isNotEmpty ? _selectedMoods : null,
        'aiMoods': _selectedAIMoods.isNotEmpty ? _selectedAIMoods : null,
        'startDate': _startDate,
        'endDate': _endDate,
        'minIntensity': _minIntensity,
        'maxIntensity': _maxIntensity,
        'isAnalyzed': _isAnalyzedFilter,
        'themes': _selectedThemes.isNotEmpty ? _selectedThemes : null,
      };

      final results = await _perfService.loadEntriesLazy(
        page: _currentPage,
        pageSize: _pageSize,
        useCache: true,
        filters: filters,
      );

      if (append) {
        _filteredEntries.addAll(results);
      } else {
        _filteredEntries = results;
      }

      // Check if there are more pages
      _hasMorePages = results.length == _pageSize;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Legacy search methods for backward compatibility
  Future<List<JournalEntry>> searchEntries(String query) async {
    try {
      return await _repository.searchEntriesFullText(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<JournalEntry>> getEntriesByMood(String mood) async {
    try {
      return await _repository.getEntriesByMood(mood);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get monthly statistics
  Future<Map<String, int>> getMonthlyStats(int year) async {
    try {
      return await _journalService.getMonthlyEntryCounts(year);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Refresh current data
  Future<void> refresh() async {
    if (_selectedYear.isNotEmpty) {
      await loadEntriesForYear(_selectedYear);
    } else {
      await initialize();
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Memory management and resource cleanup
  void optimizeMemoryUsage() {
    _perfService.optimizeMemoryUsage();
  }

  void clearCache() {
    _perfService.clearCache();
  }

  Map<String, dynamic> getPerformanceMetrics() {
    return _perfService.performanceMetrics;
  }

  // Background AI processing methods
  Future<void> queueEntryForAnalysis(JournalEntry entry) async {
    debugPrint('JournalProvider: Queueing entry ${entry.id} for analysis');
    await _aiProcessor.queueEntryAnalysis(
      entry,
      priority: ProcessingPriority.normal,
      onComplete: (result) {
        debugPrint('JournalProvider: Analysis completed for entry ${entry.id}');
        // Update entry with analysis result
        _updateEntryWithAnalysis(entry.id, result);
      },
      onError: (error) {
        debugPrint('JournalProvider: AI analysis failed for entry ${entry.id}: $error');
      },
    );
  }

  Future<void> queueBatchAnalysis(List<JournalEntry> entries) async {
    await _aiProcessor.queueBatchAnalysis(
      entries,
      onBatchProgress: (completed, total) {
        if (kDebugMode) {
          debugPrint('Batch analysis progress: $completed/$total');
        }
      },
      onBatchComplete: (results) {
        // Update entries with analysis results
        for (int i = 0; i < entries.length && i < results.length; i++) {
          if (!results[i].containsKey('error')) {
            _updateEntryWithAnalysis(entries[i].id, results[i]);
          }
        }
      },
    );
  }

  void _updateEntryWithAnalysis(String entryId, Map<String, dynamic> analysis) {
    debugPrint('JournalProvider: Updating entry $entryId with analysis');
    
    // Update entry in local lists
    final entryIndex = _entries.indexWhere((e) => e.id == entryId);
    if (entryIndex != -1) {
      // Create updated entry with analysis
      final updatedEntry = _entries[entryIndex].copyWith(
        aiAnalysis: EmotionalAnalysis.fromJson(analysis),
        isAnalyzed: true,
      );
      _entries[entryIndex] = updatedEntry;
      
      // Also update filtered entries if present
      final filteredIndex = _filteredEntries.indexWhere((e) => e.id == entryId);
      if (filteredIndex != -1) {
        _filteredEntries[filteredIndex] = updatedEntry;
      }
      
      // Invalidate cache for this entry
      _perfService.invalidateCache(entryId: entryId);
      
      // Update emotional cores based on this analysis
      _updateCoresWithAnalysis(updatedEntry, analysis);
      
      notifyListeners();
    } else {
      debugPrint('JournalProvider: Entry $entryId not found for analysis update');
    }
  }
  
  // Update emotional cores based on journal analysis
  Future<void> _updateCoresWithAnalysis(JournalEntry entry, Map<String, dynamic> analysis) async {
    try {
      debugPrint('JournalProvider: Updating cores with analysis for entry ${entry.id}');
      
      // Convert raw analysis to EmotionalAnalysisResult
      final emotionalAnalyzer = EmotionalAnalyzer();
      final analysisResult = emotionalAnalyzer.processAnalysis(analysis, entry);
      
      // Get core library service
      final coreLibraryService = CoreLibraryService();
      
      // Update cores with this analysis
      await coreLibraryService.updateCoresWithJournalAnalysis([entry], analysisResult);
      
      debugPrint('JournalProvider: Successfully updated cores with analysis');
    } catch (e) {
      debugPrint('JournalProvider: Error updating cores with analysis: $e');
    }
  }

  @override
  void dispose() {
    // Dispose of performance services
    _perfService.dispose();
    _aiProcessor.dispose();
    
    super.dispose();
  }
}
