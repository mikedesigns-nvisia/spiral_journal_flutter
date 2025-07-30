import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';

/// Unified theme system that uses DesignTokens as the single source of truth
/// and provides Flutter ThemeData configurations for the app.
/// 
/// This class serves as a bridge between the comprehensive DesignTokens system
/// and Flutter's ThemeData, ensuring consistency across the entire application
/// including AI-generated content.
class AppTheme {
  
  /// Light theme configuration using DesignTokens
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Removed global fontFamily to allow text styles to use their own fonts
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignTokens.primaryOrange,
        brightness: Brightness.light,
        primary: DesignTokens.primaryOrange,
        onPrimary: Colors.white,
        secondary: DesignTokens.primaryLight,
        onSecondary: DesignTokens.textPrimary,
        surface: DesignTokens.backgroundPrimary,
        onSurface: DesignTokens.textPrimary,
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.backgroundPrimary,
        foregroundColor: DesignTokens.primaryOrange,
        elevation: DesignTokens.appBarElevation,
        centerTitle: false,
        titleTextStyle: DesignTokens.getTextStyle(
          fontSize: 18.0,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.primaryOrange,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: DesignTokens.backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.cardElevation,
        shadowColor: DesignTokens.getColorWithOpacity(Colors.black, 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          side: BorderSide(
            color: DesignTokens.backgroundTertiary, 
            width: ComponentTokens.cardBorderWidth,
          ),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DesignTokens.backgroundPrimary,
        selectedItemColor: DesignTokens.primaryOrange,
        unselectedItemColor: DesignTokens.textTertiary,
        elevation: DesignTokens.bottomNavElevation,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeS,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.primaryOrange,
        ),
        unselectedLabelStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeS,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.textTertiary,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.backgroundTertiary,
        selectedColor: DesignTokens.moodEnergetic,
        labelStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
        ),
        showCheckmark: false,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryOrange,
          foregroundColor: Colors.white,
          textStyle: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          padding: DesignTokens.buttonPaddingHorizontal,
          elevation: DesignTokens.elevationS,
        ),
      ),
      
      // Text Theme - Using serif headings and Noto Sans JP body
      textTheme: DesignTokens.textTheme(isDark: false),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(color: DesignTokens.backgroundTertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(color: DesignTokens.backgroundTertiary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(
            color: DesignTokens.primaryOrange, 
            width: DesignTokens.inputFocusedBorderWidth,
          ),
        ),
        contentPadding: DesignTokens.inputContentPadding,
        hintStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.textTertiary,
        ),
      ),
    );
  }

  /// Dark theme configuration using DesignTokens
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      // Removed global fontFamily to allow text styles to use their own fonts
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignTokens.darkPrimaryOrange,
        brightness: Brightness.dark,
        primary: DesignTokens.darkPrimaryOrange,
        onPrimary: DesignTokens.darkBackgroundPrimary,
        secondary: DesignTokens.darkPrimaryLight,
        onSecondary: DesignTokens.darkTextPrimary,
        surface: DesignTokens.darkBackgroundSecondary,
        onSurface: DesignTokens.darkTextPrimary,
        background: DesignTokens.darkBackgroundPrimary,
        onBackground: DesignTokens.darkTextPrimary,
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.darkBackgroundPrimary,
        foregroundColor: DesignTokens.darkPrimaryOrange,
        elevation: DesignTokens.appBarElevation,
        centerTitle: false,
        titleTextStyle: DesignTokens.getTextStyle(
          fontSize: 18.0,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.darkPrimaryOrange,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: DesignTokens.darkBackgroundSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: DesignTokens.elevationS,
        shadowColor: DesignTokens.getColorWithOpacity(Colors.black, 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          side: BorderSide(
            color: const Color(0xFF404040), // Subtle border for dark mode contrast
            width: ComponentTokens.cardBorderWidth,
          ),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DesignTokens.darkBackgroundPrimary,
        selectedItemColor: DesignTokens.darkPrimaryOrange,
        unselectedItemColor: DesignTokens.darkTextTertiary,
        elevation: DesignTokens.bottomNavElevation,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeS,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.darkPrimaryOrange,
        ),
        unselectedLabelStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeS,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.darkTextTertiary,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.darkBackgroundTertiary,
        selectedColor: DesignTokens.moodEnergetic,
        labelStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
        ),
        showCheckmark: false,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.darkPrimaryOrange,
          foregroundColor: DesignTokens.darkBackgroundPrimary,
          textStyle: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.darkBackgroundPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
          padding: DesignTokens.buttonPaddingHorizontal,
          elevation: DesignTokens.elevationS,
        ),
      ),
      
      // Text Theme - Using serif headings and Noto Sans JP body
      textTheme: DesignTokens.textTheme(isDark: true),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.darkBackgroundTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(
            color: const Color(0xFF505050), // Better contrast for input borders
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(
            color: const Color(0xFF505050), // Better contrast for input borders
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide(
            color: DesignTokens.darkPrimaryOrange, 
            width: DesignTokens.inputFocusedBorderWidth,
          ),
        ),
        contentPadding: DesignTokens.inputContentPadding,
        hintStyle: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.darkTextTertiary,
        ),
      ),
    );
  }

  // ============================================================================
  // THEME-AWARE GRADIENT HELPERS
  // ============================================================================
  
  /// Get theme-aware primary gradient for backgrounds
  static LinearGradient getPrimaryGradient(BuildContext context) {
    return DesignTokens.getPrimaryGradient(context);
  }
  
  /// Get theme-aware card gradient
  static LinearGradient getCardGradient(BuildContext context) {
    return DesignTokens.getCardGradient(context);
  }

  // ============================================================================
  // CONVENIENCE METHODS FOR COMMON THEME OPERATIONS
  // ============================================================================
  
  /// Get theme-aware primary color
  static Color getPrimaryColor(BuildContext context) {
    return DesignTokens.getPrimaryColor(context);
  }
  
  /// Get theme-aware background colors
  static Color getBackgroundPrimary(BuildContext context) {
    return DesignTokens.getBackgroundPrimary(context);
  }
  
  static Color getBackgroundSecondary(BuildContext context) {
    return DesignTokens.getBackgroundSecondary(context);
  }
  
  /// Get theme-aware text colors
  static Color getTextPrimary(BuildContext context) {
    return DesignTokens.getTextPrimary(context);
  }
  
  static Color getTextSecondary(BuildContext context) {
    return DesignTokens.getTextSecondary(context);
  }
  
  static Color getTextTertiary(BuildContext context) {
    return DesignTokens.getTextTertiary(context);
  }
  
  /// Get mood color (theme-agnostic)
  static Color getMoodColor(String mood) {
    return DesignTokens.getMoodColor(mood);
  }
  
  /// Get core color (theme-agnostic)
  static Color getCoreColor(String coreType) {
    return DesignTokens.getCoreColor(coreType);
  }
  
  /// Apply opacity to color
  static Color getColorWithOpacity(Color color, double opacity) {
    return DesignTokens.getColorWithOpacity(color, opacity);
  }

  // ============================================================================
  // BACKWARD COMPATIBILITY PROPERTIES AND METHODS
  // ============================================================================
  
  /// Legacy color properties for backward compatibility
  static Color get primaryOrange => DesignTokens.primaryOrange;
  static Color get primaryLight => DesignTokens.primaryLight;
  static Color get primaryDark => DesignTokens.primaryDark;
  static Color get backgroundPrimary => DesignTokens.backgroundPrimary;
  static Color get backgroundSecondary => DesignTokens.backgroundSecondary;
  static Color get backgroundTertiary => DesignTokens.backgroundTertiary;
  static Color get textPrimary => DesignTokens.textPrimary;
  static Color get textSecondary => DesignTokens.textSecondary;
  static Color get textTertiary => DesignTokens.textTertiary;
  
  /// Dark theme color properties
  static Color get darkPrimaryOrange => DesignTokens.darkPrimaryOrange;
  static Color get darkPrimaryLight => DesignTokens.darkPrimaryLight;
  static Color get darkPrimaryDark => DesignTokens.darkPrimaryDark;
  static Color get darkBackgroundPrimary => DesignTokens.darkBackgroundPrimary;
  static Color get darkBackgroundSecondary => DesignTokens.darkBackgroundSecondary;
  static Color get darkBackgroundTertiary => DesignTokens.darkBackgroundTertiary;
  static Color get darkTextPrimary => DesignTokens.darkTextPrimary;
  static Color get darkTextSecondary => DesignTokens.darkTextSecondary;
  static Color get darkTextTertiary => DesignTokens.darkTextTertiary;
  
  /// Accent colors
  static Color get accentYellow => DesignTokens.accentYellow;
  static Color get accentGreen => DesignTokens.accentGreen;
  static Color get accentRed => DesignTokens.accentRed;
  static Color get accentOrange => DesignTokens.warningColor;
  
  /// Status colors
  static Color get warningColor => DesignTokens.warningColor;
  static Color get successColor => DesignTokens.successColor;
  static Color get errorColor => DesignTokens.errorColor;
  static Color get infoColor => DesignTokens.infoColor;
  
  /// Mood colors
  static Color get moodHappy => DesignTokens.moodHappy;
  static Color get moodContent => DesignTokens.moodContent;
  static Color get moodUnsure => DesignTokens.moodUnsure;
  static Color get moodSad => DesignTokens.moodSad;
  static Color get moodEnergetic => DesignTokens.moodEnergetic;
  
  /// Legacy method for getting text styles
  static TextStyle getTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    TextDecoration? decoration,
  }) {
    return DesignTokens.getTextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }
  
  /// Legacy method for getting border color
  static Color getBorderColor(BuildContext context) {
    return DesignTokens.getBackgroundTertiary(context);
  }
}
