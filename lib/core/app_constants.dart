/// Application-wide constants for UI, database, and system configuration
/// 
/// This class centralizes all magic numbers and configuration values used
/// throughout the application to improve maintainability and consistency.
/// 
/// ## Usage Examples
/// ```dart
/// // UI Layout
/// Container(
///   padding: EdgeInsets.all(AppConstants.defaultPadding),
///   child: Card(
///     borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
///   ),
/// );
/// 
/// // Database Operations
/// if (content.length > AppConstants.maxContentLength) {
///   throw ValidationException('Content too long');
/// }
/// 
/// // Timeout Management
/// final result = await operation()
///     .timeout(AppConstants.authTimeout);
/// ```
/// 
/// ## Maintenance Guidelines
/// - When adding new constants, group them logically in existing sections
/// - Use descriptive names that clearly indicate the constant's purpose
/// - Include units in the name when applicable (e.g., `durationMs`, `lengthPx`)
/// - Update related validation when changing limits or thresholds
/// - Consider backward compatibility when modifying existing constants
/// 
/// ## Extension Pattern
/// To add new constant categories:
/// 1. Add a new section with clear comment dividers
/// 2. Group related constants together
/// 3. Use consistent naming conventions
/// 4. Add documentation for complex or non-obvious values
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ============================================================================
  // SPACING CONSTANTS
  // ============================================================================
  
  /// Fine-grained spacing scale
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  
  /// Semantic spacing aliases
  static const double defaultPadding = spacing16;
  static const double smallPadding = spacing8;
  static const double largePadding = spacing24;
  static const double extraLargePadding = spacing32;

  // ============================================================================
  // BORDER RADIUS CONSTANTS
  // ============================================================================
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  /// Semantic radius aliases
  static const double cardBorderRadius = radiusLarge;
  static const double buttonBorderRadius = radiusSmall;
  static const double chipBorderRadius = radiusXLarge;
  static const double borderRadius = radiusMedium; // Legacy alias
  
  // ============================================================================
  // ANIMATION CONSTANTS
  // ============================================================================
  
  static const int animationFast = 200;
  static const int animationNormal = 300;
  static const int animationSlow = 500;
  
  /// Semantic animation aliases
  static const int animationDurationMs = animationNormal;
  static const Duration animationDuration = Duration(milliseconds: animationNormal);
  static const Duration pageTransitionDuration = Duration(milliseconds: animationSlow);
  
  // ============================================================================
  // SIZE CONSTANTS
  // ============================================================================
  
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  
  /// Legacy aliases
  static const double defaultIconSize = iconSizeMedium;
  static const double largeIconSize = iconSizeXLarge;
  
  /// Accessibility minimum touch target
  static const double minTouchTarget = 48.0;
  
  // ============================================================================
  // ELEVATION CONSTANTS
  // ============================================================================
  
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // ============================================================================
  // TEXT & CONTENT CONSTANTS
  // ============================================================================
  
  static const int maxJournalLength = 10000;
  static const int maxTitleLength = 100;
  static const int snippetLength = 150;
  static const int previewTextLength = 100; // Legacy alias
  
  /// Button padding
  static const double buttonHorizontalPadding = 32.0;
  static const double buttonVerticalPadding = 16.0;

  // ============================================================================
  // Database Constants
  // ============================================================================
  
  /// Maximum content length for journal entries (characters)
  static const int maxContentLength = 10000;
  
  /// Default user ID for local storage
  static const String defaultUserId = 'local_user';
  
  /// Maximum number of error history entries to keep
  static const int maxHistorySize = 100;

  // ============================================================================
  // Validation Constants
  // ============================================================================
  
  /// Minimum number of moods that must be selected
  static const int minMoodSelection = 1;
  
  /// Maximum number of moods that can be selected
  static const int maxMoodSelection = 10;
  
  /// Minimum words per entry for detailed reflection analysis
  static const int minWordsForDetailedAnalysis = 50;
  
  /// Core percentage increment for mood-based updates
  static const double corePercentageIncrement = 0.5;
  
  /// Minimum percentage difference to consider a trend change
  static const double trendChangeThreshold = 0.1;
  
  /// Maximum core percentage value
  static const double maxCorePercentage = 100.0;
  
  /// Minimum core percentage value
  static const double minCorePercentage = 0.0;

  // ============================================================================
  // Timeout Constants
  // ============================================================================
  
  /// Maximum time to wait for app initialization
  static const Duration initializationTimeout = Duration(seconds: 15);
  
  /// Timeout for authentication operations
  static const Duration authTimeout = Duration(seconds: 5);
  
  /// Timeout for health check operations
  static const Duration healthCheckTimeout = Duration(seconds: 3);
  
  /// Timeout for first launch detection
  static const Duration firstLaunchTimeout = Duration(seconds: 3);

  // ============================================================================
  // Analysis Constants
  // ============================================================================
  
  /// Number of top moods to consider for monthly summaries
  static const int topMoodsCount = 3;
  
  /// Number of data points for emotional journey visualization
  static const int journeyDataPoints = 4;
  
  /// Multiplier for journey data variation
  static const double journeyDataVariation = 0.1;
  
  /// Minimum entries required for meaningful analysis
  static const int minEntriesForAnalysis = 1;

  // ============================================================================
  // Core System Constants
  // ============================================================================
  
  /// Number of emotional cores in the system
  static const int totalCoreCount = 6;
  
  /// Default core percentage for new cores
  static const double defaultCorePercentage = 50.0;
}
