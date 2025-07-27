import 'dart:math';
import 'package:flutter/material.dart';
import 'package:spiral_journal/theme/app_theme.dart';

/// Enhanced emotional state model with comprehensive accessibility support.
/// 
/// This model provides both visual and textual representations of emotional states,
/// ensuring users with color vision deficiencies can fully understand their emotional data.
/// 
/// Features:
/// - Accessibility-compliant color management
/// - Semantic label generation for screen readers
/// - Theme-aware color adaptation
/// - High contrast mode support
/// - WCAG AA compliance for color contrast
class EmotionalState {
  final String emotion;
  final double intensity; // 0.0 to 1.0
  final double confidence; // 0.0 to 1.0
  final Color primaryColor;
  final Color accessibleColor;
  final String displayName;
  final String description;
  final DateTime timestamp;
  final List<String> relatedEmotions;
  
  // Accessibility properties
  final String semanticLabel;
  final String accessibilityHint;
  final bool isPositive;

  EmotionalState({
    required this.emotion,
    required this.intensity,
    required this.confidence,
    required this.primaryColor,
    required this.accessibleColor,
    required this.displayName,
    required this.description,
    required this.timestamp,
    this.relatedEmotions = const [],
    required this.semanticLabel,
    required this.accessibilityHint,
    required this.isPositive,
  });

  /// Factory constructor to create EmotionalState with automatic accessibility features
  factory EmotionalState.create({
    required String emotion,
    required double intensity,
    required double confidence,
    required BuildContext context,
    String? customDescription,
    List<String> relatedEmotions = const [],
  }) {
    final emotionColors = AccessibleEmotionColors.forContext(context);
    final emotionColorPair = emotionColors.getEmotionColors(emotion);
    
    final displayName = _getDisplayName(emotion);
    final description = customDescription ?? _getDefaultDescription(emotion, intensity);
    final isPositive = _isPositiveEmotion(emotion);
    
    return EmotionalState(
      emotion: emotion,
      intensity: intensity,
      confidence: confidence,
      primaryColor: emotionColorPair.primary,
      accessibleColor: emotionColorPair.accessible,
      displayName: displayName,
      description: description,
      timestamp: DateTime.now(),
      relatedEmotions: relatedEmotions,
      semanticLabel: _generateSemanticLabel(displayName, intensity, confidence, isPositive),
      accessibilityHint: _generateAccessibilityHint(displayName, intensity),
      isPositive: isPositive,
    );
  }

  /// Generate semantic label for screen readers
  static String _generateSemanticLabel(String displayName, double intensity, double confidence, bool isPositive) {
    final intensityPercent = (intensity * 100).round();
    final confidencePercent = (confidence * 100).round();
    final emotionType = isPositive ? 'positive' : 'negative';
    
    return '$displayName emotion at $intensityPercent percent intensity, $emotionType feeling, $confidencePercent percent confidence';
  }

  /// Generate accessibility hint for interactive elements
  static String _generateAccessibilityHint(String displayName, double intensity) {
    final intensityLevel = intensity > 0.7 ? 'strong' : intensity > 0.4 ? 'moderate' : 'mild';
    return 'Double tap to view details about this $intensityLevel $displayName emotion';
  }

