# Heading Standardization Audit

## Overview
This document provides a comprehensive inventory of all manual fontSize usage across the Spiral Journal app, documenting current font sizes, their semantic purposes, and mapping each usage to appropriate HeadingSystem methods.

## HeadingSystem Available Methods

### Text Style Methods
- `HeadingSystem.getDisplayLarge(context)` - 42px (largest headings)
- `HeadingSystem.getDisplayMedium(context)` - 32px 
- `HeadingSystem.getDisplaySmall(context)` - 26px
- `HeadingSystem.getHeadlineLarge(context)` - 20px (section headings)
- `HeadingSystem.getHeadlineMedium(context)` - 18px (standard heading)
- `HeadingSystem.getHeadlineSmall(context)` - 16px (component headings)
- `HeadingSystem.getTitleLarge(context)` - 16px (component titles)
- `HeadingSystem.getTitleMedium(context)` - 14px (card titles)
- `HeadingSystem.getTitleSmall(context)` - 12px (section labels)
- `HeadingSystem.getBodyLarge(context)` - 16px (main body text)
- `HeadingSystem.getBodyMedium(context)` - 14px (secondary body text)
- `HeadingSystem.getBodySmall(context)` - 12px (captions and metadata)
- `HeadingSystem.getLabelLarge(context)` - 14px (button text)
- `HeadingSystem.getLabelMedium(context)` - 12px (tab labels)
- `HeadingSystem.getLabelSmall(context)` - 10px (chip text)

### Component Methods
- `HeadingSystem.screenTitle(context, text)` - App bar titles
- `HeadingSystem.pageHeading(context, text)` - Main page headings
- `HeadingSystem.sectionHeading(context, text)` - Section dividers
- `HeadingSystem.cardTitle(context, text)` - Card headers
- `HeadingSystem.listItemTitle(context, text)` - List item titles
- `HeadingSystem.caption(context, text)` - Metadata and captions

## Manual fontSize Usage Inventory

### 1. Splash Screen (`lib/screens/splash_screen.dart`)

#### Current Issues:
- **Line 169**: `fontSize: 32` - App title "Spiral Journal"
  - **Semantic Purpose**: Main app title on splash screen
  - **Recommended Fix**: `HeadingSystem.getDisplayMedium(context)` (32px)
  - **Alternative**: `HeadingSystem.pageHeading(context, 'Spiral Journal')`

- **Line 183**: `fontSize: 16` - Subtitle text
  - **Semantic Purpose**: App description/subtitle
  - **Recommended Fix**: `HeadingSystem.getBodyLarge(context)` (16px)

- **Line 202**: `fontSize: 12` - Loading status text
  - **Semantic Purpose**: Status/progress indicator
  - **Recommended Fix**: `HeadingSystem.getBodySmall(context)` (12px)

- **Line 210**: `fontSize: 12` - Bold status text
  - **Semantic Purpose**: Emphasized status text
  - **Recommended Fix**: `HeadingSystem.getBodySmall(context).copyWith(fontWeight: FontWeight.bold)`

- **Line 223**: `fontSize: 12` - Additional status text
  - **Semantic Purpose**: Secondary status information
  - **Recommended Fix**: `HeadingSystem.getBodySmall(context)`

### 2. Core Library Screen (`lib/screens/core_library_screen.dart`)

#### Current Issues:
- **Line 507**: `fontSize: 8` - Small accent text
  - **Semantic Purpose**: Very small accent/badge text
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px) - closest available
  - **Note**: 8px is smaller than HeadingSystem minimum, consider if this is necessary

- **Line 1430**: `fontSize: 11` - Core color text
  - **Semantic Purpose**: Core metadata/description
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px) or `HeadingSystem.getBodySmall(context)` (12px)

### 3. Journal History Screen (`lib/screens/journal_history_screen.dart`)

#### Current Issues:
- **Line 165**: `fontSize: 12` - Delete button text
  - **Semantic Purpose**: Button text
  - **Recommended Fix**: `HeadingSystem.getLabelMedium(context)` (12px)

