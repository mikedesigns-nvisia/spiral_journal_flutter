# Design Document

## Overview

This design addresses the heading size inconsistency issue by establishing a comprehensive standardization approach. The solution involves auditing all text usage across the app, creating a mapping of current inconsistencies to standardized HeadingSystem methods, and systematically refactoring all screens to use the unified heading system.

## Architecture

### Current State Analysis

The app currently has three different approaches to text styling:

1. **HeadingSystem methods** (correct approach)
   - `HeadingSystem.getHeadlineLarge()`, `HeadingSystem.screenTitle()`, etc.
   - Provides consistent, theme-aware, responsive text styles

2. **Direct Theme usage** (inconsistent)
   - `Theme.of(context).textTheme.headlineLarge`
   - Often combined with `.copyWith(fontSize: X)` overrides

3. **Manual styling** (problematic)
   - `AppTheme.getTextStyle(fontSize: X, ...)`
   - `TextStyle(fontSize: X, ...)`
   - Creates arbitrary font sizes that break the design system

### Target Architecture

All text styling will use the HeadingSystem as the single source of truth:

```dart
// ✅ Correct approach
HeadingSystem.screenTitle(context, 'Settings')
HeadingSystem.sectionHeading(context, 'AI Analysis & Privacy')
HeadingSystem.cardTitle(context, 'Your Cores')

// ❌ Approaches to eliminate
Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 32)
AppTheme.getTextStyle(fontSize: 16, fontWeight: FontWeight.w600, ...)
TextStyle(fontSize: 14, ...)
```

## Components and Interfaces

### HeadingSystem Enhancement

The existing HeadingSystem already provides comprehensive text styles. We need to ensure all screens use these consistently:

#### Screen-Level Headings
- `HeadingSystem.screenTitle()` - App bar titles
- `HeadingSystem.pageHeading()` - Main page headings

#### Section-Level Headings  
- `HeadingSystem.sectionHeading()` - Section dividers
- `HeadingSystem.sectionHeadingWithIcon()` - Sections with icons

#### Component-Level Headings
- `HeadingSystem.cardTitle()` - Card headers
- `HeadingSystem.listItemTitle()` - List item titles
- `HeadingSystem.caption()` - Metadata and captions

#### Specialized Components
- `HeadingSystem.appBar()` - Standardized app bars
- `HeadingSystem.listTile()` - Standardized list tiles
- `EmptyStateWidget` - Consistent empty states

### Text Style Mapping

Current inconsistent usage will be mapped to standardized methods:

| Current Usage | Font Size | Target HeadingSystem Method |
|---------------|-----------|----------------------------|
| App bar titles | 18-32px | `HeadingSystem.screenTitle()` |
| Section headings | 14-20px | `HeadingSystem.sectionHeading()` |
| Card titles | 14-18px | `HeadingSystem.cardTitle()` |
| List item titles | 12-16px | `HeadingSystem.listItemTitle()` |
| Button text | 12-16px | Use theme's button styles |
| Captions/metadata | 8-12px | `HeadingSystem.caption()` |

## Data Models

### Text Style Audit Results

Based on the code analysis, these are the main inconsistencies found:

#### Splash Screen
- Manual fontSize: 32, 16, 12 (multiple instances)
- Should use: `HeadingSystem.pageHeading()`, `HeadingSystem.getBodyLarge()`, `HeadingSystem.caption()`

#### Core Library Screen  
- Manual fontSize: 8, 11 (small text overrides)
- Should use: `HeadingSystem.caption()` or `HeadingSystem.getLabelSmall()`

#### Journal Screen
- Manual fontSize: 12, 11 (analysis results)
- Should use: `HeadingSystem.caption()` for metadata

#### Settings Screen
- Manual fontSize: 16, 14, 11 (section titles, descriptions)
- Should use: `HeadingSystem.sectionHeading()`, `HeadingSystem.getBodyMedium()`

#### Journal History Screen
- Manual fontSize: 12, 8, 9, 10 (various UI elements)
- Should use appropriate HeadingSystem methods based on semantic meaning

## Error Handling

### Validation Strategy

1. **Compile-time validation**: Remove all manual fontSize parameters
2. **Runtime validation**: Ensure HeadingSystem methods work across all themes
3. **Visual regression testing**: Compare before/after screenshots
4. **Accessibility testing**: Verify text scaling works properly

### Fallback Mechanisms

- HeadingSystem already includes fallback fonts for different platforms
- Responsive scaling is built into the system
- Theme switching is handled automatically

## Testing Strategy

### Unit Tests
- Verify HeadingSystem methods return consistent TextStyle objects
- Test responsive scaling calculations
- Validate theme-aware color selection

### Widget Tests  
- Test each refactored screen renders correctly
- Verify text hierarchy is maintained
- Check accessibility semantics

### Integration Tests
- Test theme switching maintains heading consistency
- Verify text scaling works across all screens
- Test on different device sizes

### Visual Regression Tests
- Screenshot comparison before/after refactoring
- Verify no unintended layout changes
- Check text alignment and spacing

## Implementation Phases

### Phase 1: Audit and Mapping
- Complete inventory of all manual fontSize usage
- Create mapping to appropriate HeadingSystem methods
- Document semantic meaning of each text element

### Phase 2: Core Screens Refactoring
- Refactor main screens (Journal, Settings, Core Library)
- Replace manual fontSize with HeadingSystem calls
- Test each screen individually

### Phase 3: Secondary Screens
- Refactor remaining screens (History, Profile Setup, etc.)
- Handle edge cases and specialized text elements
- Ensure consistency across all screens

### Phase 4: Validation and Testing
- Run comprehensive test suite
- Perform visual regression testing
- Validate accessibility compliance
- Test on multiple device sizes

## Responsive Design Considerations

The HeadingSystem already includes responsive design features:

- `getiPhoneAdaptiveFontSize()` for device-specific scaling
- `getResponsiveFontSize()` for general responsive behavior
- Built-in breakpoints for different screen sizes

All refactored text will automatically benefit from these responsive features.

## Accessibility Compliance

The standardized approach improves accessibility:

- Semantic heading levels for screen readers
- Consistent text scaling behavior
- Proper color contrast ratios
- Touch target size compliance

## Performance Impact

The refactoring will have minimal performance impact:

- HeadingSystem methods are lightweight
- Reduced code duplication
- Better theme caching
- Fewer style calculations at runtime