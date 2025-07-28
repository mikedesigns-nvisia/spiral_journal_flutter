import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../services/accessibility_service.dart';

/// Service that ensures visual consistency across all core displays
class CoreVisualConsistencyService {
  static final CoreVisualConsistencyService _instance = CoreVisualConsistencyService._internal();
  factory CoreVisualConsistencyService() => _instance;
  CoreVisualConsistencyService._internal();

  final AccessibilityService _accessibilityService = AccessibilityService();

  /// Standardized core color schemes with accessibility support
  Map<String, CoreColorScheme> getCoreColorSchemes(BuildContext context) {
    final accessibleColors = _accessibilityService.getAccessibleColors(context);
    
    return {
      'optimism': CoreColorScheme(
        primary: const Color(0xFFFFB74D), // Warm orange
        secondary: const Color(0xFFFFF3E0),
        accent: const Color(0xFFFF8F00),
        text: accessibleColors.onSurface,
        background: accessibleColors.surface,
      ),
      'resilience': CoreColorScheme(
        primary: const Color(0xFF66BB6A), // Strong green
        secondary: const Color(0xFFE8F5E8),
        accent: const Color(0xFF388E3C),
        text: accessibleColors.onSurface,
        background: accessibleColors.surface,
      ),
      'self_awareness': CoreColorScheme(
        primary: const Color(0xFF7986CB), // Thoughtful purple
        secondary: const Color(0xFFE8EAF6),
        accent: const Color(0xFF3F51B5),
        text: accessibleColors.onSurface,
        background: accessibleColors.surface,
      ),
      'creativity': CoreColorScheme(
        primary: const Color(0xFFAB47BC), // Creative magenta
        secondary: const Color(0xFFF3E5F5),
        accent: const Color(0xFF8E24AA),
        text: accessibleColors.onSurface,
        background: accessibleColors.surface,
      ),
      'social_connection': CoreColorScheme(
        primary: const Color(0xFF42A5F5), // Social blue
        secondary: const Color(0xFFE3F2FD),
        accent: const Color(0xFF1976D2),
        text: accessibleColors.onSurface,
        background: accessibleColors.surface,
      ),
      'growth_mindset': CoreColorScheme(
        primary: const Color(0xFF26A69A), // Growth teal
        secondary: const Color(0xFFE0F2F1),
        accent: const Color(0xFF00695C),
        text: accessibleColors.onSurface,
        background: accessibleColors.surface,
      ),
    };
  }

  /// Standardized core iconography
  Map<String, IconData> getCoreIcons() {
    return {
      'optimism': Icons.wb_sunny_rounded,
      'resilience': Icons.shield_rounded,
      'self_awareness': Icons.psychology_rounded,
      'creativity': Icons.palette_rounded,
      'social_connection': Icons.people_rounded,
      'growth_mindset': Icons.trending_up_rounded,
    };
  }

  /// Consistent loading states for core displays
  Widget buildCoreLoadingState(BuildContext context, {
    String? loadingText,
    bool showProgress = true,
  }) {
    final accessibleTextStyles = _accessibilityService.getAccessibleTextStyles(context);
    
    return Semantics(
      label: loadingText ?? 'Loading core data',
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spaceXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress) ...[
                CircularProgressIndicator(
                  semanticsLabel: 'Loading cores data',
                  color: DesignTokens.primaryOrange,
                ),
                SizedBox(height: DesignTokens.spaceL),
              ],
              if (loadingText != null)
                Text(
                  loadingText,
                  style: accessibleTextStyles.bodyMedium?.copyWith(
                    color: DesignTokens.getTextSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Consistent error displays for core components
  Widget buildCoreErrorState(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    IconData? icon,
  }) {
    final accessibleTextStyles = _accessibilityService.getAccessibleTextStyles(context);
    final accessibleColors = _accessibilityService.getAccessibleColors(context);
    
    return Semantics(
      label: '$title. $message',
      hint: onRetry != null ? 'Double tap retry button to try again' : null,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spaceXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon ?? Icons.error_outline_rounded,
                size: 64,
                color: accessibleColors.error,
              ),
              SizedBox(height: DesignTokens.spaceL),
              Text(
                title,
                style: accessibleTextStyles.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accessibleColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignTokens.spaceM),
              Text(
                message,
                style: accessibleTextStyles.bodyMedium?.copyWith(
                  color: DesignTokens.getTextSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                SizedBox(height: DesignTokens.spaceXL),
                Semantics(
                  button: true,
                  label: 'Retry loading core data',
                  hint: 'Double tap to try loading again',
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(
                        _accessibilityService.getMinimumTouchTargetSize() * 2,
                        _accessibilityService.getMinimumTouchTargetSize(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Unified animation timing and easing curves
  AnimationTimingConfig getAnimationTiming() {
    return AnimationTimingConfig(
      // Core transition animations
      coreTransition: _accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 300),
      ),
      
      // Level change animations
      levelChange: _accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 800),
      ),
      
      // Pulse animations for updates
      pulseAnimation: _accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 1200),
      ),
      
      // Milestone celebration
      celebration: _accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 2000),
      ),
      
      // Notification slide-in
      notification: _accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 600),
      ),
      
