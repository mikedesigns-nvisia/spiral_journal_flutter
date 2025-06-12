import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors - Warm oranges and browns
  static const Color primaryOrange = Color(0xFF865219);
  static const Color primaryLight = Color(0xFFFDB876);
  static const Color primaryDark = Color(0xFF6A3B01);
  
  // Background Colors - Warm creams
  static const Color backgroundPrimary = Color(0xFFFFF8F5);
  static const Color backgroundSecondary = Color(0xFFFAEBE0);
  static const Color backgroundTertiary = Color(0xFFF2DFD1);
  
  // Mood Colors
  static const Color moodHappy = Color(0xFFE78B1B);
  static const Color moodContent = Color(0xFF7AACB3);
  static const Color moodUnsure = Color(0xFF8B7ED8);
  static const Color moodSad = Color(0xFFBA1A1A);
  static const Color moodEnergetic = Color(0xFFEA8100);
  
  // Core Colors - Gradients for different core types
  static const Color coreOptimist = Color(0xFFAFCACD);
  static const Color coreReflective = Color(0xFFEBA751);
  static const Color coreCreative = Color(0xFFA198DD);
  static const Color coreSocial = Color(0xFFB1CDAF);
  static const Color coreRest = Color(0xFFB37A9B);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF211A14);
  static const Color textSecondary = Color(0xFF51443A);
  static const Color textTertiary = Color(0xFF837469);
  
  // Accent Colors
  static const Color accentYellow = Color(0xFFFFDCBF);
  static const Color accentGreen = Color(0xFF4C662B);
  static const Color accentRed = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.notoSansJp().fontFamily,
      
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
        background: backgroundPrimary,
        onBackground: textPrimary,
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
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: backgroundTertiary, width: 1),
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
          borderSide: BorderSide(color: backgroundTertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: backgroundTertiary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: GoogleFonts.notoSansJp(
          fontSize: 14,
          color: textTertiary,
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
  
  // Gradient helpers
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFDCBF), Color(0xFFFFF8F5)],
  );
  
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFEFD9), Color(0xFFFFF8F5)],
  );
}
