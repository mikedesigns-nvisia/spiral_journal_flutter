/// Validation constants for mood and core data validation
/// 
/// This class centralizes all validation data used throughout the application
/// to ensure consistency and make updates easier to manage.
/// 
/// ## Usage Examples
/// ```dart
/// // Mood validation
/// if (ValidationConstants.isValidMood(selectedMood)) {
///   final primaryCore = ValidationConstants.getPrimaryCoreForMood(selectedMood);
///   // Process valid mood selection
/// }
/// 
/// // Core validation
/// if (ValidationConstants.isValidCoreName(coreName)) {
///   // Update core data
/// }
/// 
/// // Mood categorization
/// final positiveMoods = userMoods.where(ValidationConstants.isPositiveMood);
/// final challengingMoods = userMoods.where(ValidationConstants.isChallengingMood);
/// 
/// // Multi-core mapping for complex analysis
/// final coreWeights = ValidationConstants.moodToMultipleCoreMapping[mood];
/// coreWeights?.forEach((core, weight) => updateCore(core, weight));
/// ```
/// 
/// ## Validation Patterns
/// This class provides several validation approaches:
/// - **Direct validation**: Use `isValid*` methods for simple checks
/// - **Categorization**: Use mood category lists for emotional analysis
/// - **Mapping**: Use mood-to-core mappings for personality insights
/// - **Helper methods**: Use static methods for common validation tasks
/// 
/// ## Extension Guidelines
/// When adding new validation data:
/// 1. **New moods**: Add to `validMoods` and appropriate category lists
/// 2. **New cores**: Add to `validCoreNames` and update mappings
/// 3. **New categories**: Create new category lists with clear naming
/// 4. **New mappings**: Use consistent structure and include weights
/// 
/// ## Maintenance Notes
/// - Keep mood lists synchronized across all categories
/// - Update core mappings when adding new moods or cores
/// - Test validation methods when modifying data structures
/// - Consider impact on existing analysis algorithms when changing weights
class ValidationConstants {
  // Private constructor to prevent instantiation
  ValidationConstants._();

  // ============================================================================
  // Mood Validation Data
  // ============================================================================
  
  /// Complete list of valid mood options available in the application
  static const List<String> validMoods = [
    'happy',
    'content', 
    'energetic',
    'grateful',
    'confident',
    'peaceful',
    'excited',
    'motivated',
    'creative',
    'social',
    'reflective',
    'unsure',
    'tired',
    'stressed',
    'sad'
  ];

  /// Positive mood categories for emotional analysis
  static const List<String> positiveMoods = [
    'happy',
    'content',
    'energetic', 
    'grateful',
    'confident',
    'peaceful',
    'excited',
    'motivated',
    'creative',
    'social'
  ];

  /// Neutral mood categories for emotional analysis
  static const List<String> neutralMoods = [
    'reflective',
    'unsure'
  ];

  /// Challenging mood categories for emotional analysis
  static const List<String> challengingMoods = [
    'tired',
    'stressed',
    'sad'
  ];

  /// High-intensity moods for analysis weighting
  static const List<String> highIntensityMoods = [
    'excited',
    'energetic',
    'stressed'
  ];

  // ============================================================================
  // Core Validation Data
  // ============================================================================
  
  /// Complete list of valid emotional core names
  static const List<String> validCoreNames = [
    'Optimism',
    'Resilience', 
    'Self-Awareness',
    'Creativity',
    'Social Connection',
    'Growth Mindset'
  ];

  /// Valid trend values for core progression
  static const List<String> validCoreTrends = [
    'rising',
    'stable', 
    'declining'
  ];

  /// Mapping of moods to their primary emotional cores
  static const Map<String, String> moodToCoreMapping = {
    'happy': 'Optimism',
    'content': 'Self-Awareness',
    'energetic': 'Creativity',
    'grateful': 'Optimism',
    'confident': 'Resilience',
    'peaceful': 'Self-Awareness',
    'excited': 'Growth Mindset',
    'motivated': 'Growth Mindset',
    'creative': 'Creativity',
    'social': 'Social Connection',
    'reflective': 'Self-Awareness',
  };

  /// Mapping of moods to secondary emotional cores (for fallback analysis)
  static const Map<String, Map<String, double>> moodToMultipleCoreMapping = {
    'happy': {'Optimism': 0.2, 'Self-Awareness': 0.1},
    'content': {'Self-Awareness': 0.2, 'Optimism': 0.1},
    'energetic': {'Creativity': 0.2, 'Growth Mindset': 0.1},
    'grateful': {'Optimism': 0.3, 'Social Connection': 0.1},
    'confident': {'Resilience': 0.2, 'Growth Mindset': 0.1},
    'peaceful': {'Self-Awareness': 0.2, 'Resilience': 0.1},
    'excited': {'Creativity': 0.1, 'Growth Mindset': 0.2},
    'motivated': {'Growth Mindset': 0.3, 'Resilience': 0.1},
    'creative': {'Creativity': 0.3, 'Self-Awareness': 0.1},
    'social': {'Social Connection': 0.3, 'Optimism': 0.1},
    'reflective': {'Self-Awareness': 0.3, 'Growth Mindset': 0.1},
  };

  // ============================================================================
  // Analysis Constants
  // ============================================================================
  
  /// Words that indicate positive emotional states in content analysis
  static const List<String> positiveIndicatorWords = [
    'happy',
    'joyful',
    'excited',
    'grateful',
    'content',
    'peaceful'
  ];

  /// Words that indicate neutral emotional states in content analysis
  static const List<String> neutralIndicatorWords = [
    'reflective',
    'thoughtful', 
    'calm',
    'focused'
  ];

  /// Words that indicate challenging emotional states in content analysis
  static const List<String> challengingIndicatorWords = [
    'sad',
    'stressed',
    'anxious',
    'tired',
    'unsure'
  ];

  // ============================================================================
  // Date and Time Constants
  // ============================================================================
  
  /// Day names for journal entry categorization
  static const List<String> dayNames = [
    'Monday',
    'Tuesday', 
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  /// Month names for date formatting and analysis
  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  // ============================================================================
  // Validation Helper Methods
  // ============================================================================
  
  /// Check if a mood is valid
  static bool isValidMood(String mood) {
    return validMoods.contains(mood.toLowerCase());
  }

  /// Check if a core name is valid
  static bool isValidCoreName(String coreName) {
    return validCoreNames.contains(coreName);
  }

  /// Check if a trend value is valid
  static bool isValidTrend(String trend) {
    return validCoreTrends.contains(trend.toLowerCase());
  }

  /// Get the primary core for a given mood
  static String? getPrimaryCoreForMood(String mood) {
    return moodToCoreMapping[mood.toLowerCase()];
  }

  /// Check if a mood is considered positive
  static bool isPositiveMood(String mood) {
    return positiveMoods.contains(mood.toLowerCase());
  }

  /// Check if a mood is considered challenging
  static bool isChallengingMood(String mood) {
    return challengingMoods.contains(mood.toLowerCase());
  }

  /// Check if a mood is high intensity
  static bool isHighIntensityMood(String mood) {
    return highIntensityMoods.contains(mood.toLowerCase());
  }
}