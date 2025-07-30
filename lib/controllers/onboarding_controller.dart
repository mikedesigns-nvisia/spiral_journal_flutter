import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_slide.dart';
import '../services/theme_service.dart';
import '../services/settings_service.dart';
// PIN auth service import removed - using biometrics-only authentication

/// Controller for managing onboarding flow state and user interactions
class OnboardingController extends ChangeNotifier {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _quickSetupConfigKey = 'quick_setup_config';
  
  // Progressive Feature Disclosure Keys
  static const String _shownFeaturesKey = 'shown_features';
  static const String _featureUsageCountKey = 'feature_usage_count';
  static const String _lastFeatureShownKey = 'last_feature_shown';

  final ThemeService _themeService;
  final SettingsService _settingsService;
  // PIN auth service removed - using biometrics-only authentication

  int _currentSlideIndex = 0;
  bool _isLoading = false;
  QuickSetupConfig _quickSetupConfig = const QuickSetupConfig();
  final List<OnboardingSlide> _slides = OnboardingSlide.getAllSlides();
  
  // Progressive Feature Disclosure State
  Set<String> _shownFeatures = <String>{};
  Map<String, int> _featureUsageCount = <String, int>{};
  String? _currentDisclosureFeature;
  bool _isShowingFeatureDisclosure = false;

  OnboardingController({
    required ThemeService themeService,
    required SettingsService settingsService,
    // PIN auth service parameter removed - using biometrics-only authentication
  })  : _themeService = themeService,
        _settingsService = settingsService {
        // PIN auth service assignment removed - using biometrics-only authentication
        
        // Initialize feature disclosure state
        loadFeatureDisclosureState();
      }

  // Getters
  int get currentSlideIndex => _currentSlideIndex;
  bool get isLoading => _isLoading;
  QuickSetupConfig get quickSetupConfig => _quickSetupConfig;
  List<OnboardingSlide> get slides => _slides;
  OnboardingSlide get currentSlide => _slides[_currentSlideIndex];
  bool get isFirstSlide => _currentSlideIndex == 0;
  bool get isLastSlide => _currentSlideIndex == _slides.length - 1;
  int get totalSlides => _slides.length;
  double get progress => (_currentSlideIndex + 1) / _slides.length;
  
  // Progressive Feature Disclosure Getters
  Set<String> get shownFeatures => Set.from(_shownFeatures);
  String? get currentDisclosureFeature => _currentDisclosureFeature;
  bool get isShowingFeatureDisclosure => _isShowingFeatureDisclosure;
  Map<String, int> get featureUsageCount => Map.from(_featureUsageCount);

