# Spiral Journal Design System

This design system provides a comprehensive set of design tokens, components, and patterns to ensure consistency across the Spiral Journal application.

## Overview

The design system is organized into three main files:

- **`design_tokens.dart`** - Core design tokens (colors, typography, spacing, etc.)
- **`component_library.dart`** - Pre-built UI components following the design system
- **`README.md`** - This documentation file

## Design Tokens

### Colors

The color system is built around warm oranges and browns that reflect the journaling and mindfulness theme:

#### Primary Colors
```dart
DesignTokens.primaryOrange     // #865219 - Main brand color
DesignTokens.primaryLight      // #FDB876 - Lighter variant
DesignTokens.primaryDark       // #6A3B01 - Darker variant
```

#### Background Colors (Light Theme)
```dart
DesignTokens.backgroundPrimary    // #FFF8F5 - Main background
DesignTokens.backgroundSecondary  // #FAEBE0 - Card backgrounds
DesignTokens.backgroundTertiary   // #F2DFD1 - Subtle backgrounds
```

#### Text Colors (Light Theme)
```dart
DesignTokens.textPrimary     // #211A14 - Primary text
DesignTokens.textSecondary   // #51443A - Secondary text
DesignTokens.textTertiary    // #837469 - Tertiary text
```

#### Mood Colors
```dart
DesignTokens.moodHappy       // #E78B1B
DesignTokens.moodContent     // #7AACB3
DesignTokens.moodUnsure      // #8B7ED8
DesignTokens.moodSad         // #BA1A1A
DesignTokens.moodEnergetic   // #EA8100
```

#### Core Personality Colors
```dart
DesignTokens.coreOptimist    // #AFCACD
DesignTokens.coreReflective  // #EBA751
DesignTokens.coreCreative    // #A198DD
DesignTokens.coreSocial      // #B1CDAF
DesignTokens.coreRest        // #B37A9B
```

### Typography

The typography system uses Noto Sans JP with platform-specific fallbacks:

#### Font Sizes
```dart
DesignTokens.fontSizeXS      // 10.0
DesignTokens.fontSizeS       // 12.0
DesignTokens.fontSizeM       // 14.0
DesignTokens.fontSizeL       // 16.0
DesignTokens.fontSizeXL      // 18.0
DesignTokens.fontSizeXXL     // 20.0
DesignTokens.fontSizeXXXL    // 24.0
DesignTokens.fontSizeDisplay // 32.0
```

#### Font Weights
```dart
DesignTokens.fontWeightLight     // FontWeight.w300
DesignTokens.fontWeightRegular   // FontWeight.w400
DesignTokens.fontWeightMedium    // FontWeight.w500
DesignTokens.fontWeightSemiBold  // FontWeight.w600
DesignTokens.fontWeightBold      // FontWeight.w700
```

### Spacing

The spacing system is based on a 4px grid:

```dart
DesignTokens.spaceXXS    // 2.0
DesignTokens.spaceXS     // 4.0
DesignTokens.spaceS      // 8.0
DesignTokens.spaceM      // 12.0
DesignTokens.spaceL      // 16.0
DesignTokens.spaceXL     // 20.0
DesignTokens.spaceXXL    // 24.0
DesignTokens.spaceXXXL   // 32.0
DesignTokens.spaceHuge   // 48.0
```

### Border Radius

```dart
DesignTokens.radiusXS     // 4.0
DesignTokens.radiusS      // 8.0
DesignTokens.radiusM      // 12.0
DesignTokens.radiusL      // 16.0
DesignTokens.radiusXL     // 20.0
DesignTokens.radiusXXL    // 24.0
DesignTokens.radiusRound  // 50.0
```

### Elevation

```dart
DesignTokens.elevationNone  // 0.0
DesignTokens.elevationXS    // 1.0
DesignTokens.elevationS     // 2.0
DesignTokens.elevationM     // 4.0
DesignTokens.elevationL     // 8.0
DesignTokens.elevationXL    // 12.0
DesignTokens.elevationXXL   // 16.0
```

