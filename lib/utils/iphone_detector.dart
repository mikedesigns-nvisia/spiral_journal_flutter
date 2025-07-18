import 'package:flutter/material.dart';
import 'dart:io';

/// iPhone size categories for responsive design
enum iPhoneSize {
  /// iPhone SE (1st, 2nd, 3rd gen) - 375x667
  compact,
  /// iPhone 12/13/14/15 Mini - 375x812
  mini,
  /// iPhone 12/13/14/15 - 390x844
  regular,
  /// iPhone 12/13/14/15 Plus - 428x926
  plus,
  /// iPhone 14/15 Pro Max - 430x932
  proMax,
  /// Non-iPhone or unknown
  unknown,
}

/// iPhone model detection and responsive utilities
class iPhoneDetector {
  /// Get the current iPhone size category based on screen dimensions
  static iPhoneSize getCurrentiPhoneSize(BuildContext context) {
    if (!Platform.isIOS) return iPhoneSize.unknown;
    
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    
    // Use the smaller dimension as width for consistency
    final screenWidth = width < height ? width : height;
    final screenHeight = width < height ? height : width;
    
    // iPhone size detection based on logical pixels
    if (screenWidth <= 375) {
      if (screenHeight <= 667) {
        return iPhoneSize.compact; // iPhone SE
      } else {
        return iPhoneSize.mini; // iPhone 12/13/14/15 Mini
      }
    } else if (screenWidth <= 390) {
      return iPhoneSize.regular; // iPhone 12/13/14/15
    } else if (screenWidth <= 428) {
      return iPhoneSize.plus; // iPhone 12/13/14/15 Plus
    } else if (screenWidth <= 430) {
      return iPhoneSize.proMax; // iPhone 14/15 Pro Max
    }
    
    return iPhoneSize.unknown;
  }
  
  /// Check if the current device is a compact iPhone (SE or Mini)
  static bool isCompactiPhone(BuildContext context) {
    final size = getCurrentiPhoneSize(context);
    return size == iPhoneSize.compact || size == iPhoneSize.mini;
  }
  
  /// Check if the current device is a large iPhone (Plus or Pro Max)
  static bool isLargeiPhone(BuildContext context) {
    final size = getCurrentiPhoneSize(context);
    return size == iPhoneSize.plus || size == iPhoneSize.proMax;
  }
  
  /// Check if the current device has a notch or Dynamic Island
  static bool hasNotchOrDynamicIsland(BuildContext context) {
    if (!Platform.isIOS) return false;
    
    final padding = MediaQuery.of(context).padding;
    return padding.top > 20; // Standard status bar is 20pt
  }
  
  /// Check if the current device has a home indicator (no home button)
  static bool hasHomeIndicator(BuildContext context) {
    if (!Platform.isIOS) return false;
    
    final padding = MediaQuery.of(context).padding;
    return padding.bottom > 0;
  }
  