  /// Check if onboarding has been completed
  static Future<bool> hasCompletedOnboarding() async {
    try {
      // Use SettingsService for consistent onboarding state management
      final settingsService = SettingsService();
      await settingsService.initialize();
      return await settingsService.hasCompletedOnboarding();
    } catch (e) {
      debugPrint('OnboardingController hasCompletedOnboarding error: $e');
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Use SettingsService to persist onboarding completion
      await _settingsService.setOnboardingCompleted(true);
      
      // Save quick setup configuration
      await _saveQuickSetupConfig();
      
      // Apply the configuration
      await _applyQuickSetupConfig();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('OnboardingController completeOnboarding error: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Reset onboarding (for testing/debugging)
  static Future<void> resetOnboarding() async {
    try {
      // Use SettingsService for consistent onboarding state management
      final settingsService = SettingsService();
      await settingsService.initialize();
      await settingsService.resetOnboardingStatus();
      
      // Still handle the quick setup config separately
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_quickSetupConfigKey);
    } catch (e) {
      debugPrint('OnboardingController resetOnboarding error: $e');
    }
  }

  /// Navigate to next slide
  void nextSlide() {
    if (!isLastSlide) {
      _currentSlideIndex++;
      notifyListeners();
    }
  }

  /// Navigate to previous slide
  void previousSlide() {
    if (!isFirstSlide) {
      _currentSlideIndex--;
      notifyListeners();
    }
  }

  /// Jump to specific slide
  void goToSlide(int index) {
    if (index >= 0 && index < _slides.length) {
      _currentSlideIndex = index;
      notifyListeners();
    }
  }

  /// Skip to the end of onboarding
  void skipOnboarding() {
    _currentSlideIndex = _slides.length - 1;
    notifyListeners();
  }

  /// Update quick setup configuration
  void updateQuickSetupConfig(QuickSetupConfig config) {
    _quickSetupConfig = config;
    notifyListeners();
  }

  /// Update theme preference
  void updateThemePreference(String theme) {
    _quickSetupConfig = _quickSetupConfig.copyWith(theme: theme);
    notifyListeners();
  }

  /// Update text size preference
  void updateTextSizePreference(String textSize) {
    _quickSetupConfig = _quickSetupConfig.copyWith(textSize: textSize);
    notifyListeners();
  }

  /// Update notifications preference
  void updateNotificationsPreference(bool enabled) {
    _quickSetupConfig = _quickSetupConfig.copyWith(notifications: enabled);
    notifyListeners();
  }

  // PIN setup removed - using biometrics-only authentication

  // Progressive Feature Disclosure Methods
  
  /// Load shown features from SharedPreferences
  Future<void> loadFeatureDisclosureState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load shown features
      final shownFeaturesJson = prefs.getStringList(_shownFeaturesKey) ?? [];
      _shownFeatures = shownFeaturesJson.toSet();
      
      // Load feature usage count
      final usageCountKeys = prefs.getKeys().where((key) => key.startsWith('${_featureUsageCountKey}_'));
      _featureUsageCount.clear();
      for (String key in usageCountKeys) {
        String featureName = key.replaceFirst('${_featureUsageCountKey}_', '');
        _featureUsageCount[featureName] = prefs.getInt(key) ?? 0;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('OnboardingController loadFeatureDisclosureState error: $e');
    }
  }
  
  /// Check if a feature has been shown to the user
  bool hasFeatureBeenShown(String featureName) {
    return _shownFeatures.contains(featureName);
  }
  
  /// Mark a feature as shown and save to SharedPreferences
  Future<void> markFeatureAsShown(String featureName) async {
    try {
      if (!_shownFeatures.contains(featureName)) {
        _shownFeatures.add(featureName);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_shownFeaturesKey, _shownFeatures.toList());
        await prefs.setString(_lastFeatureShownKey, featureName);
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('OnboardingController markFeatureAsShown error: $e');
    }
  }
  
  /// Increment usage count for a feature
  Future<void> incrementFeatureUsage(String featureName) async {
    try {
      _featureUsageCount[featureName] = (_featureUsageCount[featureName] ?? 0) + 1;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_featureUsageCountKey}_$featureName', _featureUsageCount[featureName]!);
      
      // Check if we should unlock new features based on usage
      await _checkForFeatureUnlocks(featureName);
      
      notifyListeners();
    } catch (e) {
      debugPrint('OnboardingController incrementFeatureUsage error: $e');
    }
  }
  
  /// Get usage count for a specific feature
  int getFeatureUsageCount(String featureName) {
    return _featureUsageCount[featureName] ?? 0;
  }
  
  /// Show feature disclosure overlay
  void showFeatureDisclosure(String featureName) {
    if (!hasFeatureBeenShown(featureName)) {
      _currentDisclosureFeature = featureName;
      _isShowingFeatureDisclosure = true;
      notifyListeners();
    }
  }
  
  /// Handle "Got it" button press for feature disclosure
  Future<void> onFeatureDisclosureGotIt() async {
    if (_currentDisclosureFeature != null) {
      await markFeatureAsShown(_currentDisclosureFeature!);
      _currentDisclosureFeature = null;
      _isShowingFeatureDisclosure = false;
      notifyListeners();
    }
  }
  
  /// Dismiss feature disclosure without marking as shown
  void dismissFeatureDisclosure() {
    _currentDisclosureFeature = null;
    _isShowingFeatureDisclosure = false;
    notifyListeners();
  }
  