## Component Library

### Buttons

#### Primary Button
```dart
ComponentLibrary.primaryButton(
  text: 'Save Entry',
  onPressed: () => _saveEntry(),
  icon: Icons.save,
  size: ButtonSize.medium,
)
```

#### Secondary Button
```dart
ComponentLibrary.secondaryButton(
  text: 'Cancel',
  onPressed: () => Navigator.pop(context),
  size: ButtonSize.medium,
)
```

#### Text Button
```dart
ComponentLibrary.textButton(
  text: 'Learn More',
  onPressed: () => _showInfo(),
  icon: Icons.info_outline,
)
```

### Cards

#### Standard Card
```dart
ComponentLibrary.card(
  child: Column(
    children: [
      Text('Card Title'),
      Text('Card content goes here'),
    ],
  ),
  onTap: () => _handleCardTap(),
)
```

#### Gradient Card
```dart
ComponentLibrary.gradientCard(
  child: Text('Gradient card content'),
  gradient: DesignTokens.cardGradient,
)
```

### Input Fields

```dart
ComponentLibrary.textField(
  label: 'Journal Entry',
  hint: 'How are you feeling today?',
  helperText: 'Express your thoughts freely',
  maxLines: 5,
  required: true,
  controller: _textController,
  onChanged: (value) => _handleTextChange(value),
)
```

### Chips

#### Mood Chip
```dart
ComponentLibrary.moodChip(
  label: 'Happy',
  isSelected: selectedMoods.contains('happy'),
  onTap: () => _toggleMood('happy'),
  moodType: 'happy',
)
```

#### Filter Chip
```dart
ComponentLibrary.filterChip(
  label: 'Recent',
  isSelected: filterType == 'recent',
  onSelected: (selected) => _setFilter('recent'),
  icon: Icons.access_time,
)
```

### Status Indicators

```dart
ComponentLibrary.statusIndicator(
  status: 'success',
  message: 'Entry saved successfully!',
  showIcon: true,
)
```

## Theme-Aware Helpers

The design system provides helper methods to get theme-appropriate colors:

```dart
// Get primary color based on current theme
Color primaryColor = DesignTokens.getPrimaryColor(context);

// Get background colors
Color bgPrimary = DesignTokens.getBackgroundPrimary(context);
Color bgSecondary = DesignTokens.getBackgroundSecondary(context);

// Get text colors
Color textPrimary = DesignTokens.getTextPrimary(context);
Color textSecondary = DesignTokens.getTextSecondary(context);
```

## Responsive Design

### Breakpoints
```dart
DesignTokens.breakpointMobile   // 480.0
DesignTokens.breakpointTablet   // 768.0
DesignTokens.breakpointDesktop  // 1024.0
```

### Responsive Values
```dart
double padding = DesignTokens.getResponsiveValue(
  context,
  mobile: 16.0,
  tablet: 24.0,
  desktop: 32.0,
);
```

### Device Type Checks
```dart
if (DesignTokens.isMobile(context)) {
  // Mobile-specific layout
} else if (DesignTokens.isTablet(context)) {
  // Tablet-specific layout
} else {
  // Desktop layout
}
```

## Layout Components

### Responsive Container
```dart
LayoutComponents.responsiveContainer(
  child: YourContent(),
  maxWidth: 800.0,
)
```

### Responsive Grid
```dart
LayoutComponents.responsiveGrid(
  children: widgets,
  mobileColumns: 1,
  tabletColumns: 2,
  desktopColumns: 3,
  spacing: DesignTokens.spaceL,
)
```

### Spacers
```dart
LayoutComponents.spacer(size: SpacingSize.large)
LayoutComponents.horizontalSpacer(size: SpacingSize.medium)
```

## Animation System

### Durations
```dart
DesignTokens.durationFast     // 150ms
DesignTokens.durationNormal   // 300ms
DesignTokens.durationSlow     // 500ms
DesignTokens.durationSlower   // 800ms
```

