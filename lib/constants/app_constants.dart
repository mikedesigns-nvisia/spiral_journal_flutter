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
  // UI Constants
  // ============================================================================
  
  /// Default padding used throughout the application
  static const double defaultPadding = 16.0;
  
  /// Large padding for major sections
  static const double largePadding = 24.0;
  
  /// Extra large padding for major sections
  static const double extraLargePadding = 32.0;
  
  /// Small padding for compact layouts
  static const double smallPadding = 8.0;
  
  /// Standard card border radius
  static const double cardBorderRadius = 16.0;
  
  /// Standard button border radius
  static const double buttonBorderRadius = 8.0;
  
  /// Standard border radius for form elements
  static const double borderRadius = 12.0;
  
  /// Default icon size for UI elements
  static const double defaultIconSize = 24.0;
  
  /// Large icon size for prominent elements
  static const double largeIconSize = 64.0;
  
  /// Standard animation duration in milliseconds
  static const int animationDurationMs = 300;
  
  /// Preview text length for journal entries
  static const int previewTextLength = 100;
  
  /// Horizontal padding for buttons
  static const double buttonHorizontalPadding = 32.0;
  
  /// Vertical padding for buttons
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
