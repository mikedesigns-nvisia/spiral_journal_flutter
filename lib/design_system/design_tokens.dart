import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive design system for Spiral Journal
/// This file centralizes all design tokens, components, and patterns
/// used throughout the application for consistency and maintainability.
class DesignTokens {
  // ============================================================================
  // COLOR SYSTEM
  // ============================================================================
  
  /// Primary brand colors - warm oranges and browns
  static const Color primaryOrange = Color(0xFF865219);
  static const Color primaryLight = Color(0xFFFDB876);
  static const Color primaryDark = Color(0xFF6A3B01);
  
  /// Light theme background colors - warm creams
  static const Color backgroundPrimary = Color(0xFFFFF8F5);
  static const Color backgroundSecondary = Color(0xFFFAEBE0);
  static const Color backgroundTertiary = Color(0xFFF2DFD1);
  
  /// Light theme text colors
  static const Color textPrimary = Color(0xFF211A14);
  static const Color textSecondary = Color(0xFF51443A);
  static const Color textTertiary = Color(0xFF837469);
  
  /// Dark theme primary colors - muted oranges
  static const Color darkPrimaryOrange = Color(0xFFB8763A);
  static const Color darkPrimaryLight = Color(0xFF8B5A2B);
  static const Color darkPrimaryDark = Color(0xFFD4A574);
  
  /// Dark theme background colors
  static const Color darkBackgroundPrimary = Color(0xFF121212);
  static const Color darkBackgroundSecondary = Color(0xFF1E1E1E);
  static const Color darkBackgroundTertiary = Color(0xFF2C2C2C);
  static const Color darkSurface = Color(0xFF383838);
  
  /// Dark theme text colors
  static const Color darkTextPrimary = Color(0xFFE8E3E0);
  static const Color darkTextSecondary = Color(0xFFB8B3B0);
  static const Color darkTextTertiary = Color(0xFFD8D3D0);
  
  /// Semantic mood colors (theme-agnostic)
  static const Color moodHappy = Color(0xFFE78B1B);
  static const Color moodContent = Color(0xFF7AACB3);
  static const Color moodUnsure = Color(0xFF8B7ED8);
  static const Color moodSad = Color(0xFFBA1A1A);
  static const Color moodEnergetic = Color(0xFFEA8100);
  
  /// Core personality colors (theme-agnostic)
  static const Color coreOptimist = Color(0xFFAFCACD);
  static const Color coreReflective = Color(0xFFEBA751);
  static const Color coreCreative = Color(0xFFA198DD);
  static const Color coreSocial = Color(0xFFB1CDAF);
  static const Color coreRest = Color(0xFFB37A9B);
  
  /// Accent and utility colors
  static const Color accentYellow = Color(0xFFFFDCBF);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentGreen = Color(0xFF4C662B);
  static const Color accentRed = Color(0xFFBA1A1A);
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color accentCyan = Color(0xFF00BCD4);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentBrown = Color(0xFF795548);
  
  /// Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color infoColor = Color(0xFF2196F3);
  
  // ============================================================================
  // AI CONTENT COLORS
  // ============================================================================
  
  /// AI-generated content colors (theme-agnostic)
  static const Color aiInsightPrimary = Color(0xFF6366F1); // Indigo for AI insights
  static const Color aiInsightSecondary = Color(0xFF8B5CF6); // Purple for AI analysis
  static const Color aiSuggestionColor = Color(0xFF10B981); // Emerald for suggestions
  static const Color aiWarningColor = Color(0xFFF59E0B); // Amber for AI warnings
  static const Color aiHighlightColor = Color(0xFFEC4899); // Pink for AI highlights
  
  /// AI content background colors
  static const Color aiContentBackground = Color(0xFFF8FAFC); // Light blue-gray
  static const Color aiContentBorder = Color(0xFFE2E8F0); // Slate border
  static const Color darkAiContentBackground = Color(0xFF1E293B); // Dark slate
  static const Color darkAiContentBorder = Color(0xFF334155); // Dark slate border
  
  // ============================================================================
  // TYPOGRAPHY SYSTEM
  // ============================================================================
  