  /// Check for feature unlocks based on usage patterns
  Future<void> _checkForFeatureUnlocks(String triggeredFeature) async {
    try {
      // Define feature unlock rules based on usage patterns
      final unlockRules = {
        'advanced_journaling': () => getFeatureUsageCount('basic_journal') >= 5,
        'emotional_insights': () => getFeatureUsageCount('basic_journal') >= 3,
        'export_functionality': () => getFeatureUsageCount('basic_journal') >= 10,
        'voice_journaling': () => getFeatureUsageCount('basic_journal') >= 7,
        'template_insights': () => getFeatureUsageCount('emotional_insights') >= 3,
        'batch_processing': () => getFeatureUsageCount('advanced_journaling') >= 5,
      };
      
      for (String featureName in unlockRules.keys) {
        if (!hasFeatureBeenShown(featureName) && unlockRules[featureName]!()) {
          // Schedule feature disclosure for next appropriate moment
          await _scheduleFeatureDisclosure(featureName);
        }
      }
    } catch (e) {
      debugPrint('OnboardingController _checkForFeatureUnlocks error: $e');
    }
  }
  
  /// Schedule a feature to be disclosed at the right moment
  Future<void> _scheduleFeatureDisclosure(String featureName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> scheduledFeatures = prefs.getStringList('scheduled_features') ?? [];
      
      if (!scheduledFeatures.contains(featureName)) {
        scheduledFeatures.add(featureName);
        await prefs.setStringList('scheduled_features', scheduledFeatures);
      }
    } catch (e) {
      debugPrint('OnboardingController _scheduleFeatureDisclosure error: $e');
    }
  }
  
  /// Get next scheduled feature to show
  Future<String?> getNextScheduledFeature() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> scheduledFeatures = prefs.getStringList('scheduled_features') ?? [];
      
      // Return first unshown scheduled feature
      for (String feature in scheduledFeatures) {
        if (!hasFeatureBeenShown(feature)) {
          return feature;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('OnboardingController getNextScheduledFeature error: $e');
      return null;
    }
  }
  
  /// Remove a feature from scheduled list after showing
  Future<void> removeFromScheduled(String featureName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> scheduledFeatures = prefs.getStringList('scheduled_features') ?? [];
      scheduledFeatures.remove(featureName);
      await prefs.setStringList('scheduled_features', scheduledFeatures);
    } catch (e) {
      debugPrint('OnboardingController removeFromScheduled error: $e');
    }
  }
  
  /// Reset all feature disclosure data (for testing)
  Future<void> resetFeatureDisclosureData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove all feature-related keys
      await prefs.remove(_shownFeaturesKey);
      await prefs.remove(_lastFeatureShownKey);
      await prefs.remove('scheduled_features');
      
      // Remove all usage count keys
      final usageCountKeys = prefs.getKeys().where((key) => key.startsWith('${_featureUsageCountKey}_'));
      for (String key in usageCountKeys) {
        await prefs.remove(key);
      }
      
      // Reset local state
      _shownFeatures.clear();
      _featureUsageCount.clear();
      _currentDisclosureFeature = null;
      _isShowingFeatureDisclosure = false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('OnboardingController resetFeatureDisclosureData error: $e');
    }
  }
  
  /// Check if user should see a feature based on usage pattern
  Future<bool> shouldShowFeature(String featureName) async {
    // Don't show if already shown
    if (hasFeatureBeenShown(featureName)) {
      return false;
    }
    
    // Check if feature is scheduled to be shown
    final scheduledFeatures = await _getScheduledFeatures();
    return scheduledFeatures.contains(featureName);
  }
  
  /// Get scheduled features list
  Future<List<String>> _getScheduledFeatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('scheduled_features') ?? [];
    } catch (e) {
      debugPrint('OnboardingController _getScheduledFeatures error: $e');
      return [];
    }
  }
  
  /// Show next available feature if any
  Future<void> showNextAvailableFeature() async {
    final nextFeature = await getNextScheduledFeature();
    if (nextFeature != null && !isShowingFeatureDisclosure) {
      showFeatureDisclosure(nextFeature);
      await removeFromScheduled(nextFeature);
    }
  }
  
  /// Get feature disclosure analytics data
  Map<String, dynamic> getFeatureDisclosureAnalytics() {
    return {
      'total_features_shown': _shownFeatures.length,
      'features_shown': _shownFeatures.toList(),
      'total_usage_events': _featureUsageCount.values.fold(0, (sum, count) => sum + count),
      'feature_usage_breakdown': Map.from(_featureUsageCount),
      'currently_showing_disclosure': _isShowingFeatureDisclosure,
      'current_disclosure_feature': _currentDisclosureFeature,
    };
  }

  /// Save quick setup configuration to preferences
  Future<void> _saveQuickSetupConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = _quickSetupConfig.toJson();
      await prefs.setString(_quickSetupConfigKey, configJson.toString());
    } catch (e) {
      debugPrint('OnboardingController _saveQuickSetupConfig error: $e');
    }
  }

  /// Apply the quick setup configuration to services
  Future<void> _applyQuickSetupConfig() async {
    try {
      // Apply theme preference
      switch (_quickSetupConfig.theme.toLowerCase()) {
        case 'light':
          await _themeService.setThemeMode(ThemeMode.light);
          break;
        case 'dark':
          await _themeService.setThemeMode(ThemeMode.dark);
          break;
        case 'auto':
        default:
          await _themeService.setThemeMode(ThemeMode.system);
          break;
      }

      // Apply text size preference
      double textScaleFactor = 1.0;
      switch (_quickSetupConfig.textSize.toLowerCase()) {
        case 'small':
          textScaleFactor = 0.85;
          break;
        case 'large':
          textScaleFactor = 1.15;
          break;
        case 'medium':
        default:
          textScaleFactor = 1.0;
          break;
      }
      await _settingsService.setTextScaleFactor(textScaleFactor);

      // Apply notifications preference
      await _settingsService.setNotificationsEnabled(_quickSetupConfig.notifications);

      // PIN setup removed - using biometrics-only authentication

      // Disable splash screen after onboarding completion
      // User has seen the onboarding, no need to show splash again
      await _settingsService.setSplashScreenEnabled(false);

    } catch (e) {
      debugPrint('OnboardingController _applyQuickSetupConfig error: $e');
    }
  }

  /// Load saved quick setup configuration
  Future<void> loadQuickSetupConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configString = prefs.getString(_quickSetupConfigKey);
      
      if (configString != null) {
        // Parse the saved configuration
        // Note: This is a simplified parsing - in production you might want to use proper JSON
        _quickSetupConfig = const QuickSetupConfig(); // Use defaults for now
      }
    } catch (e) {
      debugPrint('OnboardingController loadQuickSetupConfig error: $e');
      _quickSetupConfig = const QuickSetupConfig();
    }
  }

  /// Get slide-specific analytics data
  Map<String, dynamic> getSlideAnalytics(OnboardingSlide slide) {
    return {
      'slide_id': slide.id,
      'slide_type': slide.type.toString(),
      'slide_index': _currentSlideIndex,
      'total_slides': _slides.length,
      'progress': progress,
      'has_quick_setup': slide.hasQuickSetup,
    };
  }

  /// Handle slide completion (for analytics)
  void onSlideCompleted(OnboardingSlide slide) {
    // Track slide completion for analytics
    final analytics = getSlideAnalytics(slide);
    debugPrint('Onboarding slide completed: ${analytics['slide_id']}');
    
    // You can add analytics service calls here if needed
    // _analyticsService.trackEvent('onboarding_slide_completed', analytics);
  }

  /// Handle onboarding skip (for analytics)
  void onOnboardingSkipped() {
    final analytics = {
      'skipped_at_slide': _currentSlideIndex,
      'total_slides': _slides.length,
      'progress_when_skipped': progress,
    };
    debugPrint('Onboarding skipped: $analytics');
    
    // You can add analytics service calls here if needed
    // _analyticsService.trackEvent('onboarding_skipped', analytics);
  }

  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}

/// Extension to add theme mode conversion
extension ThemeModeExtension on String {
  ThemeMode get themeMode {
    switch (toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'auto':
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
