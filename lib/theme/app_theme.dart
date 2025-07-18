import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

class AppTheme {
  // Light Theme Colors
  // Primary Colors - Warm oranges and browns
  static const Color primaryOrange = Color(0xFF865219);
  static const Color primaryLight = Color(0xFFFDB876);
  static const Color primaryDark = Color(0xFF6A3B01);
  
  // Background Colors - Warm creams
  static const Color backgroundPrimary = Color(0xFFFFF8F5);
  static const Color backgroundSecondary = Color(0xFFFAEBE0);
  static const Color backgroundTertiary = Color(0xFFF2DFD1);
  
  // Text Colors - Light theme
  static const Color textPrimary = Color(0xFF211A14);
  static const Color textSecondary = Color(0xFF51443A);
  static const Color textTertiary = Color(0xFF837469);
  
  // Dark Theme Colors
  // Primary Colors - Muted oranges for dark theme
  static const Color darkPrimaryOrange = Color(0xFFB8763A);
  static const Color darkPrimaryLight = Color(0xFF8B5A2B);
  static const Color darkPrimaryDark = Color(0xFFD4A574);
  
  // Background Colors - Dark grays
  static const Color darkBackgroundPrimary = Color(0xFF121212);
  static const Color darkBackgroundSecondary = Color(0xFF1E1E1E);
  static const Color darkBackgroundTertiary = Color(0xFF2C2C2C);
  static const Color darkSurface = Color(0xFF383838);
  
  // Text Colors - Dark theme
  static const Color darkTextPrimary = Color(0xFFE8E3E0);
  static const Color darkTextSecondary = Color(0xFFB8B3B0);
  static const Color darkTextTertiary = Color(0xFF8A8580);
  
  // Mood Colors (work for both themes)
  static const Color moodHappy = Color(0xFFE78B1B);
  static const Color moodContent = Color(0xFF7AACB3);
  static const Color moodUnsure = Color(0xFF8B7ED8);
  static const Color moodSad = Color(0xFFBA1A1A);
  static const Color moodEnergetic = Color(0xFFEA8100);
  
  // Core Colors - Gradients for different core types (work for both themes)
  static const Color coreOptimist = Color(0xFFAFCACD);
  static const Color coreReflective = Color(0xFFEBA751);
  static const Color coreCreative = Color(0xFFA198DD);
  static const Color coreSocial = Color(0xFFB1CDAF);
  static const Color coreRest = Color(0xFFB37A9B);
  
