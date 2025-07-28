import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility service for comprehensive accessibility and usability improvements.
/// 
/// This service provides:
/// - Screen reader support with semantic labels
/// - Keyboard navigation for all interactive elements
/// - High contrast mode support
/// - Voice-over compatibility
/// - Focus management and navigation
/// - Accessibility announcements
/// 
/// ## Key Features
/// - **Screen Reader Support**: Comprehensive semantic labels and descriptions
/// - **Keyboard Navigation**: Full keyboard support with logical focus order
/// - **High Contrast Mode**: Enhanced contrast ratios for better visibility
/// - **Voice-Over Compatibility**: Optimized for iOS VoiceOver and Android TalkBack
/// - **Focus Management**: Proper focus handling and navigation
/// - **Accessibility Announcements**: Live region updates for dynamic content
/// 
/// ## Usage Example
/// ```dart
/// final accessibilityService = AccessibilityService();
/// await accessibilityService.initialize();
/// 
/// // Enable high contrast mode
/// await accessibilityService.setHighContrastMode(true);
/// 
/// // Announce dynamic content changes
/// accessibilityService.announceToScreenReader('Entry saved successfully');
/// 
/// // Get accessibility-optimized colors
/// final colors = accessibilityService.getAccessibleColors(context);
/// ```
class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Configuration keys
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _largeTextKey = 'accessibility_large_text';
  static const String _reducedMotionKey = 'accessibility_reduced_motion';
  static const String _screenReaderKey = 'accessibility_screen_reader';

  // State
  bool _highContrastMode = false;
  bool _largeTextMode = false;
  bool _reducedMotionMode = false;
  bool _screenReaderEnabled = false;
  bool _isInitialized = false;

  // Getters
  bool get highContrastMode => _highContrastMode;
  bool get largeTextMode => _largeTextMode;
  bool get reducedMotionMode => _reducedMotionMode;
  bool get screenReaderEnabled => _screenReaderEnabled;
  bool get isInitialized => _isInitialized;

  /// Initialize the accessibility service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load saved preferences
      _highContrastMode = prefs.getBool(_highContrastKey) ?? false;
      _largeTextMode = prefs.getBool(_largeTextKey) ?? false;
      _reducedMotionMode = prefs.getBool(_reducedMotionKey) ?? false;
      _screenReaderEnabled = prefs.getBool(_screenReaderKey) ?? false;

      _isInitialized = true;
    } catch (e) {
      debugPrint('AccessibilityService initialize error: $e');
      // Continue with default values
      _isInitialized = true;
    }
  }

  /// Enable or disable high contrast mode
  Future<void> setHighContrastMode(bool enabled) async {
    if (!_isInitialized) await initialize();

    _highContrastMode = enabled;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_highContrastKey, enabled);
    } catch (e) {
      debugPrint('AccessibilityService setHighContrastMode error: $e');
    }
  }

  /// Enable or disable large text mode
  Future<void> setLargeTextMode(bool enabled) async {
    if (!_isInitialized) await initialize();

    _largeTextMode = enabled;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_largeTextKey, enabled);
    } catch (e) {
      debugPrint('AccessibilityService setLargeTextMode error: $e');
    }
  }

  /// Enable or disable reduced motion mode
  Future<void> setReducedMotionMode(bool enabled) async {
    if (!_isInitialized) await initialize();

    _reducedMotionMode = enabled;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reducedMotionKey, enabled);
    } catch (e) {
      debugPrint('AccessibilityService setReducedMotionMode error: $e');
    }
  }

  /// Enable or disable screen reader optimizations
  Future<void> setScreenReaderEnabled(bool enabled) async {
    if (!_isInitialized) await initialize();

    _screenReaderEnabled = enabled;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_screenReaderKey, enabled);
    } catch (e) {
      debugPrint('AccessibilityService setScreenReaderEnabled error: $e');
    }
  }

  /// Get accessibility-optimized colors based on current settings
  AccessibleColors getAccessibleColors(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_highContrastMode) {
      return AccessibleColors(
        primary: isDark ? Colors.white : Colors.black,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: isDark ? Colors.grey[300]! : Colors.grey[700]!,
        onSecondary: isDark ? Colors.black : Colors.white,
        background: isDark ? Colors.black : Colors.white,
        onBackground: isDark ? Colors.white : Colors.black,
        surface: isDark ? Colors.grey[900]! : Colors.grey[100]!,
        onSurface: isDark ? Colors.white : Colors.black,
        error: isDark ? Colors.red[300]! : Colors.red[800]!,
        onError: isDark ? Colors.black : Colors.white,
        outline: isDark ? Colors.white : Colors.black,
        shadow: isDark ? Colors.white24 : Colors.black26,
      );
    } else {
      // Use theme colors with enhanced contrast
      return AccessibleColors(
        primary: theme.colorScheme.primary,
        onPrimary: theme.colorScheme.onPrimary,
        secondary: theme.colorScheme.secondary,
        onSecondary: theme.colorScheme.onSecondary,
        background: theme.colorScheme.surface,
        onBackground: theme.colorScheme.onSurface,
        surface: theme.colorScheme.surface,
        onSurface: theme.colorScheme.onSurface,
        error: theme.colorScheme.error,
        onError: theme.colorScheme.onError,
        outline: theme.colorScheme.outline,
        shadow: theme.colorScheme.shadow,
      );
    }
  }

  /// Get accessibility-optimized text styles
  AccessibleTextStyles getAccessibleTextStyles(BuildContext context) {
    final theme = Theme.of(context);
    final baseScale = _largeTextMode ? 1.2 : 1.0;
    
    return AccessibleTextStyles(
      displayLarge: theme.textTheme.displayLarge?.copyWith(
        fontSize: (theme.textTheme.displayLarge?.fontSize ?? 57) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.normal,
      ),
      displayMedium: theme.textTheme.displayMedium?.copyWith(
        fontSize: (theme.textTheme.displayMedium?.fontSize ?? 45) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.normal,
      ),
      displaySmall: theme.textTheme.displaySmall?.copyWith(
        fontSize: (theme.textTheme.displaySmall?.fontSize ?? 36) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.normal,
      ),
      headlineLarge: theme.textTheme.headlineLarge?.copyWith(
        fontSize: (theme.textTheme.headlineLarge?.fontSize ?? 32) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.w600,
      ),
      headlineMedium: theme.textTheme.headlineMedium?.copyWith(
        fontSize: (theme.textTheme.headlineMedium?.fontSize ?? 28) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.w600,
      ),
      headlineSmall: theme.textTheme.headlineSmall?.copyWith(
        fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 24) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.w600,
      ),
      titleLarge: theme.textTheme.titleLarge?.copyWith(
        fontSize: (theme.textTheme.titleLarge?.fontSize ?? 22) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.w500,
      ),
      titleMedium: theme.textTheme.titleMedium?.copyWith(
        fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.w500,
      ),
      titleSmall: theme.textTheme.titleSmall?.copyWith(
        fontSize: (theme.textTheme.titleSmall?.fontSize ?? 14) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.w500,
      ),
      bodyLarge: theme.textTheme.bodyLarge?.copyWith(
        fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * baseScale,
      ),
      bodyMedium: theme.textTheme.bodyMedium?.copyWith(
        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * baseScale,
      ),
      bodySmall: theme.textTheme.bodySmall?.copyWith(
        fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) * baseScale,
      ),
      labelLarge: theme.textTheme.labelLarge?.copyWith(
        fontSize: (theme.textTheme.labelLarge?.fontSize ?? 14) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.w500,
      ),
      labelMedium: theme.textTheme.labelMedium?.copyWith(
        fontSize: (theme.textTheme.labelMedium?.fontSize ?? 12) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.w500,
      ),
      labelSmall: theme.textTheme.labelSmall?.copyWith(
        fontSize: (theme.textTheme.labelSmall?.fontSize ?? 11) * baseScale,
        fontWeight: _highContrastMode ? FontWeight.bold : FontWeight.w500,
      ),
    );
  }

  /// Announce text to screen readers
  void announceToScreenReader(String message, {
    Assertiveness assertiveness = Assertiveness.polite,
  }) {
    if (_screenReaderEnabled) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  /// Get semantic label for journal entry
  String getJournalEntrySemanticLabel(String content, List<String> moods, DateTime date) {
    final moodText = moods.isNotEmpty ? 'Moods: ${moods.join(', ')}. ' : '';
    final dateText = 'Date: ${_formatDateForScreenReader(date)}. ';
    final contentPreview = content.length > 100 
        ? '${content.substring(0, 100)}...' 
        : content;
    
    return '$dateText${moodText}Entry: $contentPreview';
  }

  /// Get semantic label for mood selector
  String getMoodSelectorSemanticLabel(String mood, bool isSelected) {
    return '$mood mood ${isSelected ? 'selected' : 'not selected'}. Double tap to ${isSelected ? 'deselect' : 'select'}.';
  }

  /// Get semantic label for core progress
  String getCoreProgressSemanticLabel(String coreName, double percentage, String trend) {
    final percentageText = '${percentage.round()} percent';
    final trendText = trend != 'stable' ? ', $trend' : '';
    return '$coreName core at $percentageText$trendText';
  }

  /// Get comprehensive semantic label for core card
  String getCoreCardSemanticLabel(String coreName, double currentLevel, double previousLevel, String trend, bool hasRecentUpdate) {
    final percentage = (currentLevel * 100).round();
    final previousPercentage = (previousLevel * 100).round();
    final change = percentage - previousPercentage;
    
    String label = '$coreName core at $percentage percent';
    
    // Add trend information
    switch (trend) {
      case 'rising':
        label += ', trending upward';
        break;
      case 'declining':
        label += ', trending downward';
        break;
      default:
        label += ', stable';
    }
    
    // Add change information if significant
    if (change.abs() > 0) {
      final changeText = change > 0 ? 'increased' : 'decreased';
      label += ', $changeText by ${change.abs()} percent';
    }
    
    // Add recent update indicator
    if (hasRecentUpdate) {
      label += ', recently updated';
    }
    
    return label;
  }

  /// Get semantic label for core navigation context
  String getCoreNavigationSemanticLabel(String action, String? coreName, String? sourceContext) {
    String label = action;
    
    if (coreName != null) {
      label += ' $coreName core';
    }
    
    if (sourceContext != null) {
      switch (sourceContext) {
        case 'journal':
          label += ' from journal screen';
          break;
        case 'explore_all':
          label += ' to explore all cores';
          break;
        default:
          label += ' from $sourceContext';
      }
    }
    
    return label;
  }

  /// Get semantic hint for core interactions
  String getCoreInteractionHint(String action, String? coreName) {
    switch (action) {
      case 'view_details':
        return 'Double tap to view ${coreName ?? 'core'} details and insights';
      case 'explore_all':
        return 'Double tap to explore all personality cores';
      case 'navigate_back':
        return 'Double tap to return to previous screen';
      case 'refresh':
        return 'Double tap to refresh core data';
      case 'view_progress':
        return 'Double tap to view detailed progress for ${coreName ?? 'core'}';
      default:
        return 'Double tap to activate';
    }
  }

  /// Announce core update to screen reader with context-aware messaging
  void announceCoreUpdate(String coreName, String updateType, Map<String, dynamic> updateData) {
    if (!_screenReaderEnabled) return;
    
    String message;
    switch (updateType) {
      case 'level_changed':
        final newLevel = ((updateData['newLevel'] as double? ?? 0.0) * 100).round();
        final change = updateData['change'] as double? ?? 0.0;
        final changePercent = (change * 100).round();
        
        if (changePercent > 0) {
          message = '$coreName core increased by $changePercent percent to $newLevel percent';
        } else if (changePercent < 0) {
          message = '$coreName core decreased by ${changePercent.abs()} percent to $newLevel percent';
        } else {
          message = '$coreName core updated to $newLevel percent';
        }
        break;
        
      case 'trend_changed':
        final newTrend = updateData['newTrend'] as String? ?? 'stable';
        final previousTrend = updateData['previousTrend'] as String? ?? 'unknown';
        message = '$coreName core trend changed from $previousTrend to $newTrend';
        break;
        
      case 'milestone_achieved':
        final milestone = updateData['milestone'] as String? ?? 'milestone';
        final level = updateData['level'] as int? ?? 0;
        message = 'Congratulations! $coreName core achieved $milestone at level $level';
        break;
        
      case 'batch_update':
        final affectedCount = updateData['affectedCoreCount'] as int? ?? 1;
        message = '$affectedCount cores updated from your recent journal entry';
        break;
        
      case 'analysis_completed':
        message = 'Core analysis completed for $coreName';
        break;
        
      default:
        message = '$coreName core has been updated';
    }
    
    announceToScreenReader(message, assertiveness: Assertiveness.polite);
  }

  /// Announce navigation context changes for cores
  void announceCoreNavigation(String action, String? coreName, String? sourceContext, String? targetContext) {
    if (!_screenReaderEnabled) return;
    
    String message = action;
    
    if (coreName != null) {
      message += ' $coreName core';
    }
    
    if (sourceContext != null && targetContext != null) {
      message += ' from $sourceContext to $targetContext';
    } else if (sourceContext != null) {
      message += ' from $sourceContext';
    } else if (targetContext != null) {
      message += ' to $targetContext';
    }
    
    announceToScreenReader(message, assertiveness: Assertiveness.polite);
  }

  /// Get comprehensive accessibility label for core impact indicators
  String getCoreImpactSemanticLabel(String coreName, double impactValue, String? relatedContext) {
    final absValue = impactValue.abs();
    final percentage = (impactValue * 100).round();
    
    String impactDescription;
    if (absValue < 0.1) {
      impactDescription = 'stable with no significant change';
    } else if (absValue < 0.3) {
      impactDescription = impactValue > 0 ? 'showing growth' : 'showing decline';
    } else if (absValue < 0.6) {
      impactDescription = impactValue > 0 ? 'showing strong growth' : 'showing notable decline';
    } else {
      impactDescription = impactValue > 0 ? 'showing major growth' : 'showing significant decline';
    }
    
    String label = '$coreName core is $impactDescription';
    
    if (absValue >= 0.1) {
      label += ', ${impactValue > 0 ? 'increased' : 'decreased'} by ${percentage.abs()} percent';
    }
    
    if (relatedContext != null) {
      label += ' from $relatedContext';
    }
    
    return label;
  }

  /// Get semantic label for core correlation charts
  String getCoreCorrelationSemanticLabel(String theme, String coreName, double correlationStrength, int occurrenceCount) {
    final percentage = (correlationStrength * 100).round();
    final strengthDescription = correlationStrength.abs() > 0.5 
        ? 'strong' 
        : correlationStrength.abs() > 0.3 
            ? 'moderate' 
            : 'weak';
    
    final direction = correlationStrength > 0 ? 'positive' : 'negative';
    
    return 'Writing about $theme has a $strengthDescription $direction correlation with $coreName core, $percentage percent impact over $occurrenceCount entries';
  }

  /// Get semantic label for core notification widgets
  String getCoreNotificationSemanticLabel(String title, String message, String notificationType, double? impactValue) {
    String label = '$title. $message';
    
    if (impactValue != null && impactValue.abs() > 0.05) {
      final percentage = (impactValue * 100).round();
      label += '. Impact: ${impactValue > 0 ? 'increased' : 'decreased'} by ${percentage.abs()} percent';
    }
    
    // Add interaction hint based on notification type
    switch (notificationType) {
      case 'milestone_achieved':
        label += '. Double tap to view achievement details';
        break;
      case 'significant_growth':
        label += '. Double tap to view growth details';
        break;
      default:
        label += '. Double tap to view core details';
    }
    
    return label;
  }

  /// Get accessible focus order for core elements
  List<String> getCoreElementFocusOrder() {
    return [
      'core_header',
      'core_overview',
      'core_grid_item_0',
      'core_grid_item_1',
      'core_grid_item_2',
      'core_grid_item_3',
      'core_grid_item_4',
      'core_grid_item_5',
      'core_actions',
    ];
  }

  /// Create semantic properties for core elements
  SemanticsProperties createCoreSemantics({
    required String label,
    String? hint,
    String? value,
    bool? button,
    bool? focusable,
    bool? selected,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return SemanticsProperties(
      label: label,
      hint: hint,
      value: value,
      button: button ?? false,
      focusable: focusable ?? true,
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  /// Get semantic hint for interactive elements
  String getInteractionHint(String action) {
    switch (action) {
      case 'tap':
        return 'Double tap to activate';
      case 'edit':
        return 'Double tap to edit';
      case 'delete':
        return 'Double tap to delete';
      case 'save':
        return 'Double tap to save';
      case 'cancel':
        return 'Double tap to cancel';
      case 'search':
        return 'Double tap to search';
      case 'filter':
        return 'Double tap to filter';
      case 'navigate':
        return 'Double tap to navigate';
      default:
        return 'Double tap to activate';
    }
  }

  /// Create accessible focus node with proper configuration
  FocusNode createAccessibleFocusNode({
    String? debugLabel,
    bool skipTraversal = false,
    bool canRequestFocus = true,
  }) {
    return FocusNode(
      debugLabel: debugLabel,
      skipTraversal: skipTraversal,
      canRequestFocus: canRequestFocus,
    );
  }

  /// Handle keyboard navigation
  bool handleKeyboardNavigation(RawKeyEvent event, List<FocusNode> focusNodes) {
    if (event is RawKeyDownEvent) {
      final isTab = event.logicalKey == LogicalKeyboardKey.tab;
      final isShiftPressed = event.isShiftPressed;
      final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
      final isSpace = event.logicalKey == LogicalKeyboardKey.space;
      final isArrowUp = event.logicalKey == LogicalKeyboardKey.arrowUp;
      final isArrowDown = event.logicalKey == LogicalKeyboardKey.arrowDown;
      final isArrowLeft = event.logicalKey == LogicalKeyboardKey.arrowLeft;
      final isArrowRight = event.logicalKey == LogicalKeyboardKey.arrowRight;

      if (isTab) {
        // Handle tab navigation
        final currentFocus = FocusManager.instance.primaryFocus;
        if (currentFocus != null) {
          if (isShiftPressed) {
            currentFocus.previousFocus();
          } else {
            currentFocus.nextFocus();
          }
          return true;
        }
      } else if (isEnter || isSpace) {
        // Handle activation
        final currentFocus = FocusManager.instance.primaryFocus;
        if (currentFocus != null) {
          // Trigger tap on focused element
          return true;
        }
      } else if (isArrowUp || isArrowDown || isArrowLeft || isArrowRight) {
        // Handle directional navigation
        final currentFocus = FocusManager.instance.primaryFocus;
        if (currentFocus != null) {
          if (isArrowUp) {
            currentFocus.previousFocus();
          } else if (isArrowDown) {
            currentFocus.nextFocus();
          }
          return true;
        }
      }
    }
    
    return false;
  }

  /// Get animation duration based on reduced motion setting
  Duration getAnimationDuration(Duration defaultDuration) {
    return _reducedMotionMode 
        ? Duration(milliseconds: (defaultDuration.inMilliseconds * 0.3).round())
        : defaultDuration;
  }

  /// Get animation curve based on reduced motion setting
  Curve getAnimationCurve(Curve defaultCurve) {
    return _reducedMotionMode ? Curves.linear : defaultCurve;
  }

  /// Check if device has accessibility features enabled
  bool hasSystemAccessibilityEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.accessibleNavigation || 
           mediaQuery.boldText || 
           mediaQuery.highContrast ||
           mediaQuery.invertColors;
  }

  /// Get recommended minimum touch target size
  double getMinimumTouchTargetSize() {
    return 48.0; // Material Design minimum
  }

  /// Get recommended spacing for accessibility
  double getAccessibleSpacing() {
    return _largeTextMode ? 16.0 : 12.0;
  }

  /// Format date for screen reader
  String _formatDateForScreenReader(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    final month = months[date.month - 1];
    final weekday = weekdays[date.weekday - 1];
    
    return '$weekday, $month ${date.day}, ${date.year}';
  }
}

/// Accessibility-optimized color scheme
class AccessibleColors {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color error;
  final Color onError;
  final Color outline;
  final Color shadow;

  AccessibleColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.error,
    required this.onError,
    required this.outline,
    required this.shadow,
  });
}

/// Accessibility-optimized text styles
class AccessibleTextStyles {
  final TextStyle? displayLarge;
  final TextStyle? displayMedium;
  final TextStyle? displaySmall;
  final TextStyle? headlineLarge;
  final TextStyle? headlineMedium;
  final TextStyle? headlineSmall;
  final TextStyle? titleLarge;
  final TextStyle? titleMedium;
  final TextStyle? titleSmall;
  final TextStyle? bodyLarge;
  final TextStyle? bodyMedium;
  final TextStyle? bodySmall;
  final TextStyle? labelLarge;
  final TextStyle? labelMedium;
  final TextStyle? labelSmall;

  AccessibleTextStyles({
    this.displayLarge,
    this.displayMedium,
    this.displaySmall,
    this.headlineLarge,
    this.headlineMedium,
    this.headlineSmall,
    this.titleLarge,
    this.titleMedium,
    this.titleSmall,
    this.bodyLarge,
    this.bodyMedium,
    this.bodySmall,
    this.labelLarge,
    this.labelMedium,
    this.labelSmall,
  });
}

/// Screen reader announcement assertiveness levels
enum Assertiveness {
  polite,
  assertive,
}