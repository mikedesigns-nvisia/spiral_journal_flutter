import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../models/slide_config.dart';
import 'accessibility_service.dart' as app_accessibility;

/// Service for managing accessibility announcements and support for slide navigation
class SlideAccessibilityService {
  static final SlideAccessibilityService _instance = SlideAccessibilityService._internal();
  factory SlideAccessibilityService() => _instance;
  SlideAccessibilityService._internal();

  final app_accessibility.AccessibilityService _accessibilityService = app_accessibility.AccessibilityService();
  bool _isInitialized = false;

  /// Initialize the slide accessibility service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _accessibilityService.initialize();
    _isInitialized = true;
  }

  /// Announce slide change to screen readers
  void announceSlideChange({
    required SlideConfig slideConfig,
    required int currentIndex,
    required int totalSlides,
    String? additionalContext,
  }) {
    if (!_isInitialized) return;

    final slideNumber = currentIndex + 1;
    final announcement = _buildSlideChangeAnnouncement(
      slideConfig: slideConfig,
      slideNumber: slideNumber,
      totalSlides: totalSlides,
      additionalContext: additionalContext,
    );

    _accessibilityService.announceToScreenReader(
      announcement,
      assertiveness: app_accessibility.Assertiveness.polite,
    );
  }

  /// Build comprehensive slide change announcement
  String _buildSlideChangeAnnouncement({
    required SlideConfig slideConfig,
    required int slideNumber,
    required int totalSlides,
    String? additionalContext,
  }) {
    final buffer = StringBuffer();
    
    // Slide position
    buffer.write('Slide $slideNumber of $totalSlides. ');
    
    // Slide title and type
    buffer.write('${slideConfig.title}. ');
    
    // Note: SlideConfig doesn't have a description property, so we skip this
    
    // Content type description
    final contentDescription = _getContentTypeDescription(slideConfig);
    if (contentDescription.isNotEmpty) {
      buffer.write('$contentDescription ');
    }
    
    // Additional context
    if (additionalContext?.isNotEmpty == true) {
      buffer.write('$additionalContext ');
    }
    
    // Navigation hint
    buffer.write('Swipe left or right to navigate between slides.');
    
    return buffer.toString();
  }

  /// Get content type description for screen readers
  String _getContentTypeDescription(SlideConfig slideConfig) {
    switch (slideConfig.id) {
      case 'mood_overview':
        return 'Contains mood distribution charts and recent mood trends.';
      case 'emotional_journey':
        return 'Shows your emotional journey timeline with key insights.';
      case 'pattern_recognition':
        return 'Displays emotional patterns and behavioral insights.';
      case 'self_awareness':
        return 'Presents self-awareness metrics and growth indicators.';
      default:
        return 'Contains emotional mirror insights and data visualizations.';
    }
  }

  /// Get semantic label for slide navigation indicators
  String getSlideIndicatorLabel({
    required int slideIndex,
    required SlideConfig slideConfig,
    required bool isCurrentSlide,
    required int totalSlides,
  }) {
    final slideNumber = slideIndex + 1;
    final status = isCurrentSlide ? 'current' : 'available';
    
    return 'Slide $slideNumber of $totalSlides, ${slideConfig.title}, $status. '
           'Double tap to navigate to this slide.';
  }

  /// Get semantic label for slide content
  String getSlideContentLabel({
    required SlideConfig slideConfig,
    required String contentSummary,
  }) {
    return '${slideConfig.title} slide content. $contentSummary';
  }

  /// Announce slide loading state
  void announceSlideLoading({
    required SlideConfig slideConfig,
    required bool isLoading,
  }) {
    if (!_isInitialized) return;

    final announcement = isLoading
        ? 'Loading ${slideConfig.title} slide content.'
        : '${slideConfig.title} slide content loaded.';

    _accessibilityService.announceToScreenReader(
      announcement,
      assertiveness: app_accessibility.Assertiveness.polite,
    );
  }

  /// Announce slide error state
  void announceSlideError({
    required SlideConfig slideConfig,
    required String errorMessage,
  }) {
    if (!_isInitialized) return;

    final announcement = 'Error loading ${slideConfig.title} slide. $errorMessage';

    _accessibilityService.announceToScreenReader(
      announcement,
      assertiveness: app_accessibility.Assertiveness.assertive,
    );
  }

  /// Get semantic hint for slide interactions
  String getSlideInteractionHint(String interactionType) {
    switch (interactionType) {
      case 'swipe_navigation':
        return 'Swipe left or right to navigate between slides, or use the navigation indicators below.';
      case 'chart_interaction':
        return 'Double tap to interact with chart data. Swipe to navigate between slides.';
      case 'filter_interaction':
        return 'Double tap to modify filters. Changes will apply to current slide data.';
      case 'refresh':
        return 'Double tap to refresh slide content.';
      default:
        return 'Double tap to interact. Swipe left or right to navigate between slides.';
    }
  }

  /// Create accessible focus node for slide elements
  FocusNode createSlideFocusNode({
    required String slideId,
    required String elementId,
    String? debugLabel,
  }) {
    return _accessibilityService.createAccessibleFocusNode(
      debugLabel: debugLabel ?? '${slideId}_$elementId',
      canRequestFocus: true,
      skipTraversal: false,
    );
  }

  /// Get slide navigation semantics
  SemanticsProperties getSlideNavigationSemantics({
    required SlideConfig slideConfig,
    required int currentIndex,
    required int totalSlides,
    required VoidCallback? onTap,
  }) {
    return SemanticsProperties(
      label: getSlideIndicatorLabel(
        slideIndex: currentIndex,
        slideConfig: slideConfig,
        isCurrentSlide: true,
        totalSlides: totalSlides,
      ),
      hint: 'Swipe left or right to navigate, or use navigation indicators',
      onTap: onTap,
      button: false,
      focusable: true,
      focused: true,
    );
  }

  /// Get chart accessibility description
  String getChartAccessibilityDescription({
    required String chartType,
    required Map<String, dynamic> chartData,
  }) {
    switch (chartType) {
      case 'mood_distribution':
        return _describeMoodDistributionChart(chartData);
      case 'emotional_trend':
        return _describeEmotionalTrendChart(chartData);
      case 'pattern_timeline':
        return _describePatternTimelineChart(chartData);
      default:
        return 'Chart displaying emotional data insights.';
    }
  }

  /// Describe mood distribution chart for screen readers
  String _describeMoodDistributionChart(Map<String, dynamic> data) {
    final buffer = StringBuffer('Mood distribution chart. ');
    
    if (data.containsKey('topMood')) {
      buffer.write('Most frequent mood: ${data['topMood']}. ');
    }
    
    if (data.containsKey('moodCount')) {
      buffer.write('Total moods tracked: ${data['moodCount']}. ');
    }
    
    return buffer.toString();
  }

  /// Describe emotional trend chart for screen readers
  String _describeEmotionalTrendChart(Map<String, dynamic> data) {
    final buffer = StringBuffer('Emotional trend chart. ');
    
    if (data.containsKey('trend')) {
      buffer.write('Overall trend: ${data['trend']}. ');
    }
    
    if (data.containsKey('timeRange')) {
      buffer.write('Time range: ${data['timeRange']}. ');
    }
    
    return buffer.toString();
  }

  /// Describe pattern timeline chart for screen readers
  String _describePatternTimelineChart(Map<String, dynamic> data) {
    final buffer = StringBuffer('Pattern timeline chart. ');
    
    if (data.containsKey('patternCount')) {
      buffer.write('Patterns identified: ${data['patternCount']}. ');
    }
    
    if (data.containsKey('timeSpan')) {
      buffer.write('Time span: ${data['timeSpan']}. ');
    }
    
    return buffer.toString();
  }

  /// Check if accessibility features are enabled
  bool get isAccessibilityEnabled => _accessibilityService.isInitialized;

  /// Get accessibility service instance
  app_accessibility.AccessibilityService get accessibilityService => _accessibilityService;
}
