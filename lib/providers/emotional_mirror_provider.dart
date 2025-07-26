import 'package:flutter/material.dart';
import '../services/emotional_mirror_service.dart';
import '../models/core.dart';
import '../models/emotional_mirror_data.dart';

/// Provider for managing emotional mirror state, filters, and data
class EmotionalMirrorProvider extends ChangeNotifier {
  final EmotionalMirrorService _mirrorService = EmotionalMirrorService();

  // Data state
  EmotionalMirrorData? _mirrorData;
  List<EmotionalTrendPoint>? _intensityTrend;
  List<SentimentTrendPoint>? _sentimentTrend;
  MoodDistribution? _moodDistribution;
  EmotionalJourneyData? _journeyData;
  bool _isLoading = true;
  String? _error;

  // Filter state
  TimeRange _selectedTimeRange = TimeRange.thirtyDays;
  ViewMode _selectedViewMode = ViewMode.overview;
  SortOption _selectedSortOption = SortOption.date;
  String _searchQuery = '';
  final Set<String> _selectedEmotionalCategories = {};
  final Set<IntensityLevel> _selectedIntensityLevels = {};
  final Set<String> _selectedPatternTypes = {};
  final Set<String> _selectedCores = {};
  bool? _isAnalyzedFilter;
  bool _showFilters = false;

  // Getters
  EmotionalMirrorData? get mirrorData => _mirrorData;
  List<EmotionalTrendPoint>? get intensityTrend => _intensityTrend;
  List<SentimentTrendPoint>? get sentimentTrend => _sentimentTrend;
  MoodDistribution? get moodDistribution => _moodDistribution;
  EmotionalJourneyData? get journeyData => _journeyData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TimeRange get selectedTimeRange => _selectedTimeRange;
  ViewMode get selectedViewMode => _selectedViewMode;
  SortOption get selectedSortOption => _selectedSortOption;
  String get searchQuery => _searchQuery;
  Set<String> get selectedEmotionalCategories => _selectedEmotionalCategories;
  Set<IntensityLevel> get selectedIntensityLevels => _selectedIntensityLevels;
  Set<String> get selectedPatternTypes => _selectedPatternTypes;
  Set<String> get selectedCores => _selectedCores;
  bool? get isAnalyzedFilter => _isAnalyzedFilter;
  bool get showFilters => _showFilters;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedEmotionalCategories.isNotEmpty ||
      _selectedIntensityLevels.isNotEmpty ||
      _selectedPatternTypes.isNotEmpty ||
      _selectedCores.isNotEmpty ||
      _isAnalyzedFilter != null;

  int get timeRangeDays {
    switch (_selectedTimeRange) {
      case TimeRange.sevenDays:
        return 7;
      case TimeRange.thirtyDays:
        return 30;
      case TimeRange.ninetyDays:
        return 90;
      case TimeRange.sixMonths:
        return 180;
      case TimeRange.oneYear:
        return 365;
      case TimeRange.allTime:
        return 3650; // 10 years max
    }
  }

  /// Initialize the provider and load data
  Future<void> initialize() async {
    await loadData();
  }

