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

  final ThemeService _themeService;
  final SettingsService _settingsService;
  // PIN auth service removed - using biometrics-only authentication

  int _currentSlideIndex = 0;
  bool _isLoading = false;
  QuickSetupConfig _quickSetupConfig = const QuickSetupConfig();
  final List<OnboardingSlide> _slides = OnboardingSlide.getAllSlides();

  OnboardingController({
    required ThemeService themeService,
    required SettingsService settingsService,
    // PIN auth service parameter removed - using biometrics-only authentication
  })  : _themeService = themeService,
        _settingsService = settingsService;
        // PIN auth service assignment removed - using biometrics-only authentication

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