  /// Font family with Google Fonts primary, local cached as fallback
  static String get fontFamily {
    try {
      // Try Google Fonts first (will use cached local fonts if available)
      return GoogleFonts.notoSansJp().fontFamily ?? 'NotoSansJP';
    } catch (e) {
      debugPrint('Google Fonts failed, using cached local font: $e');
      // Fallback to bundled local font (cached on install)
      return 'NotoSansJP';
    }
  }
  
  /// Platform-specific fallback fonts
  static String _getFallbackFontFamily() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return '.SF UI Text';
      case TargetPlatform.android:
        return 'Roboto';
      case TargetPlatform.macOS:
        return '.SF NS Text';
      default:
        return 'system-ui';
    }
  }
  
  /// Typography scale
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 20.0;
  static const double fontSizeXXXL = 24.0;
  static const double fontSizeDisplay = 32.0;
  
  /// Font weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  
  /// Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
  
  // ============================================================================
  // SPACING SYSTEM - GOLDEN RATIO BASED
  // ============================================================================
  
  /// Golden ratio constant (φ ≈ 1.618)
  static const double goldenRatio = 1.618;
  
  /// Spacing scale based on 4px base unit with golden ratio progression
  /// Optimized for iPhone 12/13/14/15 (390px width) - the most common iPhone
  static const double spaceXXS = 2.0;   // 4 ÷ φ² ≈ 1.5 → 2px
  static const double spaceXS = 3.0;    // 4 ÷ φ ≈ 2.5 → 3px
  static const double spaceS = 4.0;     // Base unit (4px)
  static const double spaceM = 6.0;     // 4 × φ ≈ 6.5 → 6px
  static const double spaceL = 10.0;    // 4 × φ² ≈ 10.5 → 10px
  static const double spaceXL = 16.0;   // 4 × φ³ ≈ 17 → 16px
  static const double spaceXXL = 26.0;  // 4 × φ⁴ ≈ 27.5 → 26px
  static const double spaceXXXL = 42.0; // 4 × φ⁵ ≈ 44.5 → 42px
  static const double spaceHuge = 68.0; // 4 × φ⁶ ≈ 72 → 68px
  
  /// Component-specific spacing using golden ratio scale
  static const double cardPadding = spaceXL;      // 16px - optimal for cards
  static const double screenPadding = spaceXL;    // 16px - optimal for screen edges
  static const double buttonPadding = spaceL;     // 10px - optimal for button padding
  static const double inputPadding = spaceXL;     // 16px - optimal for input fields
  
  // ============================================================================
  // BORDER RADIUS SYSTEM - GOLDEN RATIO BASED
  // ============================================================================
  
  /// Border radius following golden ratio progression
  static const double radiusXXS = 2.0;   // 4 ÷ φ² ≈ 1.5 → 2px
  static const double radiusXS = 3.0;    // 4 ÷ φ ≈ 2.5 → 3px
  static const double radiusS = 4.0;     // Base unit
  static const double radiusM = 6.0;     // 4 × φ ≈ 6.5 → 6px
  static const double radiusL = 10.0;    // 4 × φ² ≈ 10.5 → 10px
  static const double radiusXL = 16.0;   // 4 × φ³ ≈ 17 → 16px
  static const double radiusXXL = 26.0;  // 4 × φ⁴ ≈ 27.5 → 26px
  static const double radiusRound = 50.0; // Maintained for circular elements
  
  /// Component-specific radius using golden ratio
  static const double cardRadius = radiusL;      // 10px - optimal for cards
  static const double buttonRadius = radiusM;    // 6px - optimal for buttons
  static const double inputRadius = radiusM;     // 6px - optimal for inputs
  static const double chipRadius = radiusXL;     // 16px - optimal for chips
  
  // ============================================================================
  // ELEVATION SYSTEM
  // ============================================================================
  
  static const double elevationNone = 0.0;
  static const double elevationXS = 1.0;
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 12.0;
  static const double elevationXXL = 16.0;
  
  /// Component-specific elevations
  static const double cardElevation = elevationXS;
  static const double modalElevation = elevationL;
  static const double appBarElevation = elevationNone;
  static const double bottomNavElevation = elevationXS;
  
  // ============================================================================
  // ANIMATION SYSTEM
  // ============================================================================
  
  /// Animation durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationSlower = Duration(milliseconds: 800);
  
  /// Animation curves
  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveDecelerate = Curves.easeOut;
  static const Curve curveAccelerate = Curves.easeIn;
  static const Curve curveBounce = Curves.elasticOut;
  static const Curve curveSpring = Curves.easeOutBack;
  
  // ============================================================================
  // COMPONENT TOKENS
  // ============================================================================
  
  /// Button specifications
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 56.0;
  static const EdgeInsets buttonPaddingHorizontal = EdgeInsets.symmetric(horizontal: spaceXXL);
  static const EdgeInsets buttonPaddingVertical = EdgeInsets.symmetric(vertical: spaceM);
  
  /// Input field specifications
  static const double inputHeight = 48.0;
  static const double inputHeightMultiline = 120.0;
  static const EdgeInsets inputContentPadding = EdgeInsets.all(inputPadding);
  static const double inputBorderWidth = 1.0;
  static const double inputFocusedBorderWidth = 2.0;
  
  /// Card specifications
  static const EdgeInsets cardMargin = EdgeInsets.all(spaceS);
  static const EdgeInsets cardPaddingDefault = EdgeInsets.all(cardPadding);
  static const double cardBorderWidth = 1.0;
  
  /// Chip specifications
  static const double chipHeight = 32.0;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: spaceM, vertical: spaceXS);
  static const EdgeInsets chipLabelPadding = EdgeInsets.symmetric(horizontal: spaceS);
  
  /// Loading indicator specifications
  static const double loadingIndicatorSize = 40.0;
  static const double loadingIndicatorSizeSmall = 20.0;
  static const double loadingIndicatorSizeLarge = 60.0;
  static const double loadingStrokeWidth = 3.0;
  
  /// Icon specifications - golden ratio based
  static const double iconSizeXXS = 6.0;   // 4 × φ ≈ 6.5 → 6px
  static const double iconSizeXS = 10.0;   // 4 × φ² ≈ 10.5 → 10px
  static const double iconSizeS = 16.0;    // 4 × φ³ ≈ 17 → 16px
  static const double iconSizeM = 20.0;    // Adjusted for usability
  static const double iconSizeL = 24.0;    // Adjusted for usability
  static const double iconSizeXL = 32.0;   // Maintained for larger icons
  static const double iconSizeXXL = 48.0;  // Maintained for largest icons
  
  // ============================================================================
  // LAYOUT TOKENS
  // ============================================================================
  
  /// Breakpoints for responsive design
  static const double breakpointMobile = 480.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;
  
  /// iPhone-specific breakpoints
  static const double breakpointiPhoneSE = 375.0;      // iPhone SE (1st, 2nd, 3rd gen)
  static const double breakpointiPhoneMini = 375.0;    // iPhone 12/13/14/15 Mini
  static const double breakpointiPhoneRegular = 390.0; // iPhone 12/13/14/15
  static const double breakpointiPhonePlus = 428.0;    // iPhone 12/13/14/15 Plus
  static const double breakpointiPhoneProMax = 430.0;  // iPhone 14/15 Pro Max
  
  /// Container constraints
  static const double maxContentWidth = 600.0;
  static const double minTouchTarget = 44.0;
  
  /// iPhone-specific touch targets
  static const double iPhoneMinTouchTarget = 44.0;     // Apple HIG minimum
  static const double iPhonePreferredTouchTarget = 48.0; // Preferred size
  static const double iPhoneCompactTouchTarget = 40.0;  // For compact layouts
  
  /// Grid system
  static const int gridColumns = 12;
  static const double gridGutter = spaceL;
  
  /// iPhone-specific grid columns
  static const int iPhoneCompactColumns = 1;
  static const int iPhoneRegularColumns = 2;
  static const int iPhoneLargeColumns = 3;
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get theme-aware colors
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkPrimaryOrange 
        : primaryOrange;
  }
  
  static Color getBackgroundPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackgroundPrimary 
        : backgroundPrimary;
  }
  
  static Color getBackgroundSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackgroundSecondary 
        : backgroundSecondary;
  }
  
  static Color getBackgroundTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackgroundTertiary 
        : backgroundTertiary;
  }
  
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextPrimary 
        : textPrimary;
  }
  
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextSecondary 
        : textSecondary;
  }
  
  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextTertiary 
        : textTertiary;
  }
  
  /// Get error color (theme-agnostic)
  static Color getErrorColor(BuildContext context) {
    return errorColor;
  }
  
  /// Get mood color by name
  static Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      // Positive moods - warm, bright colors
      case 'happy':
      case 'joyful':
        return moodHappy;
      case 'content':
      case 'peaceful':
      case 'calm':
        return moodContent;
      case 'energetic':
      case 'excited':
        return moodEnergetic;
      case 'grateful':
      case 'loving':
        return const Color(0xFFE91E63); // Pink
      case 'confident':
      case 'proud':
        return const Color(0xFF9C27B0); // Purple
      case 'motivated':
      case 'determined':
        return const Color(0xFF3F51B5); // Indigo
      case 'creative':
      case 'inspired':
        return const Color(0xFF673AB7); // Deep Purple
      case 'social':
      case 'compassionate':
        return const Color(0xFF009688); // Teal
      case 'optimistic':
      case 'hopeful':
        return const Color(0xFFFF9800); // Orange
      case 'focused':
      case 'accomplished':
        return const Color(0xFF4CAF50); // Green
      case 'playful':
      case 'curious':
        return const Color(0xFFFFEB3B); // Yellow
      case 'relaxed':
        return const Color(0xFF00BCD4); // Cyan
      case 'adventurous':
        return const Color(0xFFFF5722); // Deep Orange
      
      // Neutral moods - muted colors
      case 'reflective':
        return const Color(0xFF607D8B); // Blue Grey
      case 'unsure':
      case 'confused':
        return moodUnsure;
      case 'restless':
        return const Color(0xFF795548); // Brown
      
      // Challenging moods - cooler, darker colors
      case 'sad':
      case 'melancholy':
        return moodSad;
      case 'tired':
        return const Color(0xFF9E9E9E); // Grey
      case 'stressed':
      case 'overwhelmed':
        return const Color(0xFFFF5252); // Red Accent
      case 'anxious':
      case 'worried':
        return const Color(0xFFFF7043); // Deep Orange Light
      case 'frustrated':
      case 'angry':
        return const Color(0xFFF44336); // Red
      case 'lonely':
        return const Color(0xFF5C6BC0); // Indigo Light
      case 'disappointed':
        return const Color(0xFF8BC34A); // Light Green (muted)
      
      default:
        return primaryOrange;
    }
  }
  
  /// Get core personality color by type
  static Color getCoreColor(String coreType) {
    switch (coreType.toLowerCase()) {
      case 'optimist':
        return coreOptimist;
      case 'reflective':
        return coreReflective;
      case 'creative':
        return coreCreative;
      case 'social':
        return coreSocial;
      case 'rest':
        return coreRest;
      default:
        return primaryLight;
    }
  }
  
  /// Get status color by type
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return successColor;
      case 'warning':
        return warningColor;
      case 'error':
        return errorColor;
      case 'info':
        return infoColor;
      default:
        return primaryOrange;
    }
  }
  
  /// Get AI content color by type
  static Color getAiContentColor(String type) {
    switch (type.toLowerCase()) {
      case 'insight':
      case 'analysis':
        return aiInsightPrimary;
      case 'reflection':
      case 'pattern':
        return aiInsightSecondary;
      case 'suggestion':
      case 'recommendation':
        return aiSuggestionColor;
      case 'warning':
      case 'concern':
        return aiWarningColor;
      case 'highlight':
      case 'important':
        return aiHighlightColor;
      default:
        return aiInsightPrimary;
    }
  }
  
  /// Get theme-aware AI content background
  static Color getAiContentBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkAiContentBackground 
        : aiContentBackground;
  }
  
  /// Get theme-aware AI content border
  static Color getAiContentBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkAiContentBorder 
        : aiContentBorder;
  }
  
  /// Apply opacity to color consistently
  static Color getColorWithOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }
  
  /// Create consistent text style
  static TextStyle getTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    TextDecoration? decoration,
  }) {
    try {
      return GoogleFonts.notoSansJp(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    } catch (e) {
      debugPrint('Google Fonts failed in getTextStyle, using cached local font: $e');
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
        fontFamily: 'NotoSansJP', // Use cached local font as fallback
      );
    }
  }

  /// Create Lora serif text style for headings
  static TextStyle getSerifTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    try {
      return GoogleFonts.lora(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );
    } catch (e) {
      debugPrint('Google Fonts failed in getSerifTextStyle, using serif fallback: $e');
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
        fontFamily: 'serif', // Use serif fallback
      );
    }
  }

  /// Complete text theme with serif headings and Noto Sans JP body
  static TextTheme textTheme({required bool isDark}) {
    final baseColor = isDark ? darkTextPrimary : textPrimary;
    
    return TextTheme(
      // Display styles - NOW USING SERIF (Lora)
      displayLarge: getSerifTextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: baseColor,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: getSerifTextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.16,
      ),
      displaySmall: getSerifTextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.22,
      ),
      
      // Headlines - NOW USING SERIF (Lora)
      headlineLarge: getSerifTextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.25,
      ),
      headlineMedium: getSerifTextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.29,
      ),
      headlineSmall: getSerifTextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.33,
      ),
      
      // Title styles - KEEP NOTO SANS JP
      titleLarge: getTextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.27,
      ),
      titleMedium: getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.5,
      ),
      titleSmall: getTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.43,
      ),
      
      // Body text - KEEP NOTO SANS JP
      bodyLarge: getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.5,
      ),
      bodyMedium: getTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.43,
      ),
      bodySmall: getTextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: baseColor,
        height: 1.33,
      ),
      
      // Labels - KEEP NOTO SANS JP
      labelLarge: getTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.43,
      ),
      labelMedium: getTextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.33,
      ),
      labelSmall: getTextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: baseColor,
        height: 1.45,
      ),
    );
  }
  
  /// Responsive value based on screen width
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= breakpointDesktop && desktop != null) {
      return desktop;
    } else if (width >= breakpointTablet && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }
  
  /// iPhone-specific responsive value based on device size
  static T getiPhoneResponsiveValue<T>(
    BuildContext context, {
    required T compact,
    T? regular,
    T? large,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= breakpointiPhonePlus && large != null) {
      return large;
    } else if (width >= breakpointiPhoneRegular && regular != null) {
      return regular;
    } else {
      return compact;
    }
  }
  
  /// Get iPhone-specific spacing based on device size
  static double getiPhoneAdaptiveSpacing(
    BuildContext context, {
    required double base,
    double compactScale = 0.8,
    double largeScale = 1.2,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= breakpointiPhonePlus) {
      return base * largeScale;
    } else if (width <= breakpointiPhoneMini) {
      return base * compactScale;
    } else {
      return base;
    }
  }
  
  /// Get iPhone-specific font size based on device size
  static double getiPhoneAdaptiveFontSize(
    BuildContext context, {
    required double base,
    double compactScale = 0.9,
    double largeScale = 1.1,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= breakpointiPhonePlus) {
      return base * largeScale;
    } else if (width <= breakpointiPhoneMini) {
      return base * compactScale;
    } else {
      return base;
    }
  }
  
  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointTablet;
  }
  
  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointTablet && width < breakpointDesktop;
  }
  
  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointDesktop;
  }
  
  /// Check if device is compact iPhone (SE or Mini)
  static bool isCompactiPhone(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width <= breakpointiPhoneMini;
  }
  
  /// Check if device is regular iPhone
  static bool isRegulariPhone(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > breakpointiPhoneMini && width < breakpointiPhonePlus;
  }
  
  /// Check if device is large iPhone (Plus or Pro Max)
  static bool isLargeiPhone(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointiPhonePlus;
  }
  
  /// Get safe area aware padding for iPhone layouts
  static EdgeInsets getSafeAreaPadding(BuildContext context, {
    EdgeInsets? fallback,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final safeArea = mediaQuery.padding;
    final defaultPadding = fallback ?? EdgeInsets.all(spaceL);
    
    return EdgeInsets.only(
      top: defaultPadding.top + safeArea.top,
      bottom: defaultPadding.bottom + safeArea.bottom,
      left: defaultPadding.left + safeArea.left,
      right: defaultPadding.right + safeArea.right,
    );
  }
  
  // ============================================================================
  // GRADIENT DEFINITIONS
  // ============================================================================
  
  /// Primary gradients for light theme
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF8F5), // backgroundPrimary
      Color(0xFFFAEBE0), // backgroundSecondary
      Color(0xFFF2DFD1), // backgroundTertiary
    ],
    stops: [0.0, 0.6, 1.0],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8F5), // backgroundPrimary
      Color(0xFFFAEBE0), // backgroundSecondary
    ],
    stops: [0.0, 1.0],
  );
  
  /// Subtle accent gradient for light theme
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFDCBF), // accentYellow
      Color(0xFFFFF8F5), // backgroundPrimary
    ],
    stops: [0.0, 1.0],
  );
  
  /// Dark theme gradients
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF121212), // darkBackgroundPrimary
      Color(0xFF1E1E1E), // darkBackgroundSecondary
      Color(0xFF2C2C2C), // darkBackgroundTertiary
    ],
    stops: [0.0, 0.6, 1.0],
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1E1E), // darkBackgroundSecondary
      Color(0xFF2C2C2C), // darkBackgroundTertiary
    ],
    stops: [0.0, 1.0],
  );
  
  /// Subtle accent gradient for dark theme
  static const LinearGradient darkAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2C2C2C), // darkBackgroundTertiary
      Color(0xFF383838), // darkSurface
    ],
    stops: [0.0, 1.0],
  );
  
  /// Get theme-aware gradient
  static LinearGradient getPrimaryGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkPrimaryGradient 
        : primaryGradient;
  }
  
  static LinearGradient getCardGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkCardGradient 
        : cardGradient;
  }
  
  // ============================================================================
  // SHADOW DEFINITIONS
  // ============================================================================
  
  /// Shadow presets
  static List<BoxShadow> get shadowXS => [
    BoxShadow(
      color: getColorWithOpacity(Colors.black, 0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];
  
  static List<BoxShadow> get shadowS => [
    BoxShadow(
      color: getColorWithOpacity(Colors.black, 0.1),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];
  
  static List<BoxShadow> get shadowM => [
    BoxShadow(
      color: getColorWithOpacity(Colors.black, 0.15),
      offset: const Offset(0, 4),
      blurRadius: 8,
    ),
  ];
  
  static List<BoxShadow> get shadowL => [
    BoxShadow(
      color: getColorWithOpacity(Colors.black, 0.2),
      offset: const Offset(0, 8),
      blurRadius: 16,
    ),
  ];
  
  /// Theme-aware shadows
  static List<BoxShadow> getShadow(BuildContext context, String size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opacity = isDark ? 0.3 : 0.1;
    
    switch (size) {
      case 'xs':
        return [BoxShadow(
          color: getColorWithOpacity(Colors.black, opacity * 0.5),
          offset: const Offset(0, 1),
          blurRadius: 2,
        )];
      case 's':
        return [BoxShadow(
          color: getColorWithOpacity(Colors.black, opacity),
          offset: const Offset(0, 2),
          blurRadius: 4,
        )];
      case 'm':
        return [BoxShadow(
          color: getColorWithOpacity(Colors.black, opacity * 1.5),
          offset: const Offset(0, 4),
          blurRadius: 8,
        )];
      case 'l':
        return [BoxShadow(
          color: getColorWithOpacity(Colors.black, opacity * 2),
          offset: const Offset(0, 8),
          blurRadius: 16,
        )];
      default:
        return shadowS;
    }
  }
}

/// Component-specific design tokens
class ComponentTokens {
  // ============================================================================
  // MOOD SELECTOR TOKENS
  // ============================================================================
  
  static const EdgeInsets moodSelectorPadding = EdgeInsets.all(DesignTokens.cardPadding);
  static const double moodSelectorSpacing = DesignTokens.spaceS;
  static const double moodSelectorRunSpacing = DesignTokens.spaceS;
  static const double moodChipHeight = 32.0;
  static const EdgeInsets moodChipPadding = EdgeInsets.symmetric(
    horizontal: DesignTokens.spaceM, 
    vertical: DesignTokens.spaceXS,
  );
  
  // ============================================================================
  // LOADING WIDGET TOKENS
  // ============================================================================
  
  static const double loadingMessageSpacing = DesignTokens.spaceL;
  static const double loadingProgressSpacing = DesignTokens.spaceM;
  static const double loadingProgressTextSpacing = DesignTokens.spaceS;
  
  // ============================================================================
  // ERROR DISPLAY TOKENS
  // ============================================================================
  
  static const EdgeInsets errorDisplayMargin = EdgeInsets.all(DesignTokens.spaceL);
  static const EdgeInsets errorDisplayPadding = EdgeInsets.all(DesignTokens.spaceL);
  static const double errorIconSize = DesignTokens.iconSizeL;
  static const double errorIconSpacing = DesignTokens.spaceM;
  static const double errorContentSpacing = DesignTokens.spaceS;
  static const double errorActionsSpacing = DesignTokens.spaceL;
  static const double errorActionSpacing = DesignTokens.spaceS;
  
  // ============================================================================
  // CARD TOKENS
  // ============================================================================
  
  static const EdgeInsets cardDefaultMargin = EdgeInsets.all(DesignTokens.spaceS);
  static const EdgeInsets cardDefaultPadding = EdgeInsets.all(DesignTokens.cardPadding);
  static const double cardDefaultRadius = DesignTokens.cardRadius;
  static const double cardDefaultElevation = DesignTokens.cardElevation;
  static const double cardBorderWidth = 1.0;
  
  // ============================================================================
  // ANIMATION TOKENS
  // ============================================================================
  
  static const Duration staggerDelay = Duration(milliseconds: 100);
  static const Duration slideAnimationDuration = Duration(milliseconds: 600);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 300);
  static const Duration scaleAnimationDuration = Duration(milliseconds: 400);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 1000);
  
  // ============================================================================
  // CHART TOKENS
  // ============================================================================
  
  static const double chartHeight = 200.0;
  static const double chartPadding = DesignTokens.spaceL;
  static const double chartLegendSpacing = DesignTokens.spaceM;
  static const double chartAxisLabelSize = DesignTokens.fontSizeS;
  static const double chartTitleSize = DesignTokens.fontSizeL;
  
  // ============================================================================
  // NAVIGATION TOKENS
  // ============================================================================
  
  static const double bottomNavHeight = 60.0;
  static const double bottomNavIconSize = DesignTokens.iconSizeL;
  static const double bottomNavLabelSize = DesignTokens.fontSizeS;
  static const EdgeInsets bottomNavPadding = EdgeInsets.symmetric(
    horizontal: DesignTokens.spaceS,
    vertical: DesignTokens.spaceXS,
  );
  
  // ============================================================================
  // FORM TOKENS
  // ============================================================================
  
  static const double formFieldSpacing = DesignTokens.spaceL;
  static const double formSectionSpacing = DesignTokens.spaceXXL;
  static const EdgeInsets formPadding = EdgeInsets.all(DesignTokens.screenPadding);
  static const double formLabelSpacing = DesignTokens.spaceS;
  static const double formHelperSpacing = DesignTokens.spaceXS;
}

/// Accessibility tokens
class AccessibilityTokens {
  static const double minTouchTarget = 44.0;
  static const double preferredTouchTarget = 48.0;
  static const double minTextSize = 12.0;
  static const double preferredTextSize = 16.0;
  static const double minContrastRatio = 4.5;
  static const double preferredContrastRatio = 7.0;
  
  /// Focus indicators
  static const double focusIndicatorWidth = 2.0;
  static const Color focusIndicatorColor = DesignTokens.primaryOrange;
  static const double focusIndicatorRadius = DesignTokens.radiusS;
  
  /// Screen reader labels
  static const String semanticButtonLabel = 'Button';
  static const String semanticLinkLabel = 'Link';
  static const String semanticImageLabel = 'Image';
  static const String semanticInputLabel = 'Text input';
}
