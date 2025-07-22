import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/slide_config.dart';
import '../services/slide_preloader.dart';
import '../providers/emotional_mirror_provider.dart';
import '../services/chart_optimization_service.dart';
import '../services/slide_accessibility_service.dart';
import '../design_system/slide_design_tokens.dart';
import '../services/slide_micro_interactions_service.dart';

/// Controller for managing slide navigation state in the emotional mirror
class EmotionalMirrorSlideController extends ChangeNotifier {
  final PageController _pageController;
  final List<SlideConfig> _slides;
  int _currentSlide = 0;
  bool _isTransitioning = false;
  final List<int> _navigationHistory = [];
  EmotionalMirrorProvider? _provider;
  BuildContext? _context;
  final SlideAccessibilityService _accessibilityService = SlideAccessibilityService();
  final SlideMicroInteractionsService _microInteractionsService = SlideMicroInteractionsService();

  EmotionalMirrorSlideController({
    required List<SlideConfig> slides,
    int initialSlide = 0,
  }) : _slides = slides,
       _pageController = PageController(initialPage: initialSlide),
       _currentSlide = initialSlide {
    _navigationHistory.add(initialSlide);
    
    // Initialize services
    ChartOptimizationService.initialize();
    _initializeServices();
  }

  /// Initialize accessibility and micro-interactions services
  Future<void> _initializeServices() async {
    await _accessibilityService.initialize();
    await _microInteractionsService.initialize();
  }

  /// The underlying PageController for the slide view
  PageController get pageController => _pageController;

  /// List of slide configurations
  List<SlideConfig> get slides => List.unmodifiable(_slides);

  /// Total number of slides
  int get totalSlides => _slides.length;

  /// Current slide index
  int get currentSlide => _currentSlide;

  /// Current slide configuration
  SlideConfig get currentSlideConfig => _slides[_currentSlide];

  /// Whether a transition is currently in progress
  bool get isTransitioning => _isTransitioning;

  /// Whether we can navigate to the next slide
  bool get canGoNext => _currentSlide < _slides.length - 1;

  /// Whether we can navigate to the previous slide
  bool get canGoPrevious => _currentSlide > 0;

  /// Navigate to the next slide with haptic feedback
  Future<void> nextSlide() async {
    if (!canGoNext || _isTransitioning) {
      // Provide haptic feedback for boundary hit
      if (!canGoNext) {
        await _microInteractionsService.triggerBoundaryHaptic();
      }
      return;
    }
    
    _setTransitionState(true);
    
    try {
      // Trigger success haptic feedback
      await _microInteractionsService.triggerSlideTransitionHaptic();
      
      await _pageController.nextPage(
        duration: SlideDesignTokens.getTransitionDuration(SlideTransitionType.next),
        curve: SlideDesignTokens.getTransitionCurve(SlideTransitionType.next),
      );
    } finally {
      _setTransitionState(false);
    }
  }

  /// Navigate to the previous slide with haptic feedback
  Future<void> previousSlide() async {
    if (!canGoPrevious || _isTransitioning) {
      // Provide haptic feedback for boundary hit
      if (!canGoPrevious) {
        await _microInteractionsService.triggerBoundaryHaptic();
      }
      return;
    }
    
    _setTransitionState(true);
    
    try {
      // Trigger success haptic feedback
      await _microInteractionsService.triggerSlideTransitionHaptic();
      
      await _pageController.previousPage(
        duration: SlideDesignTokens.getTransitionDuration(SlideTransitionType.previous),
        curve: SlideDesignTokens.getTransitionCurve(SlideTransitionType.previous),
      );
    } finally {
      _setTransitionState(false);
    }
  }

