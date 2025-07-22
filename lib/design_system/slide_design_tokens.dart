import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';

/// Design tokens specifically for slide components and interactions
class SlideDesignTokens {
  SlideDesignTokens._();

  // Slide Transition Durations
  static const Duration transitionDurationFast = Duration(milliseconds: 200);
  static const Duration transitionDurationNormal = Duration(milliseconds: 250);
  static const Duration transitionDurationSlow = Duration(milliseconds: 350);
  static const Duration transitionDurationBoundary = Duration(milliseconds: 150);

  // Slide Transition Curves
  static const Curve transitionCurveSlide = Curves.easeOutCubic;
  static const Curve transitionCurveJump = Curves.easeInOutCubic;
  static const Curve transitionCurveBounce = Curves.elasticOut;
  static const Curve transitionCurveSpring = Curves.fastLinearToSlowEaseIn;

  // Slide Indicator Sizes
  static const double indicatorSizeSmall = 6.0;
  static const double indicatorSizeNormal = 8.0;
  static const double indicatorSizeLarge = 10.0;
  static const double indicatorSpacing = 8.0;
  static const double indicatorBorderRadius = 4.0;

  // Slide Indicator Animation
  static const Duration indicatorAnimationDuration = Duration(milliseconds: 200);
  static const Curve indicatorAnimationCurve = Curves.easeInOut;
  static const double indicatorActiveScale = 1.2;
  static const double indicatorInactiveOpacity = 0.4;

