# Splash Screen Design Document

## Overview

The Spiral Journal splash screen will serve as the app's first impression, displaying the brand identity while providing proper attribution. The design will follow Material Design 3 principles and integrate seamlessly with the existing app theme, featuring warm orange and cream color schemes with the Noto Sans JP typography.

## Architecture

### Component Structure
```
SplashScreen (StatefulWidget)
├── AnimationController (for fade transitions)
├── Timer (for minimum display duration)
└── Navigation logic (to next screen)
```

### Integration Points
- **App Entry**: Replaces current AuthWrapper loading state
- **Navigation Flow**: SplashScreen → AuthScreen → MainScreen
- **Theme Integration**: Uses existing AppTheme color palette and typography
- **Animation System**: Leverages Flutter's built-in animation framework

## Components and Interfaces

### SplashScreen Widget
```dart
class SplashScreen extends StatefulWidget {
  final Duration displayDuration;
  final VoidCallback? onComplete;
  
  const SplashScreen({
    Key? key,
    this.displayDuration = const Duration(seconds: 3),
    this.onComplete,
  }) : super(key: key);
}
```

### Key Properties
- **Display Duration**: Configurable minimum display time (default 3 seconds)
- **Auto-dismiss**: Automatic transition after duration
- **Tap-to-dismiss**: Optional early dismissal after minimum time (1 second)
- **Animation Support**: Fade-in/fade-out transitions

### Visual Layout
```
┌─────────────────────────────────┐
│                                 │
│           [App Icon]            │  ← Optional spiral/journal icon
│                                 │
│        Spiral Journal           │  ← Main title (headlineLarge)
│                                 │
│     [Tagline/Description]       │  ← Optional subtitle
│                                 │
│                                 │
│                                 │
│                                 │
│      Powered by Anthropic       │  ← Attribution (bodySmall)
│         Made by Mike            │  ← Creator credit (bodySmall)
│                                 │
└─────────────────────────────────┘
```

## Data Models

### SplashConfig
```dart
class SplashConfig {
  final Duration minDisplayDuration;
  final Duration maxDisplayDuration;
  final bool allowEarlyDismiss;
  final String appName;
  final String? tagline;
  final String aiAttribution;
  final String creatorAttribution;
  
  const SplashConfig({
    this.minDisplayDuration = const Duration(seconds: 2),
    this.maxDisplayDuration = const Duration(seconds: 5),
    this.allowEarlyDismiss = true,
    this.appName = 'Spiral Journal',
    this.tagline,
    this.aiAttribution = 'Powered by Anthropic',
    this.creatorAttribution = 'Made by Mike',
  });
}
```

## Error Handling

### Navigation Failures
- **Fallback Route**: If navigation fails, default to AuthScreen
- **Error Logging**: Log navigation errors for debugging
- **Graceful Degradation**: Continue app flow even if splash encounters issues

### Animation Failures
- **Static Fallback**: Display static content if animations fail
- **Performance Consideration**: Reduce animations on low-performance devices
- **Memory Management**: Properly dispose of animation controllers

### Timer Issues
- **Timeout Protection**: Maximum display duration to prevent infinite splash
- **Background Handling**: Pause timers when app goes to background
- **State Management**: Handle widget disposal during timer execution

## Testing Strategy

### Unit Tests
- **Timer Logic**: Test minimum and maximum display durations
- **Navigation Logic**: Verify correct screen transitions
- **Configuration**: Test different SplashConfig parameters
- **Error Handling**: Test failure scenarios and fallbacks

### Widget Tests
- **Visual Elements**: Verify all text and styling elements render correctly
- **Responsive Design**: Test on different screen sizes
- **Theme Integration**: Ensure proper color and typography usage
- **Accessibility**: Test screen reader compatibility and contrast ratios

### Integration Tests
- **App Flow**: Test complete splash → auth → main screen flow
- **Performance**: Measure splash screen load time and memory usage
- **Platform Testing**: Verify behavior on macOS and other target platforms
- **Animation Smoothness**: Test transition animations under various conditions

## Implementation Details

### Color Scheme
- **Background**: AppTheme.backgroundPrimary (#FFF8F5)
- **Primary Text**: AppTheme.primaryOrange (#865219) for "Spiral Journal"
- **Attribution Text**: AppTheme.textTertiary (#837469) for credits
- **Accent**: AppTheme.primaryLight (#FDB876) for highlights

### Typography
- **App Name**: headlineLarge (24px, weight 600, Noto Sans JP)
- **Tagline**: bodyLarge (16px, weight 400, Noto Sans JP)
- **Attribution**: bodySmall (12px, weight 400, Noto Sans JP)

### Animations
- **Fade In**: 500ms ease-in animation for content appearance
- **Fade Out**: 300ms ease-out animation for screen transition
- **Stagger Effect**: Optional staggered appearance of elements (100ms delays)

### Accessibility
- **Semantic Labels**: Proper semantics for screen readers
- **High Contrast**: Ensure sufficient color contrast ratios
- **Reduced Motion**: Respect system reduce motion preferences
- **Focus Management**: Proper focus handling for keyboard navigation

### Performance Considerations
- **Lightweight**: Minimal resource usage during splash display
- **Preloading**: Optional preloading of critical app resources
- **Memory Efficient**: Proper cleanup of splash screen resources
- **Fast Transition**: Smooth transition to prevent perceived lag