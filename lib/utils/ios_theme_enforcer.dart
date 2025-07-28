import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:spiral_journal/design_system/design_tokens.dart';

/// iOS-specific theme enforcement utility
/// 
/// This class handles iOS-specific UI behaviors, system overlay styling,
/// and ensures proper theme integration with iOS system elements.
class iOSThemeEnforcer {
  static bool _isInitialized = false;
  
  /// Check if the current platform is iOS
  static bool get isiOS => Platform.isIOS;
  
  /// Initialize iOS-specific system UI configuration
  /// 
  /// Call this during app initialization to set up proper iOS system UI
  /// overlay styles and ensure consistent theme behavior.
  static void initialize() {
    if (!isiOS || _isInitialized) return;
    
    try {
      // Set iOS-specific system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light, // Light status bar background
          statusBarIconBrightness: Brightness.dark, // Dark status bar icons
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      
      // Ensure system chrome is visible
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('iOS Theme Enforcer initialization failed: $e');
    }
  }
  
  /// Enforce iOS theme styling for the given widget
  /// 
  /// Wraps the child widget with iOS-specific system UI overlay style
  /// annotations to ensure proper integration with iOS system elements.
  static Widget enforceTheme(BuildContext context, Widget child) {
    if (!isiOS) return child;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Force iOS to respect our theme
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Theme(
        data: _getiOSEnforcedTheme(context),
        child: child,
      ),
    );
  }
  
  /// Create iOS-specific safe area handling for screens
  /// 
  /// Returns a SafeArea widget configured appropriately for iOS devices,
  /// with special handling for different iPhone models and their safe areas.
  static Widget withSafeArea({
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    if (!isiOS) return child;
    
    return SafeArea(
      top: top,
      bottom: bottom, // Always apply bottom safe area on iOS for home indicator
      left: left,
      right: right,
      child: child,
    );
  }
  
  /// Handle iOS keyboard dismissal behavior
  /// 
  /// Wraps the child with a GestureDetector that dismisses the keyboard
  /// when tapping outside of text input fields, following iOS conventions.
  static Widget withKeyboardDismissal({
    required BuildContext context,
    required Widget child,
  }) {
    if (!isiOS) return child;
    
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside text fields
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      child: child,
    );
  }
  
  /// Get iOS-enforced theme data
  static ThemeData _getiOSEnforcedTheme(BuildContext context) {
    final baseTheme = Theme.of(context);
    final isDark = baseTheme.brightness == Brightness.dark;
    
    // Create iOS-specific theme overrides
    return baseTheme.copyWith(
      // Ensure proper color scheme application
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
        onPrimary: isDark ? DesignTokens.darkBackgroundPrimary : Colors.white,
        secondary: isDark ? DesignTokens.darkPrimaryLight : DesignTokens.primaryLight,
        surface: isDark ? DesignTokens.darkBackgroundSecondary : DesignTokens.backgroundSecondary,
        onSurface: isDark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
      ),
      
      // Force proper app bar theme
      appBarTheme: baseTheme.appBarTheme.copyWith(
        systemOverlayStyle: isDark 
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: DesignTokens.darkBackgroundPrimary,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: DesignTokens.backgroundPrimary,
            ),
      ),
      
      // Ensure proper scaffold background
      scaffoldBackgroundColor: isDark 
        ? DesignTokens.darkBackgroundPrimary 
        : DesignTokens.backgroundPrimary,
      
      // Force proper text theme application
      textTheme: _getiOSTextTheme(context, baseTheme.textTheme, isDark),
      
      // Ensure proper button themes
      elevatedButtonTheme: _getiOSElevatedButtonTheme(context, isDark),
      textButtonTheme: _getiOSTextButtonTheme(context, isDark),
      outlinedButtonTheme: _getiOSOutlinedButtonTheme(context, isDark),
      
      // Force proper input decoration
      inputDecorationTheme: _getiOSInputDecorationTheme(context, isDark),
      
      // Ensure proper card theme
      cardTheme: _getiOSCardTheme(context, isDark),
      
      // Force proper bottom navigation theme
      bottomNavigationBarTheme: _getiOSBottomNavigationTheme(context, isDark),
    );
  }
  
  /// Get iOS-specific text theme
  static TextTheme _getiOSTextTheme(BuildContext context, TextTheme baseTheme, bool isDark) {
    return baseTheme.copyWith(
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        color: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
        fontFamily: DesignTokens.fontFamily,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
        fontFamily: DesignTokens.fontFamily,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        color: isDark ? DesignTokens.darkPrimaryDark : DesignTokens.primaryDark,
        fontFamily: DesignTokens.fontFamily,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary,
        fontFamily: DesignTokens.fontFamily,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary,
        fontFamily: DesignTokens.fontFamily,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        color: isDark ? DesignTokens.darkTextTertiary : DesignTokens.textTertiary,
        fontFamily: DesignTokens.fontFamily,
      ),
    );
  }
  
  /// Get iOS-specific elevated button theme
  static ElevatedButtonThemeData _getiOSElevatedButtonTheme(BuildContext context, bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
        foregroundColor: isDark ? DesignTokens.darkBackgroundPrimary : Colors.white,
        textStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.getiPhoneAdaptiveFontSize(context, base: DesignTokens.fontSizeL),
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: isDark ? DesignTokens.darkBackgroundPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        padding: DesignTokens.buttonPaddingHorizontal,
        elevation: DesignTokens.elevationS,
        minimumSize: Size(
          0,
          DesignTokens.getiPhoneAdaptiveSpacing(context, base: DesignTokens.buttonHeight),
        ),
      ),
    );
  }
  
  /// Get iOS-specific text button theme
  static TextButtonThemeData _getiOSTextButtonTheme(BuildContext context, bool isDark) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
        textStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.getiPhoneAdaptiveFontSize(context, base: DesignTokens.fontSizeL),
          fontWeight: DesignTokens.fontWeightMedium,
          color: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
        ),
        minimumSize: Size(
          0,
          DesignTokens.getiPhoneAdaptiveSpacing(context, base: DesignTokens.buttonHeight),
        ),
      ),
    );
  }
  
  /// Get iOS-specific outlined button theme
  static OutlinedButtonThemeData _getiOSOutlinedButtonTheme(BuildContext context, bool isDark) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
        side: BorderSide(
          color: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
          width: 1.5,
        ),
        textStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.getiPhoneAdaptiveFontSize(context, base: DesignTokens.fontSizeL),
          fontWeight: DesignTokens.fontWeightMedium,
          color: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        minimumSize: Size(
          0,
          DesignTokens.getiPhoneAdaptiveSpacing(context, base: DesignTokens.buttonHeight),
        ),
      ),
    );
  }
  
  /// Get iOS-specific input decoration theme
  static InputDecorationTheme _getiOSInputDecorationTheme(BuildContext context, bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? DesignTokens.darkBackgroundTertiary : DesignTokens.backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        borderSide: BorderSide(
          color: isDark ? DesignTokens.darkSurface : DesignTokens.backgroundTertiary,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        borderSide: BorderSide(
          color: isDark ? DesignTokens.darkSurface : DesignTokens.backgroundTertiary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        borderSide: BorderSide(
          color: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
          width: DesignTokens.inputFocusedBorderWidth,
        ),
      ),
      contentPadding: DesignTokens.inputContentPadding,
      hintStyle: DesignTokens.getTextStyle(
        fontSize: DesignTokens.getiPhoneAdaptiveFontSize(context, base: DesignTokens.fontSizeM),
        fontWeight: DesignTokens.fontWeightRegular,
        color: isDark ? DesignTokens.darkTextTertiary : DesignTokens.textTertiary,
      ),
      labelStyle: DesignTokens.getTextStyle(
        fontSize: DesignTokens.getiPhoneAdaptiveFontSize(context, base: DesignTokens.fontSizeM),
        fontWeight: DesignTokens.fontWeightRegular,
        color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary,
      ),
    );
  }
  
  /// Get iOS-specific card theme
  static CardThemeData _getiOSCardTheme(BuildContext context, bool isDark) {
    return CardThemeData(
      color: isDark ? DesignTokens.darkBackgroundSecondary : DesignTokens.backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: DesignTokens.cardElevation,
      shadowColor: DesignTokens.getColorWithOpacity(Colors.black, isDark ? 0.3 : 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        side: BorderSide(
          color: isDark ? DesignTokens.darkBackgroundTertiary : DesignTokens.backgroundTertiary,
          width: 1.0,
        ),
      ),
      margin: EdgeInsets.all(
        DesignTokens.getiPhoneAdaptiveSpacing(context, base: DesignTokens.spaceS),
      ),
    );
  }
  
  /// Get iOS-specific bottom navigation theme
  static BottomNavigationBarThemeData _getiOSBottomNavigationTheme(BuildContext context, bool isDark) {
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? DesignTokens.darkBackgroundPrimary : DesignTokens.backgroundPrimary,
      selectedItemColor: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
      unselectedItemColor: isDark ? DesignTokens.darkTextTertiary : DesignTokens.textTertiary,
      elevation: DesignTokens.bottomNavElevation,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: DesignTokens.getTextStyle(
        fontSize: DesignTokens.getiPhoneAdaptiveFontSize(context, base: DesignTokens.fontSizeS),
        fontWeight: DesignTokens.fontWeightMedium,
        color: isDark ? DesignTokens.darkPrimaryOrange : DesignTokens.primaryOrange,
      ),
      unselectedLabelStyle: DesignTokens.getTextStyle(
        fontSize: DesignTokens.getiPhoneAdaptiveFontSize(context, base: DesignTokens.fontSizeS),
        fontWeight: DesignTokens.fontWeightRegular,
        color: isDark ? DesignTokens.darkTextTertiary : DesignTokens.textTertiary,
      ),
    );
  }
  
  /// Update system UI overlay based on current theme
  static void updateSystemUIOverlay(BuildContext context) {
    if (!Platform.isIOS) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: isDark 
          ? DesignTokens.darkBackgroundPrimary 
          : DesignTokens.backgroundPrimary,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
  
  /// Force rebuild of theme-dependent widgets on iOS
  static void forceThemeRebuild(BuildContext context) {
    if (!Platform.isIOS) return;
    
    // Update system UI overlay
    updateSystemUIOverlay(context);
    
    // Force a rebuild by updating the system UI overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateSystemUIOverlay(context);
    });
  }
  
  /// Check if iOS theme enforcement is needed
  static bool needsEnforcement() {
    return Platform.isIOS;
  }
  
  /// Get iOS-safe colors that work properly on iOS devices
  static Color getiOSSafeColor(Color color, BuildContext context) {
    if (!Platform.isIOS) return color;
    
    // Ensure color has proper alpha channel for iOS
    return color.withValues(alpha: color.alpha.toDouble());
  }
  
  /// Apply iOS-specific font rendering fixes
  static TextStyle getiOSSafeTextStyle(TextStyle style) {
    if (!Platform.isIOS) return style;
    
    // Ensure proper font rendering on iOS
    return style.copyWith(
      fontFamily: style.fontFamily ?? DesignTokens.fontFamily,
      // Force proper text rendering on iOS
      decoration: style.decoration ?? TextDecoration.none,
    );
  }
}

/// Extension to easily apply iOS theme enforcement to widgets
extension iOSThemeEnforcementExtension on Widget {
  /// Wrap this widget with iOS theme enforcement
  Widget withiOSThemeEnforcement(BuildContext context) {
    return iOSThemeEnforcer.enforceTheme(context, this);
  }
}