- **Line 220**: `fontSize: 8` - "Editable" badge
  - **Semantic Purpose**: Small status badge
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px)

- **Line 247**: `fontSize: 8` - "AI" badge
  - **Semantic Purpose**: Small status badge
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px)

- **Line 285**: `fontSize: 9` - Mood chip text
  - **Semantic Purpose**: Chip/tag text
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px)

- **Line 317**: `fontSize: 12` - "Tap to edit" text
  - **Semantic Purpose**: Instructional text
  - **Recommended Fix**: `HeadingSystem.getBodySmall(context)` (12px)

- **Line 392**: `fontSize: 12` - Mood text
  - **Semantic Purpose**: Mood display text
  - **Recommended Fix**: `HeadingSystem.getBodySmall(context)` (12px)

- **Line 475**: `fontSize: 10` - Emotion text
  - **Semantic Purpose**: Emotion chip text
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px)

- **Line 542**: `fontSize: 10` - Metadata text
  - **Semantic Purpose**: Entry metadata
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px)

- **Line 625**: `fontSize: 12` - Filter chip text
  - **Semantic Purpose**: Filter/chip text
  - **Recommended Fix**: `HeadingSystem.getLabelMedium(context)` (12px)

- **Line 655**: `fontSize: 12` - Date picker text
  - **Semantic Purpose**: Date display
  - **Recommended Fix**: `HeadingSystem.getBodySmall(context)` (12px)

- **Line 668**: `fontSize: 12` - Date picker text
  - **Semantic Purpose**: Date display
  - **Recommended Fix**: `HeadingSystem.getBodySmall(context)` (12px)

- **Line 798**: `fontSize: 12` - Warning text
  - **Semantic Purpose**: Warning/error message
  - **Recommended Fix**: `HeadingSystem.getBodySmall(context)` (12px)

- **Line 833**: `fontSize: 14` - Delete button text
  - **Semantic Purpose**: Button text
  - **Recommended Fix**: `HeadingSystem.getLabelLarge(context)` (14px)

### 4. Settings Screen (`lib/screens/settings_screen.dart`)

#### Current Issues:
- **Line 337**: `fontSize: 16` - Section title
  - **Semantic Purpose**: Section heading
  - **Recommended Fix**: `HeadingSystem.getHeadlineSmall(context)` (16px)

- **Line 426**: `fontSize: 16` - List item title
  - **Semantic Purpose**: Settings item title
  - **Recommended Fix**: `HeadingSystem.getTitleLarge(context)` (16px)

- **Line 434**: `fontSize: 14` - List item subtitle
  - **Semantic Purpose**: Settings item description
  - **Recommended Fix**: `HeadingSystem.getTitleMedium(context)` (14px)

- **Line 478**: `fontSize: 14` - Status text
  - **Semantic Purpose**: Setting status description
  - **Recommended Fix**: `HeadingSystem.getTitleMedium(context)` (14px)

- **Line 489**: `fontSize: 11` - Description text
  - **Semantic Purpose**: Detailed description
  - **Recommended Fix**: `HeadingSystem.getBodySmall(context)` (12px)

- **Line 511**: `fontSize: 16` - Theme title
  - **Semantic Purpose**: Settings item title
  - **Recommended Fix**: `HeadingSystem.getTitleLarge(context)` (16px)

- **Line 519**: `fontSize: 14` - Theme description
  - **Semantic Purpose**: Settings item description
  - **Recommended Fix**: `HeadingSystem.getTitleMedium(context)` (14px)

- **Line 942**: `fontSize: 16` - Option title
  - **Semantic Purpose**: Selection option title
  - **Recommended Fix**: `HeadingSystem.getTitleLarge(context)` (16px)

- **Line 952**: `fontSize: 14` - Option subtitle
  - **Semantic Purpose**: Selection option description
  - **Recommended Fix**: `HeadingSystem.getTitleMedium(context)` (14px)

