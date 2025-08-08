# Design Document

## Overview

This design enhances the emotional mirror screen's accessibility by adding text indicators for emotions in the emotional balance widget and creating a new primary emotional state widget. The solution ensures users with color vision deficiencies can fully understand their emotional data through both visual and textual representations while maintaining the app's aesthetic appeal.

## Architecture

### Component Structure

```
EmotionalMirrorScreen
├── PrimaryEmotionalStateWidget (NEW)
│   ├── EmotionalStateIndicator
│   ├── AccessibleEmotionLabel
│   └── StateChangeAnimation
├── Enhanced EmotionalBalanceWidget
│   ├── ColorIndicator (existing)
│   ├── TextLabel (NEW)
│   └── AccessibilityWrapper (NEW)
└── Existing components (unchanged)
```

### Data Flow

1. **Emotional Analysis Service** → Provides current emotional state data
2. **Primary Emotional State Widget** → Displays dominant emotion with text labels
3. **Enhanced Emotional Balance Widget** → Shows balance with color + text indicators
4. **Accessibility Service** → Provides semantic labels and announcements

## Components and Interfaces

### 1. Primary Emotional State Widget

**Purpose**: Display the user's current dominant emotional state prominently with full accessibility support.

**Interface**:
```dart
class PrimaryEmotionalStateWidget extends StatelessWidget {
  final EmotionalState primaryState;
  final double confidence;
  final bool showAnimation;
  final VoidCallback? onTap;
}

class EmotionalState {
  final String emotion;
  final double intensity;
  final Color color;
  final String description;
  final DateTime lastUpdated;
}
```

**Features**:
- Large, prominent display of primary emotion
- Text label alongside color indicator
- Confidence level indicator
- Smooth state change animations (respects reduced motion)
- Full screen reader support
- Keyboard navigation support

### 2. Enhanced Emotional Balance Widget

**Purpose**: Extend existing emotional balance visualization with text indicators for accessibility.

**Interface**:
```dart
class AccessibleEmotionalBalanceWidget extends StatelessWidget {
  final EmotionalBalance balance;
  final bool showTextLabels;
  final bool highContrastMode;
  final VoidCallback? onTap;
}

class EmotionIndicator {
  final String emotion;
  final double value;
  final Color color;
  final String textLabel;
  final String accessibilityLabel;
}
```

**Features**:
- Text labels for each emotion segment
- High contrast mode support
- Semantic labels for screen readers
- Keyboard focusable elements
- Theme-aware color adaptation

### 3. Accessibility Enhancement Service

**Purpose**: Provide accessibility-specific functionality for emotional mirror components.

**Interface**:
```dart
class EmotionalMirrorAccessibilityService {
  String getEmotionalStateSemanticLabel(EmotionalState state);
  String getEmotionalBalanceSemanticLabel(EmotionalBalance balance);
  void announceEmotionalStateChange(EmotionalState newState);
  AccessibleEmotionColors getAccessibleEmotionColors(BuildContext context);
}
```

## Data Models

### Enhanced Emotional State Model

```dart
class EmotionalState {
  final String emotion;
  final double intensity; // 0.0 to 1.0
  final double confidence; // 0.0 to 1.0
  final Color primaryColor;
  final Color accessibleColor;
  final String displayName;
  final String description;
  final DateTime timestamp;
  final List<String> relatedEmotions;
  
  // Accessibility properties
  final String semanticLabel;
  final String accessibilityHint;
  final bool isPositive;
}
```

### Accessible Emotion Colors

```dart
class AccessibleEmotionColors {
  final Map<String, EmotionColorPair> emotionColors;
  final bool highContrastMode;
  final Brightness brightness;
}

class EmotionColorPair {
  final Color primary;
  final Color accessible;
  final Color onColor;
  final String textLabel;
  final double contrastRatio;
}
```

## Error Handling

### Graceful Degradation
- **No emotional data**: Show neutral state with appropriate messaging
- **Color calculation errors**: Fall back to high contrast colors
- **Animation failures**: Display static state without animation
- **Accessibility service errors**: Continue with basic text labels

### Error Recovery
- Retry emotional state calculation on failure
- Cache last known good state for display
- Provide manual refresh option
- Log accessibility-related errors for debugging

## Testing Strategy

### Unit Tests
- **EmotionalStateWidget**: Test state display and accessibility labels
- **AccessibleEmotionalBalance**: Test text label generation and color contrast
- **AccessibilityService**: Test semantic label generation and announcements

### Integration Tests
- **Theme switching**: Verify accessibility in light/dark modes
- **Screen reader**: Test with TalkBack/VoiceOver simulation
- **Keyboard navigation**: Test focus management and navigation
- **State changes**: Test smooth transitions and announcements

### Accessibility Tests
- **Color contrast**: Verify WCAG AA compliance (4.5:1 ratio)
- **Screen reader**: Test semantic labels and announcements
- **Keyboard navigation**: Test full keyboard accessibility
- **High contrast mode**: Test visibility in high contrast themes

### Visual Tests
- **Color vision simulation**: Test with deuteranopia, protanopia, tritanopia
- **Text readability**: Test text labels in various lighting conditions
- **Animation respect**: Test reduced motion preferences

## Implementation Details

### Primary Emotional State Widget Layout

```
┌─────────────────────────────────────┐
│  🟠 Happy (Primary Emotion)         │
│  ████████████████░░░░ 80% Confident │
│  "Feeling joyful and optimistic"    │
│  Last updated: 2 minutes ago        │
└─────────────────────────────────────┘
```

### Enhanced Emotional Balance Widget Layout

```
┌─────────────────────────────────────┐
│  Emotional Balance                  │
│  ████████████████████████████████   │
│  🟢 Positive  🟡 Neutral  🔴 Negative│
│  60%         25%        15%         │
└─────────────────────────────────────┘
```

### Accessibility Features

1. **Semantic Labels**:
   - Primary state: "Happy emotion at 80% intensity, high confidence"
   - Balance: "Emotional balance: 60% positive, 25% neutral, 15% negative"

2. **Screen Reader Announcements**:
   - State changes: "Primary emotion changed to Happy"
   - Updates: "Emotional data refreshed"

3. **Keyboard Navigation**:
   - Tab order: Primary state → Balance widget → Action buttons
   - Enter/Space: Activate focused element
   - Arrow keys: Navigate within complex widgets

4. **High Contrast Support**:
   - Increased border thickness
   - Enhanced color differentiation
   - Bold text weights
   - Clear visual separators

### Theme Integration

The widgets will integrate with the existing theme system:

- **Light Theme**: Use warm colors with sufficient contrast
- **Dark Theme**: Adapt colors for dark backgrounds
- **High Contrast**: Use system high contrast colors
- **Color Blind**: Provide alternative visual indicators

### Performance Considerations

- **Lazy Loading**: Load emotional state data on demand
- **Caching**: Cache calculated accessibility labels
- **Animation Optimization**: Use efficient animation controllers
- **Memory Management**: Dispose of resources properly

### Localization Support

- **Text Labels**: Support for multiple languages
- **Semantic Labels**: Localized screen reader text
- **Cultural Adaptation**: Respect cultural emotion expressions
- **RTL Support**: Right-to-left language support