### Curves
```dart
DesignTokens.curveStandard    // Curves.easeOutCubic
DesignTokens.curveDecelerate  // Curves.easeOut
DesignTokens.curveAccelerate  // Curves.easeIn
DesignTokens.curveBounce      // Curves.elasticOut
DesignTokens.curveSpring      // Curves.easeOutBack
```

## Accessibility

The design system includes accessibility tokens to ensure inclusive design:

```dart
AccessibilityTokens.minTouchTarget        // 44.0
AccessibilityTokens.preferredTouchTarget  // 48.0
AccessibilityTokens.minTextSize          // 12.0
AccessibilityTokens.preferredTextSize    // 16.0
```

## Usage Guidelines

### Do's
- ✅ Use design tokens instead of hardcoded values
- ✅ Use component library components when available
- ✅ Follow the spacing system (4px grid)
- ✅ Use theme-aware color helpers
- ✅ Test components in both light and dark themes
- ✅ Ensure minimum touch targets for accessibility

### Don'ts
- ❌ Don't hardcode colors, spacing, or typography values
- ❌ Don't create custom components without following design tokens
- ❌ Don't ignore responsive design considerations
- ❌ Don't use arbitrary spacing values outside the system
- ❌ Don't forget to test accessibility features

## Examples

### Creating a Journal Entry Card
```dart
ComponentLibrary.card(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Today\'s Reflection',
        style: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeXL,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.getTextPrimary(context),
        ),
      ),
      LayoutComponents.spacer(size: SpacingSize.small),
      Text(
        entry.content,
        style: DesignTokens.getTextStyle(
          fontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.getTextSecondary(context),
        ),
      ),
      LayoutComponents.spacer(size: SpacingSize.medium),
      Wrap(
        spacing: DesignTokens.spaceS,
        children: entry.moods.map((mood) =>
          ComponentLibrary.moodChip(
            label: mood,
            isSelected: true,
            onTap: () {},
            moodType: mood,
          ),
        ).toList(),
      ),
    ],
  ),
)
```

### Creating a Settings Form
```dart
Column(
  children: [
    ComponentLibrary.textField(
      label: 'Display Name',
      hint: 'Enter your display name',
      controller: _nameController,
      required: true,
    ),
    LayoutComponents.spacer(size: SpacingSize.medium),
    ComponentLibrary.textField(
      label: 'Bio',
      hint: 'Tell us about yourself',
      maxLines: 3,
      controller: _bioController,
    ),
    LayoutComponents.spacer(size: SpacingSize.large),
    Row(
      children: [
        Expanded(
          child: ComponentLibrary.secondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        LayoutComponents.horizontalSpacer(size: SpacingSize.medium),
        Expanded(
          child: ComponentLibrary.primaryButton(
            text: 'Save',
            onPressed: _saveSettings,
            icon: Icons.save,
          ),
        ),
      ],
    ),
  ],
)
```

## Migration Guide

If you're updating existing components to use the design system:

1. **Replace hardcoded colors** with design tokens:
   ```dart
   // Before
   color: Color(0xFF865219)
   
   // After
   color: DesignTokens.primaryOrange
   ```

2. **Replace hardcoded spacing** with design tokens:
   ```dart
   // Before
   padding: EdgeInsets.all(16.0)
   
   // After
   padding: EdgeInsets.all(DesignTokens.spaceL)
   ```

3. **Use component library** instead of custom widgets:
   ```dart
   // Before
   ElevatedButton(...)
   
   // After
   ComponentLibrary.primaryButton(...)
   ```

4. **Make components theme-aware**:
   ```dart
   // Before
   color: Colors.black
   
   // After
   color: DesignTokens.getTextPrimary(context)
   ```

## Contributing

When adding new components or tokens:

1. Follow the existing naming conventions
2. Add comprehensive documentation
3. Test in both light and dark themes
4. Ensure accessibility compliance
5. Update this README with usage examples

## Support

For questions about the design system, please refer to:
- The component library source code
- Design token definitions
- Existing usage patterns in the codebase