### 5. Authentication Screen (`lib/screens/auth_screen.dart`)

#### Current Issues:
- **Line 589**: `fontSize: 14` - Error message
  - **Semantic Purpose**: Error text
  - **Recommended Fix**: `HeadingSystem.getTitleMedium(context)` (14px)

- **Line 612**: `fontSize: 16` - "Skip for now" button
  - **Semantic Purpose**: Button text
  - **Recommended Fix**: `HeadingSystem.getTitleLarge(context)` (16px)

- **Line 624**: `fontSize: 16` - "Reset Authentication" button
  - **Semantic Purpose**: Button text
  - **Recommended Fix**: `HeadingSystem.getTitleLarge(context)` (16px)

### 6. AI Settings Screen (`lib/screens/ai_settings_screen.dart`)

#### Current Issues:
- **Line 245**: `fontSize: 16` - "Development Mode Only" title
  - **Semantic Purpose**: Section title
  - **Recommended Fix**: `HeadingSystem.getHeadlineSmall(context)` (16px)

- **Line 253**: `fontSize: 14` - Description text
  - **Semantic Purpose**: Section description
  - **Recommended Fix**: `HeadingSystem.getTitleMedium(context)` (14px)

- **Line 289**: `fontSize: 16` - Status text
  - **Semantic Purpose**: Status display
  - **Recommended Fix**: `HeadingSystem.getTitleLarge(context)` (16px)

- **Line 353**: `fontSize: 14` - API key status
  - **Semantic Purpose**: Status description
  - **Recommended Fix**: `HeadingSystem.getTitleMedium(context)` (14px)

- **Line 449**: `fontSize: 14` - Warning text
  - **Semantic Purpose**: Warning message
  - **Recommended Fix**: `HeadingSystem.getTitleMedium(context)` (14px)

- **Line 478**: `fontSize: 14` - Error message
  - **Semantic Purpose**: Error text
  - **Recommended Fix**: `HeadingSystem.getTitleMedium(context)` (14px)

- **Line 506**: `fontSize: 14` - Success message
  - **Semantic Purpose**: Success text
  - **Recommended Fix**: `HeadingSystem.getTitleMedium(context)` (14px)

### 7. Emotional Mirror Screen (`lib/screens/emotional_mirror_screen.dart`)

#### Current Issues:
- **Line 227**: `fontSize: 12` - Tab text
  - **Semantic Purpose**: Tab label
  - **Recommended Fix**: `HeadingSystem.getLabelMedium(context)` (12px)

- **Line 239**: `fontSize: 12` - Tab text
  - **Semantic Purpose**: Tab label
  - **Recommended Fix**: `HeadingSystem.getLabelMedium(context)` (12px)

### 8. Main App (`lib/main.dart`)

#### Current Issues:
- **Line 398**: `fontSize: 16` - Error dialog text
  - **Semantic Purpose**: Error message
  - **Recommended Fix**: `HeadingSystem.getBodyLarge(context)` (16px)

- **Line 472**: `fontSize: 16` - "Continue Anyway" button
  - **Semantic Purpose**: Button text
  - **Recommended Fix**: `HeadingSystem.getTitleLarge(context)` (16px)

### 9. Widget Files

#### Your Cores Card (`lib/widgets/your_cores_card.dart`)
- **Line 763**: `fontSize: 11` - Trend percentage
  - **Semantic Purpose**: Small metric text
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px) or `HeadingSystem.getBodySmall(context)` (12px)

- **Line 893**: `fontSize: 10` - "Updated" badge
  - **Semantic Purpose**: Status badge
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px)

#### TestFlight Feedback Widget (`lib/widgets/testflight_feedback_widget.dart`)
- **Line 370**: `fontSize: 16` - Submit button text
  - **Semantic Purpose**: Button text
  - **Recommended Fix**: `HeadingSystem.getTitleLarge(context)` (16px)