  /// Jump directly to a specific slide with haptic feedback
  Future<void> jumpToSlide(int index) async {
    if (index < 0 || index >= _slides.length || index == _currentSlide || _isTransitioning) {
      return;
    }
    
    _setTransitionState(true);
    
    try {
      // Trigger success haptic feedback
      await _microInteractionsService.triggerSlideTransitionHaptic();
      
      // Use design token duration for jump transitions
      final duration = SlideDesignTokens.getTransitionDuration(SlideTransitionType.jump);
      
      await _pageController.animateToPage(
        index,
        duration: duration,
        curve: SlideDesignTokens.getTransitionCurve(SlideTransitionType.jump),
      );
    } finally {
      _setTransitionState(false);
    }
  }

  /// Set transition state and notify chart optimization service
  void _setTransitionState(bool isTransitioning) {
    _isTransitioning = isTransitioning;
    ChartOptimizationService.setTransitionState(isTransitioning);
    notifyListeners();
  }

  /// Trigger haptic feedback for successful slide transitions
  void _triggerSuccessHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  /// Trigger haptic feedback for boundary hits
  void _triggerBoundaryHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  /// Update the current slide index (called by PageView)
  void updateCurrentSlide(int index) {
    if (index >= 0 && index < _slides.length && index != _currentSlide) {
      final previousSlide = _currentSlide;
      _currentSlide = index;
      _navigationHistory.add(index);
      
      // Keep navigation history manageable
      if (_navigationHistory.length > 20) {
        _navigationHistory.removeAt(0);
      }
      
      notifyListeners();
      
      // Announce slide change for accessibility
      _announceSlideChange(previousSlide, index);
      
      // Trigger preloading for adjacent slides
      _triggerPreloading();
    }
  }

  /// Announce slide change to screen readers
  void _announceSlideChange(int previousIndex, int newIndex) {
    if (newIndex >= 0 && newIndex < _slides.length) {
      final slideConfig = _slides[newIndex];
      
      // Add context about navigation direction
      String? navigationContext;
      if (previousIndex >= 0 && previousIndex < _slides.length) {
        if (newIndex > previousIndex) {
          navigationContext = 'Navigated forward to';
        } else if (newIndex < previousIndex) {
          navigationContext = 'Navigated back to';
        } else {
          navigationContext = 'Jumped to';
        }
      }
      
      _accessibilityService.announceSlideChange(
        slideConfig: slideConfig,
        currentIndex: newIndex,
        totalSlides: _slides.length,
        additionalContext: navigationContext,
      );
    }
  }

  /// Set the provider and context for preloading
  void setPreloadingContext(EmotionalMirrorProvider provider, BuildContext context) {
    _provider = provider;
    _context = context;
    
    // Initial preloading
    _triggerPreloading();
  }

  /// Trigger intelligent preloading of adjacent slides
  void _triggerPreloading() {
    if (_provider == null || _context == null) return;
    
    // Use intelligent preloading with navigation history
    SlidePreloader.intelligentPreload(
      currentIndex: _currentSlide,
      slides: _slides,
      provider: _provider!,
      context: _context!,
      recentlyVisited: _navigationHistory,
    );
  }

  /// Get navigation history for analytics
  List<int> get navigationHistory => List.unmodifiable(_navigationHistory);

  /// Clear navigation history
  void clearNavigationHistory() {
    _navigationHistory.clear();
    _navigationHistory.add(_currentSlide);
  }

  /// Get slide configuration by index
  SlideConfig? getSlideConfig(int index) {
    if (index >= 0 && index < _slides.length) {
      return _slides[index];
    }
    return null;
  }

  /// Get slide index by ID
  int getSlideIndex(String slideId) {
    return _slides.indexWhere((slide) => slide.id == slideId);
  }

  /// Navigate to slide by ID
  Future<void> jumpToSlideById(String slideId) async {
    final index = getSlideIndex(slideId);
    if (index != -1) {
      await jumpToSlide(index);
    }
  }

  @override
  void dispose() {
    // Clear any preloaded slides for this controller
    if (_provider != null) {
      for (final slide in _slides) {
        SlidePreloader.clearPreloadedSlide(slide.id, _provider!.hashCode);
      }
    }
    
    _pageController.dispose();
    super.dispose();
  }
}