  /// Get safe area insets for iPhone-specific layouts
  static EdgeInsets getSafeAreaInsets(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// Get adaptive padding based on iPhone size
  static EdgeInsets getAdaptivePadding(BuildContext context, {
    double? compact,
    double? regular,
    double? large,
  }) {
    final size = getCurrentiPhoneSize(context);
    double padding;
    
    switch (size) {
      case iPhoneSize.compact:
      case iPhoneSize.mini:
        padding = compact ?? 12.0;
        break;
      case iPhoneSize.plus:
      case iPhoneSize.proMax:
        padding = large ?? 20.0;
        break;
      case iPhoneSize.regular:
      default:
        padding = regular ?? 16.0;
        break;
    }
    
    return EdgeInsets.all(padding);
  }
  
  /// Get adaptive horizontal padding based on iPhone size
  static EdgeInsets getAdaptiveHorizontalPadding(BuildContext context, {
    double? compact,
    double? regular,
    double? large,
  }) {
    final size = getCurrentiPhoneSize(context);
    double padding;
    
    switch (size) {
      case iPhoneSize.compact:
      case iPhoneSize.mini:
        padding = compact ?? 12.0;
        break;
      case iPhoneSize.plus:
      case iPhoneSize.proMax:
        padding = large ?? 24.0;
        break;
      case iPhoneSize.regular:
      default:
        padding = regular ?? 16.0;
        break;
    }
    
    return EdgeInsets.symmetric(horizontal: padding);
  }
  
  /// Get adaptive font size based on iPhone size
  static double getAdaptiveFontSize(BuildContext context, {
    required double base,
    double? compactScale,
    double? largeScale,
  }) {
    final size = getCurrentiPhoneSize(context);
    
    switch (size) {
      case iPhoneSize.compact:
      case iPhoneSize.mini:
        return base * (compactScale ?? 0.9);
      case iPhoneSize.plus:
      case iPhoneSize.proMax:
        return base * (largeScale ?? 1.1);
      case iPhoneSize.regular:
      default:
        return base;
    }
  }
  
  /// Get adaptive icon size based on iPhone size
  static double getAdaptiveIconSize(BuildContext context, {
    required double base,
    double? compactScale,
    double? largeScale,
  }) {
    final size = getCurrentiPhoneSize(context);
    
    switch (size) {
      case iPhoneSize.compact:
      case iPhoneSize.mini:
        return base * (compactScale ?? 0.9);
      case iPhoneSize.plus:
      case iPhoneSize.proMax:
        return base * (largeScale ?? 1.2);
      case iPhoneSize.regular:
      default:
        return base;
    }
  }
  
  /// Get adaptive button height based on iPhone size
  static double getAdaptiveButtonHeight(BuildContext context, {
    required double base,
    double? compactHeight,
    double? largeHeight,
  }) {
    final size = getCurrentiPhoneSize(context);
    
    switch (size) {
      case iPhoneSize.compact:
      case iPhoneSize.mini:
        return compactHeight ?? (base * 0.9);
      case iPhoneSize.plus:
      case iPhoneSize.proMax:
        return largeHeight ?? (base * 1.1);
      case iPhoneSize.regular:
      default:
        return base;
    }
  }
  
  /// Get adaptive spacing based on iPhone size
  static double getAdaptiveSpacing(BuildContext context, {
    required double base,
    double? compactScale,
    double? largeScale,
  }) {
    final size = getCurrentiPhoneSize(context);
    
    switch (size) {
      case iPhoneSize.compact:
      case iPhoneSize.mini:
        return base * (compactScale ?? 0.8);
      case iPhoneSize.plus:
      case iPhoneSize.proMax:
        return base * (largeScale ?? 1.2);
      case iPhoneSize.regular:
      default:
        return base;
    }
  }
  
  /// Get the number of columns for grid layouts based on iPhone size
  static int getAdaptiveColumns(BuildContext context, {
    int? compact,
    int? regular,
    int? large,
  }) {
    final size = getCurrentiPhoneSize(context);
    
    switch (size) {
      case iPhoneSize.compact:
      case iPhoneSize.mini:
        return compact ?? 1;
      case iPhoneSize.plus:
      case iPhoneSize.proMax:
        return large ?? 3;
      case iPhoneSize.regular:
      default:
        return regular ?? 2;
    }
  }
  
  /// Get adaptive bottom navigation height based on iPhone size and safe area
  static double getAdaptiveBottomNavHeight(BuildContext context) {
    final safeArea = getSafeAreaInsets(context);
    final baseHeight = getAdaptiveButtonHeight(context, base: 60.0);
    
    // Add extra padding for devices with home indicator
    return baseHeight + safeArea.bottom;
  }
  
  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return viewInsets.bottom > 0;
  }
  
  /// Get adaptive keyboard padding
  static double getKeyboardPadding(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return viewInsets.bottom;
  }
  
  /// Get device info string for debugging
  static String getDeviceInfo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final iPhoneSize = getCurrentiPhoneSize(context);
    final safeArea = getSafeAreaInsets(context);
    
    return '''
Device Size: ${size.width.toStringAsFixed(1)} x ${size.height.toStringAsFixed(1)}
iPhone Size: $iPhoneSize
Has Notch/Dynamic Island: ${hasNotchOrDynamicIsland(context)}
Has Home Indicator: ${hasHomeIndicator(context)}
Safe Area: ${safeArea.toString()}
''';
  }
}