  /// Load all emotional mirror data
  Future<void> loadData() async {
    try {
      _setLoading(true);
      _error = null;

      final daysBack = timeRangeDays;

      // Load all data in parallel
      final results = await Future.wait([
        _mirrorService.getEmotionalMirrorData(daysBack: daysBack),
        _mirrorService.getEmotionalIntensityTrend(daysBack: daysBack),
        _mirrorService.getSentimentTrend(daysBack: daysBack),
        _mirrorService.getMoodDistribution(daysBack: daysBack),
        _mirrorService.getEmotionalJourney(daysBack: daysBack),
      ]);

      _mirrorData = results[0] as EmotionalMirrorData;
      _intensityTrend = results[1] as List<EmotionalTrendPoint>;
      _sentimentTrend = results[2] as List<SentimentTrendPoint>;
      _moodDistribution = results[3] as MoodDistribution;
      _journeyData = results[4] as EmotionalJourneyData;

      _setLoading(false);
    } catch (e) {
      _error = 'Failed to load emotional mirror data: $e';
      _setLoading(false);
      debugPrint('EmotionalMirrorProvider loadData error: $e');
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadData();
  }

  /// Set time range filter
  void setTimeRange(TimeRange timeRange) {
    if (_selectedTimeRange != timeRange) {
      _selectedTimeRange = timeRange;
      notifyListeners();
      loadData(); // Reload data with new time range
    }
  }

  /// Set view mode
  void setViewMode(ViewMode viewMode) {
    if (_selectedViewMode != viewMode) {
      _selectedViewMode = viewMode;
      notifyListeners();
    }
  }

  /// Set sort option
  void setSortOption(SortOption sortOption) {
    if (_selectedSortOption != sortOption) {
      _selectedSortOption = sortOption;
      notifyListeners();
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Toggle emotional category filter
  void toggleEmotionalCategory(String category) {
    if (_selectedEmotionalCategories.contains(category)) {
      _selectedEmotionalCategories.remove(category);
    } else {
      _selectedEmotionalCategories.add(category);
    }
    notifyListeners();
  }

  /// Toggle intensity level filter
  void toggleIntensityLevel(IntensityLevel level) {
    if (_selectedIntensityLevels.contains(level)) {
      _selectedIntensityLevels.remove(level);
    } else {
      _selectedIntensityLevels.add(level);
    }
    notifyListeners();
  }

  /// Toggle pattern type filter
  void togglePatternType(String patternType) {
    if (_selectedPatternTypes.contains(patternType)) {
      _selectedPatternTypes.remove(patternType);
    } else {
      _selectedPatternTypes.add(patternType);
    }
    notifyListeners();
  }

  /// Toggle core filter
  void toggleCore(String core) {
    if (_selectedCores.contains(core)) {
      _selectedCores.remove(core);
    } else {
      _selectedCores.add(core);
    }
    notifyListeners();
  }

  /// Set analyzed filter
  void setAnalyzedFilter(bool? isAnalyzed) {
    if (_isAnalyzedFilter != isAnalyzed) {
      _isAnalyzedFilter = isAnalyzed;
      notifyListeners();
    }
  }

  /// Toggle filters visibility
  void toggleFilters() {
    _showFilters = !_showFilters;
    notifyListeners();
  }

  /// Clear all filters
  void clearAllFilters() {
    _searchQuery = '';
    _selectedEmotionalCategories.clear();
    _selectedIntensityLevels.clear();
    _selectedPatternTypes.clear();
    _selectedCores.clear();
    _isAnalyzedFilter = null;
    notifyListeners();
  }

  /// Get filtered insights based on current filters
  List<String> getFilteredInsights() {
    if (_mirrorData == null) return [];

    var insights = List<String>.from(_mirrorData!.insights);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      insights = insights
          .where((insight) =>
              insight.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply other filters as needed
    // This is a simplified implementation - you could make it more sophisticated

    return insights;
  }

  /// Get filtered patterns based on current filters
  List<EmotionalPattern> getFilteredPatterns() {
    if (_mirrorData == null) return [];

    var patterns = List<EmotionalPattern>.from(_mirrorData!.emotionalPatterns);

    // Apply pattern type filter
    if (_selectedPatternTypes.isNotEmpty) {
      patterns = patterns
          .where((pattern) => _selectedPatternTypes.contains(pattern.type))
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      patterns = patterns
          .where((pattern) =>
              pattern.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              pattern.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return patterns;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

/// Time range options for filtering
enum TimeRange {
  sevenDays,
  thirtyDays,
  ninetyDays,
  sixMonths,
  oneYear,
  allTime,
}

/// View mode options
enum ViewMode {
  overview,
  charts,
  timeline,
}

/// Sort options
enum SortOption {
  date,
  intensity,
  sentiment,
  patternStrength,
}

/// Intensity level options
enum IntensityLevel {
  low,
  medium,
  high,
}

/// Extension methods for enums
extension TimeRangeExtension on TimeRange {
  String get displayName {
    switch (this) {
      case TimeRange.sevenDays:
        return '7 Days';
      case TimeRange.thirtyDays:
        return '30 Days';
      case TimeRange.ninetyDays:
        return '90 Days';
      case TimeRange.sixMonths:
        return '6 Months';
      case TimeRange.oneYear:
        return '1 Year';
      case TimeRange.allTime:
        return 'All Time';
    }
  }
}

extension ViewModeExtension on ViewMode {
  String get displayName {
    switch (this) {
      case ViewMode.overview:
        return 'Overview';
      case ViewMode.charts:
        return 'Charts';
      case ViewMode.timeline:
        return 'Timeline';
    }
  }

  IconData get icon {
    switch (this) {
      case ViewMode.overview:
        return Icons.dashboard_rounded;
      case ViewMode.charts:
        return Icons.analytics_rounded;
      case ViewMode.timeline:
        return Icons.timeline_rounded;
    }
  }
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.date:
        return 'Date';
      case SortOption.intensity:
        return 'Intensity';
      case SortOption.sentiment:
        return 'Sentiment';
      case SortOption.patternStrength:
        return 'Pattern Strength';
    }
  }
}

extension IntensityLevelExtension on IntensityLevel {
  String get displayName {
    switch (this) {
      case IntensityLevel.low:
        return 'Low (0-3)';
      case IntensityLevel.medium:
        return 'Medium (4-7)';
      case IntensityLevel.high:
        return 'High (8-10)';
    }
  }

  String get shortName {
    switch (this) {
      case IntensityLevel.low:
        return 'Low';
      case IntensityLevel.medium:
        return 'Medium';
      case IntensityLevel.high:
        return 'High';
    }
  }
}