  // Slide Content Padding
  static const EdgeInsets slideContentPaddingCompact = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 8.0,
  );
  static const EdgeInsets slideContentPaddingNormal = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  static const EdgeInsets slideContentPaddingLarge = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );
  static const EdgeInsets slideContentPaddingTablet = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 20.0,
  );

  // Slide Header Spacing
  static const double slideHeaderSpacingSmall = 8.0;
  static const double slideHeaderSpacingNormal = 12.0;
  static const double slideHeaderSpacingLarge = 16.0;

  // Slide Navigation Heights
  static const double slideNavigationHeightCompact = 44.0;
  static const double slideNavigationHeightNormal = 56.0;
  static const double slideNavigationHeightLarge = 64.0;

  // Slide Loading Animation
  static const Duration loadingAnimationDuration = Duration(milliseconds: 1200);
  static const Curve loadingAnimationCurve = Curves.easeInOut;
  static const double loadingIndicatorSize = 24.0;

  // Slide Error State
  static const double errorIconSize = 48.0;
  static const EdgeInsets errorPadding = EdgeInsets.all(24.0);
  static const double errorSpacing = 16.0;

  // Slide Haptic Feedback Intensities (using void functions instead of types)
  static void hapticSuccess() => HapticFeedback.lightImpact();
  static void hapticBoundary() => HapticFeedback.mediumImpact();
  static void hapticError() => HapticFeedback.heavyImpact();

  // Slide Shadow and Elevation
  static const double slideShadowBlurRadius = 8.0;
  static const double slideShadowSpreadRadius = 0.0;
  static const Offset slideShadowOffset = Offset(0, 2);
  static const double slideElevation = 2.0;

  // Slide Border Radius
  static const double slideBorderRadiusSmall = 8.0;
  static const double slideBorderRadiusNormal = 12.0;
  static const double slideBorderRadiusLarge = 16.0;

  /// Get slide transition duration based on navigation type
  static Duration getTransitionDuration(SlideTransitionType type) {
    switch (type) {
      case SlideTransitionType.next:
      case SlideTransitionType.previous:
        return transitionDurationNormal;
      case SlideTransitionType.jump:
        return transitionDurationSlow;
      case SlideTransitionType.boundary:
        return transitionDurationBoundary;
      case SlideTransitionType.fast:
        return transitionDurationFast;
    }
  }

  /// Get slide transition curve based on navigation type
  static Curve getTransitionCurve(SlideTransitionType type) {
    switch (type) {
      case SlideTransitionType.next:
      case SlideTransitionType.previous:
        return transitionCurveSlide;
      case SlideTransitionType.jump:
        return transitionCurveJump;
      case SlideTransitionType.boundary:
        return transitionCurveBounce;
      case SlideTransitionType.fast:
        return transitionCurveSpring;
    }
  }

  /// Get slide indicator size based on device type
  static double getIndicatorSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 375) {
      return indicatorSizeSmall;
    } else if (screenWidth > 414) {
      return indicatorSizeLarge;
    }
    return indicatorSizeNormal;
  }

  /// Get slide content padding based on device type
  static EdgeInsets getSlideContentPadding(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final isCompact = screenSize.width < 375;

    if (isTablet) {
      return slideContentPaddingTablet;
    } else if (isCompact) {
      return slideContentPaddingCompact;
    } else if (screenSize.width > 414) {
      return slideContentPaddingLarge;
    }
    return slideContentPaddingNormal;
  }

  /// Get slide header spacing based on device type
  static double getSlideHeaderSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 375) {
      return slideHeaderSpacingSmall;
    } else if (screenWidth > 414) {
      return slideHeaderSpacingLarge;
    }
    return slideHeaderSpacingNormal;
  }

  /// Get slide navigation height based on device type
  static double getSlideNavigationHeight(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 375;
    final isLarge = screenSize.width > 414;

    if (isCompact) {
      return slideNavigationHeightCompact;
    } else if (isLarge) {
      return slideNavigationHeightLarge;
    }
    return slideNavigationHeightNormal;
  }

  /// Get slide border radius based on device type
  static double getSlideBorderRadius(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final isCompact = screenSize.width < 375;

    if (isTablet) {
      return slideBorderRadiusLarge;
    } else if (isCompact) {
      return slideBorderRadiusSmall;
    }
    return slideBorderRadiusNormal;
  }

  /// Get slide colors based on theme and state
  static SlideColorScheme getSlideColors(BuildContext context, {
    bool isActive = false,
    bool isError = false,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isError) {
      return SlideColorScheme(
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
        accent: theme.colorScheme.error,
        indicator: theme.colorScheme.error,
        shadow: theme.colorScheme.error.withOpacity(0.2),
      );
    }

    if (isLoading) {
      return SlideColorScheme(
        background: theme.colorScheme.surface,
        foreground: theme.colorScheme.onSurface.withOpacity(0.6),
        accent: theme.colorScheme.primary.withOpacity(0.6),
        indicator: theme.colorScheme.primary.withOpacity(0.4),
        shadow: theme.colorScheme.shadow.withOpacity(0.1),
      );
    }

    if (isActive) {
      return SlideColorScheme(
        background: theme.colorScheme.primaryContainer,
        foreground: theme.colorScheme.onPrimaryContainer,
        accent: theme.colorScheme.primary,
        indicator: theme.colorScheme.primary,
        shadow: theme.colorScheme.primary.withOpacity(0.2),
      );
    }

    return SlideColorScheme(
      background: theme.colorScheme.surface,
      foreground: theme.colorScheme.onSurface,
      accent: theme.colorScheme.secondary,
      indicator: theme.colorScheme.outline,
      shadow: theme.colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.1),
    );
  }

  /// Get slide typography based on context
  static SlideTypography getSlideTypography(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SlideTypography(
      title: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      
      subtitle: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
      ) ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      
      body: textTheme.bodyMedium?.copyWith(
        height: 1.5,
        letterSpacing: 0.25,
      ) ?? const TextStyle(fontSize: 14, height: 1.5),
      
      caption: textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ) ?? const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      
      button: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ) ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  /// Get slide animation configuration
  static SlideAnimationConfig getAnimationConfig(SlideTransitionType type) {
    return SlideAnimationConfig(
      duration: getTransitionDuration(type),
      curve: getTransitionCurve(type),
      hapticFeedback: type == SlideTransitionType.boundary 
          ? hapticBoundary 
          : hapticSuccess,
    );
  }
}

/// Enumeration of slide transition types
enum SlideTransitionType {
  next,
  previous,
  jump,
  boundary,
  fast,
}

/// Color scheme for slide components
class SlideColorScheme {
  final Color background;
  final Color foreground;
  final Color accent;
  final Color indicator;
  final Color shadow;

  const SlideColorScheme({
    required this.background,
    required this.foreground,
    required this.accent,
    required this.indicator,
    required this.shadow,
  });
}

/// Typography configuration for slide components
class SlideTypography {
  final TextStyle title;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle button;

  const SlideTypography({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.caption,
    required this.button,
  });
}

/// Animation configuration for slide transitions
class SlideAnimationConfig {
  final Duration duration;
  final Curve curve;
  final VoidCallback hapticFeedback;

  const SlideAnimationConfig({
    required this.duration,
    required this.curve,
    required this.hapticFeedback,
  });
}