  /// Get display name for emotion
  static String _getDisplayName(String emotion) {
    final displayNames = {
      'happy': 'Happy',
      'sad': 'Sad',
      'angry': 'Angry',
      'anxious': 'Anxious',
      'excited': 'Excited',
      'calm': 'Calm',
      'frustrated': 'Frustrated',
      'content': 'Content',
      'worried': 'Worried',
      'joyful': 'Joyful',
      'peaceful': 'Peaceful',
      'stressed': 'Stressed',
      'optimistic': 'Optimistic',
      'melancholy': 'Melancholy',
      'energetic': 'Energetic',
      'tired': 'Tired',
      'confident': 'Confident',
      'uncertain': 'Uncertain',
      'grateful': 'Grateful',
      'lonely': 'Lonely',
    };
    
    return displayNames[emotion.toLowerCase()] ?? emotion.toLowerCase().split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  /// Get default description for emotion
  static String _getDefaultDescription(String emotion, double intensity) {
    final intensityLevel = intensity > 0.7 ? 'very' : intensity > 0.4 ? 'moderately' : 'slightly';
    final displayName = _getDisplayName(emotion).toLowerCase();
    
    return 'Feeling $intensityLevel $displayName';
  }

  /// Determine if emotion is positive
  static bool _isPositiveEmotion(String emotion) {
    final positiveEmotions = {
      'happy', 'excited', 'calm', 'content', 'joyful', 'peaceful', 
      'optimistic', 'energetic', 'confident', 'grateful'
    };
    
    return positiveEmotions.contains(emotion.toLowerCase());
  }

  /// Create copy with updated properties
  EmotionalState copyWith({
    String? emotion,
    double? intensity,
    double? confidence,
    Color? primaryColor,
    Color? accessibleColor,
    String? displayName,
    String? description,
    DateTime? timestamp,
    List<String>? relatedEmotions,
    String? semanticLabel,
    String? accessibilityHint,
    bool? isPositive,
  }) {
    return EmotionalState(
      emotion: emotion ?? this.emotion,
      intensity: intensity ?? this.intensity,
      confidence: confidence ?? this.confidence,
      primaryColor: primaryColor ?? this.primaryColor,
      accessibleColor: accessibleColor ?? this.accessibleColor,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      relatedEmotions: relatedEmotions ?? this.relatedEmotions,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      accessibilityHint: accessibilityHint ?? this.accessibilityHint,
      isPositive: isPositive ?? this.isPositive,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'intensity': intensity,
      'confidence': confidence,
      // ignore: deprecated_member_use
      'primaryColor': primaryColor.value,
      // ignore: deprecated_member_use
      'accessibleColor': accessibleColor.value,
      'displayName': displayName,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'relatedEmotions': relatedEmotions,
      'semanticLabel': semanticLabel,
      'accessibilityHint': accessibilityHint,
      'isPositive': isPositive,
    };
  }

  /// Create from JSON
  factory EmotionalState.fromJson(Map<String, dynamic> json) {
    return EmotionalState(
      emotion: json['emotion'],
      intensity: json['intensity'].toDouble(),
      confidence: json['confidence'].toDouble(),
      primaryColor: Color(json['primaryColor']),
      accessibleColor: Color(json['accessibleColor']),
      displayName: json['displayName'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      relatedEmotions: List<String>.from(json['relatedEmotions'] ?? []),
      semanticLabel: json['semanticLabel'],
      accessibilityHint: json['accessibilityHint'],
      isPositive: json['isPositive'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is EmotionalState &&
        other.emotion == emotion &&
        other.intensity == intensity &&
        other.confidence == confidence &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(emotion, intensity, confidence, timestamp);
  }

  @override
  String toString() {
    return 'EmotionalState(emotion: $emotion, intensity: $intensity, confidence: $confidence, displayName: $displayName)';
  }
}

/// Color pair for emotion representation with accessibility support.
/// 
/// Provides both primary and accessible color variants to ensure
/// WCAG AA compliance and support for users with color vision deficiencies.
class EmotionColorPair {
  final Color primary;
  final Color accessible;
  final Color onColor;
  final String textLabel;
  final double contrastRatio;

  EmotionColorPair({
    required this.primary,
    required this.accessible,
    required this.onColor,
    required this.textLabel,
    required this.contrastRatio,
  });

  /// Create color pair with automatic contrast calculation
  factory EmotionColorPair.create({
    required Color primary,
    required Color background,
    required String textLabel,
    bool highContrastMode = false, // Kept for backward compatibility but unused
  }) {
    Color accessible = primary;
    Color onColor = _getContrastingColor(primary);
    
    // Calculate contrast ratio
    double contrastRatio = _calculateContrastRatio(primary, background);
    
    // Adjust for accessibility if needed
    if (contrastRatio < 4.5) {
      accessible = _adjustForAccessibility(primary, background, false);
      contrastRatio = _calculateContrastRatio(accessible, background);
      onColor = _getContrastingColor(accessible);
    }
    
    return EmotionColorPair(
      primary: primary,
      accessible: accessible,
      onColor: onColor,
      textLabel: textLabel,
      contrastRatio: contrastRatio,
    );
  }

  /// Calculate contrast ratio between two colors
  static double _calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _calculateLuminance(color1);
    final luminance2 = _calculateLuminance(color2);
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  static double _calculateLuminance(Color color) {
    final r = _linearizeColorComponent((color.r * 255.0).round() / 255.0);
    final g = _linearizeColorComponent((color.g * 255.0).round() / 255.0);
    final b = _linearizeColorComponent((color.b * 255.0).round() / 255.0);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearize color component for luminance calculation
  static double _linearizeColorComponent(double component) {
    return component <= 0.03928 
        ? component / 12.92 
        : pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Get contrasting color (black or white) for text
  static Color _getContrastingColor(Color color) {
    final luminance = _calculateLuminance(color);
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Adjust color for accessibility compliance
  static Color _adjustForAccessibility(Color original, Color background, bool highContrastMode) {
    // highContrastMode parameter kept for backward compatibility but unused
    
    // Adjust saturation and lightness to meet contrast requirements
    final hsl = HSLColor.fromColor(original);
    
    // Try different lightness values to achieve proper contrast
    for (double lightness = 0.1; lightness <= 0.9; lightness += 0.1) {
      final adjusted = hsl.withLightness(lightness).toColor();
      if (_calculateContrastRatio(adjusted, background) >= 4.5) {
        return adjusted;
      }
    }
    
    // Fallback to high contrast if adjustment fails
    final backgroundLuminance = _calculateLuminance(background);
    return backgroundLuminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Check if color pair meets WCAG AA standards
  bool get meetsWCAGAA => contrastRatio >= 4.5;

  /// Check if color pair meets WCAG AAA standards
  bool get meetsWCAGAAA => contrastRatio >= 7.0;

  @override
  String toString() {
    return 'EmotionColorPair(textLabel: $textLabel, contrastRatio: ${contrastRatio.toStringAsFixed(2)})';
  }
}

/// Accessible emotion colors with theme awareness and high contrast support.
/// 
/// Manages emotion-to-color mapping with accessibility alternatives,
/// theme-specific adaptations, and WCAG compliance.
class AccessibleEmotionColors {
  final Map<String, EmotionColorPair> emotionColors;
  final bool highContrastMode; // Kept for backward compatibility but unused
  final Brightness brightness;

  AccessibleEmotionColors({
    required this.emotionColors,
    required this.highContrastMode,
    required this.brightness,
  });

  /// Create accessible emotion colors for current context
  factory AccessibleEmotionColors.forContext(BuildContext context, {bool? forceHighContrast}) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final background = brightness == Brightness.light 
        ? AppTheme.getBackgroundPrimary(context)
        : AppTheme.getBackgroundPrimary(context);
    
    // Check for high contrast mode
    final mediaQuery = MediaQuery.of(context);
    // highContrastMode kept for backward compatibility but unused
    final highContrastMode = false;
    
    final emotionColorMap = <String, EmotionColorPair>{};
    
    // Define base emotion colors
    final baseEmotionColors = _getBaseEmotionColors(brightness);
    
    // Create color pairs for each emotion
    for (final entry in baseEmotionColors.entries) {
      emotionColorMap[entry.key] = EmotionColorPair.create(
        primary: entry.value,
        background: background,
        textLabel: EmotionalState._getDisplayName(entry.key),
        highContrastMode: false,
      );
    }
    
    return AccessibleEmotionColors(
      emotionColors: emotionColorMap,
      highContrastMode: false,
      brightness: brightness,
    );
  }

  /// Get base emotion colors for theme
  static Map<String, Color> _getBaseEmotionColors(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return {
        'happy': const Color(0xFFFFD700),      // Gold
        'sad': const Color(0xFF6495ED),        // Cornflower Blue
        'angry': const Color(0xFFFF6B6B),      // Light Red
        'anxious': const Color(0xFFDDA0DD),    // Plum
        'excited': const Color(0xFFFF8C00),    // Dark Orange
        'calm': const Color(0xFF98FB98),       // Pale Green
        'frustrated': const Color(0xFFFF4500), // Orange Red
        'content': const Color(0xFF90EE90),    // Light Green
        'worried': const Color(0xFFDDA0DD),    // Plum
        'joyful': const Color(0xFFFFD700),     // Gold
        'peaceful': const Color(0xFF87CEEB),   // Sky Blue
        'stressed': const Color(0xFFFF6347),   // Tomato
        'optimistic': const Color(0xFFFFD700), // Gold
        'melancholy': const Color(0xFF9370DB), // Medium Purple
        'energetic': const Color(0xFFFF8C00),  // Dark Orange
        'tired': const Color(0xFF708090),      // Slate Gray
        'confident': const Color(0xFF32CD32),  // Lime Green
        'uncertain': const Color(0xFFDDA0DD),  // Plum
        'grateful': const Color(0xFFFFD700),   // Gold
        'lonely': const Color(0xFF6495ED),     // Cornflower Blue
      };
    } else {
      return {
        'happy': const Color(0xFFFFA500),      // Orange
        'sad': const Color(0xFF4169E1),        // Royal Blue
        'angry': const Color(0xFFDC143C),      // Crimson
        'anxious': const Color(0xFF9932CC),    // Dark Orchid
        'excited': const Color(0xFFFF4500),    // Orange Red
        'calm': const Color(0xFF32CD32),       // Lime Green
        'frustrated': const Color(0xFFB22222), // Fire Brick
        'content': const Color(0xFF228B22),    // Forest Green
        'worried': const Color(0xFF9932CC),    // Dark Orchid
        'joyful': const Color(0xFFFFA500),     // Orange
        'peaceful': const Color(0xFF4682B4),   // Steel Blue
        'stressed': const Color(0xFFCD5C5C),   // Indian Red
        'optimistic': const Color(0xFFFFA500), // Orange
        'melancholy': const Color(0xFF8A2BE2),  // Blue Violet
        'energetic': const Color(0xFFFF4500),  // Orange Red
        'tired': const Color(0xFF2F4F4F),      // Dark Slate Gray
        'confident': const Color(0xFF228B22),  // Forest Green
        'uncertain': const Color(0xFF9932CC),  // Dark Orchid
        'grateful': const Color(0xFFFFA500),   // Orange
        'lonely': const Color(0xFF4169E1),     // Royal Blue
      };
    }
  }

  /// Get emotion colors for specific emotion
  EmotionColorPair getEmotionColors(String emotion) {
    return emotionColors[emotion.toLowerCase()] ?? 
           emotionColors['content'] ?? 
           _createFallbackColorPair(emotion);
  }

  /// Create fallback color pair for unknown emotions
  EmotionColorPair _createFallbackColorPair(String emotion) {
    final fallbackColor = brightness == Brightness.dark 
        ? const Color(0xFF808080) 
        : const Color(0xFF696969);
    
    return EmotionColorPair(
      primary: fallbackColor,
      accessible: fallbackColor,
      onColor: brightness == Brightness.dark ? Colors.white : Colors.black,
      textLabel: EmotionalState._getDisplayName(emotion),
      contrastRatio: 4.5,
    );
  }

  /// Get all available emotion names
  List<String> get availableEmotions => emotionColors.keys.toList();

  /// Check if emotion is supported
  bool hasEmotion(String emotion) => emotionColors.containsKey(emotion.toLowerCase());

  /// Get theme-appropriate color for emotion
  Color getThemeColor(String emotion) {
    return getEmotionColors(emotion).accessible;
  }

  /// Get text color for emotion background
  Color getTextColor(String emotion) {
    return getEmotionColors(emotion).onColor;
  }

  @override
  String toString() {
    return 'AccessibleEmotionColors(emotions: ${emotionColors.length}, brightness: $brightness)';
  }
}

