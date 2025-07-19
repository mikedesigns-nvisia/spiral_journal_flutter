# Design Document

## Overview

The Fresh Install Experience feature transforms the development app into a production-like environment where every launch simulates a first-time user experience. This is achieved through a comprehensive data clearing mechanism and forced navigation flow that ensures developers can consistently test the complete user onboarding journey.

## Architecture

### Core Components

1. **FreshInstallManager**: Central service responsible for detecting fresh install mode and orchestrating the data clearing process
2. **DataClearingService**: Handles the systematic removal of all user data across different storage mechanisms
3. **NavigationFlowController**: Manages the mandatory navigation sequence through splash → onboarding → profile → journal
4. **DevelopmentModeDetector**: Determines when the app is running in development mode to enable fresh install behavior

### Data Flow

```
App Launch → FreshInstallManager.initialize()
    ↓
Check if fresh install mode enabled
    ↓
DataClearingService.clearAllData()
    ↓
NavigationFlowController.startFreshFlow()
    ↓
Splash Screen → Onboarding → Profile → Journal
```

## Components and Interfaces

### FreshInstallManager

```dart
class FreshInstallManager {
  static bool _isFreshInstallMode = true; // Default for development
  
  static Future<void> initialize() async
  static bool get isFreshInstallMode
  static void setFreshInstallMode(bool enabled)
  static Future<void> performFreshInstall()
}
```

**Responsibilities:**
- Detect if fresh install mode should be active
- Coordinate the data clearing process
- Provide configuration interface for toggling the feature

### DataClearingService

```dart
class DataClearingService {
  static Future<void> clearAllData() async
  static Future<void> clearDatabase() async
  static Future<void> clearSharedPreferences() async
  static Future<void> clearSecureStorage() async
  static Future<void> clearCaches() async
}
```

**Responsibilities:**
- Clear SQLite database entries
- Reset SharedPreferences to defaults
- Clear Flutter Secure Storage
- Remove cached AI analysis data
- Reset user settings and preferences

### NavigationFlowController

```dart
class NavigationFlowController {
  static Future<void> startFreshFlow(BuildContext context) async
  static bool canNavigateBack(String currentRoute)
  static String getNextRoute(String currentRoute)
  static void enforceFlowSequence()
}
```

**Responsibilities:**
- Enforce the mandatory navigation sequence
- Prevent backward navigation during onboarding
- Manage screen transitions and timing
- Ensure all required steps are completed

### DevelopmentModeDetector

```dart
class DevelopmentModeDetector {
  static bool get isDevelopmentMode
  static bool get isFlutterRun
  static void logFreshInstallStatus()
}
```

**Responsibilities:**
- Detect if app is running via `flutter run`
- Distinguish between development and production builds
- Provide logging for debugging fresh install behavior

## Data Models

### FreshInstallConfig

```dart
class FreshInstallConfig {
  final bool enabled;
  final bool showIndicator;
  final bool enableLogging;
  final Duration splashDuration;
  
  const FreshInstallConfig({
    this.enabled = true,
    this.showIndicator = true,
    this.enableLogging = true,
    this.splashDuration = const Duration(seconds: 2),
  });
}
```

### NavigationState

```dart
enum NavigationState {
  splash,
  onboarding,
  profileSetup,
  journal,
  completed
}

class FlowState {
  final NavigationState currentState;
  final bool canGoBack;
  final String? nextRoute;
  
  const FlowState({
    required this.currentState,
    this.canGoBack = false,
    this.nextRoute,
  });
}
```

## Error Handling

### Data Clearing Failures
- Log specific errors for each storage mechanism
- Continue with fresh install flow even if some data clearing fails
- Provide fallback mechanisms for critical data clearing operations

### Navigation Flow Interruptions
- Handle system back button presses during mandatory flow
- Manage app lifecycle events (backgrounding/foregrounding)
- Recover from navigation stack corruption

### Configuration Errors
- Validate fresh install configuration on startup
- Provide sensible defaults for missing configuration
- Log configuration issues for debugging

## Testing Strategy

### Unit Tests
- Test each data clearing mechanism independently
- Verify navigation flow logic and state transitions
- Test configuration loading and validation
- Mock storage services for isolated testing

### Integration Tests
- Test complete fresh install flow from launch to journal screen
- Verify data persistence is properly cleared
- Test navigation enforcement and back button handling
- Validate timing and animations match production behavior

### Manual Testing Scenarios
- Launch app multiple times to verify consistent fresh install behavior
- Test with different device orientations and screen sizes
- Verify performance impact of data clearing operations
- Test error recovery scenarios

## Performance Considerations

### Data Clearing Optimization
- Perform data clearing operations in parallel where possible
- Use efficient database clearing methods (DROP/CREATE vs DELETE)
- Minimize UI blocking during data clearing operations
- Implement progress indicators for longer operations

### Memory Management
- Ensure proper disposal of services and controllers
- Clear cached objects and listeners during data clearing
- Monitor memory usage during fresh install process
- Implement garbage collection hints after major data clearing

### Startup Performance
- Optimize the fresh install detection logic
- Cache configuration values to avoid repeated file reads
- Use lazy initialization for non-critical components
- Profile startup time impact of fresh install mode

## Security Considerations

### Data Sanitization
- Ensure complete removal of sensitive user data
- Verify secure storage is properly cleared
- Clear any temporary files or caches containing user data
- Implement secure deletion methods where available

### Development Mode Safety
- Prevent accidental activation in production builds
- Validate that fresh install mode is development-only
- Implement safeguards against data loss in production
- Log security-relevant events for audit purposes

## Implementation Notes

### Integration Points
- Modify `main.dart` to initialize FreshInstallManager early
- Update splash screen controller to respect fresh install timing
- Integrate with existing authentication and onboarding flows
- Ensure compatibility with existing navigation patterns

### Configuration Management
- Use environment variables or build flags for configuration
- Support runtime toggling for development convenience
- Provide clear documentation for configuration options
- Implement configuration validation and error reporting

### Logging and Debugging
- Implement comprehensive logging for troubleshooting
- Provide visual indicators when fresh install mode is active
- Log timing information for performance analysis
- Include fresh install status in crash reports and diagnostics