#### Journal to Core Flow Animation (`lib/widgets/journal_to_core_flow_animation.dart`)
- **Line 386**: `fontSize: 10` - Core name
  - **Semantic Purpose**: Small label text
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px)

- **Line 397**: `fontSize: 10` - Impact percentage
  - **Semantic Purpose**: Small metric text
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px)

#### Offline Status Widget (`lib/widgets/offline_status_widget.dart`)
- **Line 438**: `fontSize: 10` - Status text
  - **Semantic Purpose**: Status indicator
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px)

#### Emotional Trend Chart (`lib/widgets/emotional_trend_chart.dart`)
- **Multiple instances**: `fontSize: 10` - Chart labels and axis text
  - **Semantic Purpose**: Chart metadata
  - **Recommended Fix**: `HeadingSystem.getLabelSmall(context)` (10px)

#### Mood Distribution Chart (`lib/widgets/mood_distribution_chart.dart`)
- **Line 342**: `fontSize: 24` - Chart title
  - **Semantic Purpose**: Chart heading
  - **Recommended Fix**: `HeadingSystem.getDisplaySmall(context)` (26px) - closest available

- **Line 363**: `fontSize: 12` - Chart subtitle
  - **Semantic Purpose**: Chart description
  - **Recommended Fix**: `HeadingSystem.getBodySmall(context)` (12px)

## Summary of Findings

### Font Size Distribution:
- **32px**: 1 usage (splash screen title) → `HeadingSystem.getDisplayMedium(context)`
- **24px**: 1 usage (chart title) → `HeadingSystem.getDisplaySmall(context)` (26px)
- **16px**: 8 usages (buttons, titles) → `HeadingSystem.getTitleLarge(context)` or `HeadingSystem.getBodyLarge(context)`
- **14px**: 9 usages (descriptions, subtitles) → `HeadingSystem.getTitleMedium(context)`
- **12px**: 12 usages (captions, metadata) → `HeadingSystem.getBodySmall(context)` or `HeadingSystem.getLabelMedium(context)`
- **11px**: 2 usages (small text) → `HeadingSystem.getBodySmall(context)` (12px)
- **10px**: 6 usages (very small text) → `HeadingSystem.getLabelSmall(context)`
- **9px**: 1 usage (mood chip) → `HeadingSystem.getLabelSmall(context)` (10px)
- **8px**: 2 usages (tiny badges) → `HeadingSystem.getLabelSmall(context)` (10px)

### Semantic Categories:
1. **App/Page Titles**: 32px → `HeadingSystem.getDisplayMedium()` or `HeadingSystem.pageHeading()`
2. **Section Headings**: 16px → `HeadingSystem.getHeadlineSmall()`
3. **Card/Component Titles**: 16px → `HeadingSystem.getTitleLarge()`
4. **Button Text**: 16px, 14px → `HeadingSystem.getTitleLarge()` or `HeadingSystem.getLabelLarge()`
5. **Descriptions/Subtitles**: 14px → `HeadingSystem.getTitleMedium()`
6. **Captions/Metadata**: 12px → `HeadingSystem.getBodySmall()`
7. **Tab Labels**: 12px → `HeadingSystem.getLabelMedium()`
8. **Chip/Badge Text**: 10px, 8px → `HeadingSystem.getLabelSmall()`
9. **Chart Labels**: 10px → `HeadingSystem.getLabelSmall()`

### Priority Areas for Refactoring:
1. **High Priority**: Splash screen (main app title and descriptions)
2. **High Priority**: Settings screen (multiple section titles and descriptions)
3. **Medium Priority**: Journal history screen (many small text elements)
4. **Medium Priority**: Authentication screen (button and error text)
5. **Low Priority**: Widget components (chart labels, badges)

## Next Steps
1. Start with splash screen refactoring (Task 2)
2. Move to core library screen (Task 3)
3. Continue with journal screen (Task 4)
4. Proceed through remaining screens systematically
5. Test each screen after refactoring to ensure visual hierarchy is maintained