      // Standard easing curves
      standardCurve: _accessibilityService.getAnimationCurve(Curves.easeInOutCubic),
      elasticCurve: _accessibilityService.getAnimationCurve(Curves.elasticOut),
      bounceCurve: _accessibilityService.getAnimationCurve(Curves.bounceOut),
    );
  }

  /// Consistent spacing and typography following design tokens
  CoreSpacingConfig getSpacingConfig() {
    return CoreSpacingConfig(
      // Card padding
      cardPadding: EdgeInsets.all(DesignTokens.spaceXL),
      
      // Item spacing
      itemSpacing: DesignTokens.spaceL,
      
      // Section spacing
      sectionSpacing: DesignTokens.spaceXXL,
      
      // Accessible spacing
      accessibleSpacing: _accessibilityService.getAccessibleSpacing(),
      
      // Minimum touch targets
      minTouchTarget: _accessibilityService.getMinimumTouchTargetSize(),
    );
  }

  /// Standardized core progress indicators
  Widget buildCoreProgressIndicator(
    BuildContext context, {
    required double progress,
    required Color color,
    required String coreName,
    double size = 60,
    bool showPercentage = true,
    bool animated = true,
  }) {
    final percentage = (progress * 100).round();
    
    return Semantics(
      label: '$coreName core at $percentage percent',
      value: '$percentage percent',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Background circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: _accessibilityService.highContrastMode
                    ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
                    : null,
              ),
            ),
            
            // Progress indicator
            if (animated)
              TweenAnimationBuilder<double>(
                duration: _accessibilityService.getAnimationDuration(
                  const Duration(milliseconds: 800),
                ),
                tween: Tween<double>(begin: 0, end: progress),
                curve: _accessibilityService.getAnimationCurve(Curves.easeInOutCubic),
                builder: (context, animatedProgress, child) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: CoreProgressPainter(
                      progress: animatedProgress,
                      color: color,
                      strokeWidth: _accessibilityService.highContrastMode ? 6 : 4,
                    ),
                  );
                },
              )
            else
              CustomPaint(
                size: Size(size, size),
                painter: CoreProgressPainter(
                  progress: progress,
                  color: color,
                  strokeWidth: _accessibilityService.highContrastMode ? 6 : 4,
                ),
              ),
            
            // Center content
            if (showPercentage)
              Center(
                child: Text(
                  '$percentage%',
                  style: _accessibilityService.getAccessibleTextStyles(context).bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: size * 0.15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Standardized core trend indicators
  Widget buildCoreTrendIndicator(
    BuildContext context, {
    required String trend,
    required Color color,
    double size = 16,
  }) {
    IconData icon;
    String semanticLabel;
    
    switch (trend) {
      case 'rising':
        icon = Icons.trending_up_rounded;
        semanticLabel = 'Rising trend';
        break;
      case 'declining':
        icon = Icons.trending_down_rounded;
        semanticLabel = 'Declining trend';
        break;
      default:
        icon = Icons.trending_flat_rounded;
        semanticLabel = 'Stable trend';
    }
    
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }

  /// Haptic feedback with accessibility consideration
  void provideCoreHapticFeedback(CoreHapticType type) {
    if (_accessibilityService.reducedMotionMode) return;
    
    switch (type) {
      case CoreHapticType.lightImpact:
        // HapticFeedback.lightImpact();
        break;
      case CoreHapticType.mediumImpact:
        // HapticFeedback.mediumImpact();
        break;
      case CoreHapticType.heavyImpact:
        // HapticFeedback.heavyImpact();
        break;
      case CoreHapticType.selection:
        // HapticFeedback.selectionClick();
        break;
    }
  }
}

/// Core color scheme data model
class CoreColorScheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color text;
  final Color background;

  CoreColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.text,
    required this.background,
  });
}

/// Animation timing configuration
class AnimationTimingConfig {
  final Duration coreTransition;
  final Duration levelChange;
  final Duration pulseAnimation;
  final Duration celebration;
  final Duration notification;
  final Curve standardCurve;
  final Curve elasticCurve;
  final Curve bounceCurve;

  AnimationTimingConfig({
    required this.coreTransition,
    required this.levelChange,
    required this.pulseAnimation,
    required this.celebration,
    required this.notification,
    required this.standardCurve,
    required this.elasticCurve,
    required this.bounceCurve,
  });
}

/// Spacing configuration
class CoreSpacingConfig {
  final EdgeInsets cardPadding;
  final double itemSpacing;
  final double sectionSpacing;
  final double accessibleSpacing;
  final double minTouchTarget;

  CoreSpacingConfig({
    required this.cardPadding,
    required this.itemSpacing,
    required this.sectionSpacing,
    required this.accessibleSpacing,
    required this.minTouchTarget,
  });
}

/// Haptic feedback types for core interactions
enum CoreHapticType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selection,
}

/// Custom painter for core progress indicators
class CoreProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CoreProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      const startAngle = -90 * (3.14159 / 180); // Start from top
      final sweepAngle = 2 * 3.14159 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CoreProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
           color != oldDelegate.color ||
           strokeWidth != oldDelegate.strokeWidth;
  }
}