  // Accent Colors
  static const Color accentYellow = Color(0xFFFFDCBF);
  static const Color accentGreen = Color(0xFF4C662B);
  static const Color accentRed = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.notoSansJp().fontFamily,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        brightness: Brightness.light,
        primary: primaryOrange,
        onPrimary: Colors.white,
        secondary: primaryLight,
        onSecondary: textPrimary,
        surface: backgroundPrimary,
        onSurface: textPrimary,
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundPrimary,
        foregroundColor: primaryOrange,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansJp(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryOrange,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: backgroundTertiary, width: 1),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundPrimary,
        selectedItemColor: primaryOrange,
        unselectedItemColor: textTertiary,
        elevation: 1,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: backgroundTertiary,
        selectedColor: moodEnergetic,
        labelStyle: GoogleFonts.notoSansJp(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.notoSansJp(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryOrange,
        ),
        headlineMedium: GoogleFonts.notoSansJp(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.notoSansJp(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: primaryDark,
        ),
        bodyLarge: GoogleFonts.notoSansJp(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodyMedium: GoogleFonts.notoSansJp(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textTertiary,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: backgroundTertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: backgroundTertiary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: GoogleFonts.notoSansJp(
          fontSize: 14,
          color: textTertiary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.notoSansJp().fontFamily,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimaryOrange,
        brightness: Brightness.dark,
        primary: darkPrimaryOrange,
        onPrimary: darkBackgroundPrimary,
        secondary: darkPrimaryLight,
        onSecondary: darkTextPrimary,
        surface: darkBackgroundSecondary,
        onSurface: darkTextPrimary,
        background: darkBackgroundPrimary,
        onBackground: darkTextPrimary,
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackgroundPrimary,
        foregroundColor: darkPrimaryOrange,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansJp(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkPrimaryOrange,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: darkBackgroundSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkBackgroundTertiary, width: 1),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkBackgroundPrimary,
        selectedItemColor: darkPrimaryOrange,
        unselectedItemColor: darkTextTertiary,
        elevation: 1,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: darkBackgroundTertiary,
        selectedColor: moodEnergetic,
        labelStyle: GoogleFonts.notoSansJp(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryOrange,
          foregroundColor: darkBackgroundPrimary,
          textStyle: GoogleFonts.notoSansJp(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.notoSansJp(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkPrimaryOrange,
        ),
        headlineMedium: GoogleFonts.notoSansJp(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        headlineSmall: GoogleFonts.notoSansJp(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: darkPrimaryDark,
        ),
        bodyLarge: GoogleFonts.notoSansJp(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
        ),
        bodyMedium: GoogleFonts.notoSansJp(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
        ),
        bodySmall: GoogleFonts.notoSansJp(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkTextTertiary,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackgroundTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkSurface),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkSurface),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkPrimaryOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: GoogleFonts.notoSansJp(
          fontSize: 14,
          color: darkTextTertiary,
        ),
      ),
    );
  }

  // Helper method to get mood color
  static Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return moodHappy;
      case 'content':
        return moodContent;
      case 'unsure':
        return moodUnsure;
      case 'sad':
        return moodSad;
      case 'energetic':
        return moodEnergetic;
      default:
        return primaryOrange;
    }
  }
  
  // Helper method to get core color
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
  
  // Theme Helper Methods
  
  /// Creates a consistent text style with font fallback for iOS compatibility
  static TextStyle getTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    try {
      return GoogleFonts.notoSansJp(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } catch (e) {
      // Fallback to system font if Google Fonts fails
      debugPrint('Google Fonts failed, using system font: $e');
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontFamily: _getFallbackFontFamily(),
      );
    }
  }
  
  /// Get platform-appropriate fallback font family
  static String _getFallbackFontFamily() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return '.SF UI Text'; // iOS system font
      case TargetPlatform.android:
        return 'Roboto'; // Android system font
      case TargetPlatform.macOS:
        return '.SF NS Text'; // macOS system font
      default:
        return 'system-ui'; // Web/Desktop fallback
    }
  }
  
  /// Applies opacity to a color consistently
  static Color getColorWithOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Builds consistent BottomNavigationBarTheme
  static BottomNavigationBarThemeData buildBottomNavTheme() {
    return BottomNavigationBarThemeData(
      backgroundColor: backgroundPrimary,
      selectedItemColor: primaryOrange,
      unselectedItemColor: textTertiary,
      elevation: 1,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: getTextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: primaryOrange,
      ),
      unselectedLabelStyle: getTextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textTertiary,
      ),
    );
  }
  
  /// Builds consistent CardTheme
  static CardThemeData buildCardTheme() {
    return CardThemeData(
      color: backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: getColorWithOpacity(Colors.black, 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: backgroundTertiary, width: 1),
      ),
    );
  }
  
  /// Builds consistent InputDecorationTheme
  static InputDecorationTheme buildInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: backgroundTertiary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: backgroundTertiary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryOrange, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
      hintStyle: getTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textTertiary,
      ),
    );
  }

  // Theme-aware helper methods
  
  /// Get primary color based on theme brightness
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkPrimaryOrange 
        : primaryOrange;
  }
  
  /// Get background primary color based on theme brightness
  static Color getBackgroundPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackgroundPrimary 
        : backgroundPrimary;
  }
  
  /// Get background secondary color based on theme brightness
  static Color getBackgroundSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackgroundSecondary 
        : backgroundSecondary;
  }
  
  /// Get text primary color based on theme brightness
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextPrimary 
        : textPrimary;
  }
  
  /// Get text secondary color based on theme brightness
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextSecondary 
        : textSecondary;
  }
  
  /// Get text tertiary color based on theme brightness
  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkTextTertiary 
        : textTertiary;
  }
  
  /// Builds theme-aware BottomNavigationBarTheme
  static BottomNavigationBarThemeData buildBottomNavThemeForBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? darkBackgroundPrimary : backgroundPrimary,
      selectedItemColor: isDark ? darkPrimaryOrange : primaryOrange,
      unselectedItemColor: isDark ? darkTextTertiary : textTertiary,
      elevation: 1,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: getTextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? darkPrimaryOrange : primaryOrange,
      ),
      unselectedLabelStyle: getTextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: isDark ? darkTextTertiary : textTertiary,
      ),
    );
  }
  
  /// Builds theme-aware CardTheme
  static CardThemeData buildCardThemeForBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return CardThemeData(
      color: isDark ? darkBackgroundSecondary : backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      elevation: isDark ? 2 : 1,
      shadowColor: getColorWithOpacity(Colors.black, isDark ? 0.3 : 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? darkBackgroundTertiary : backgroundTertiary, 
          width: 1
        ),
      ),
    );
  }
  
  /// Builds theme-aware InputDecorationTheme
  static InputDecorationTheme buildInputThemeForBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? darkBackgroundTertiary : backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? darkSurface : backgroundTertiary
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? darkSurface : backgroundTertiary
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? darkPrimaryOrange : primaryOrange, 
          width: 2
        ),
      ),
      contentPadding: const EdgeInsets.all(16),
      hintStyle: getTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? darkTextTertiary : textTertiary,
      ),
    );
  }

  // Gradient helpers
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFDCBF), Color(0xFFFFF8F5)],
  );
  
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFEFD90), Color(0xFFFFF8F5)],
  );
  
  // Dark theme gradients
  static LinearGradient get darkPrimaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
  );
  
  static LinearGradient get darkCardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF383838), Color(0xFF2C2C2C)],
  );
  
  /// Get theme-aware gradient
  static LinearGradient getPrimaryGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkPrimaryGradient 
        : primaryGradient;
  }
  
  /// Get theme-aware card gradient
  static LinearGradient getCardGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkCardGradient 
        : cardGradient;
  }
}
