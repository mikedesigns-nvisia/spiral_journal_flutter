# Requirements Document

## Introduction

The Spiral Journal app currently has inconsistent heading sizes across different screens due to mixed implementation approaches. Some screens use the standardized HeadingSystem, others use Theme.of(context).textTheme directly, and many override font sizes manually with `.copyWith(fontSize: X)` calls. This creates a poor user experience where similar UI elements have different sizes, breaking visual hierarchy and design consistency.

## Requirements

### Requirement 1

**User Story:** As a user, I want all app headings to have consistent sizes so that the interface feels cohesive and professional.

#### Acceptance Criteria

1. WHEN I navigate between different screens THEN all screen titles SHALL have the same font size
2. WHEN I view section headings across screens THEN they SHALL all use the same standardized size
3. WHEN I see card titles throughout the app THEN they SHALL maintain consistent sizing
4. WHEN I look at list item titles THEN they SHALL have uniform font sizes
5. WHEN I view button text THEN it SHALL follow the standardized text hierarchy

### Requirement 2

**User Story:** As a developer, I want a single source of truth for heading styles so that future development maintains consistency.

#### Acceptance Criteria

1. WHEN implementing new UI elements THEN developers SHALL use only HeadingSystem methods
2. WHEN existing code uses manual fontSize overrides THEN it SHALL be refactored to use HeadingSystem
3. WHEN Theme.of(context).textTheme is used directly THEN it SHALL be replaced with HeadingSystem equivalents
4. WHEN AppTheme.getTextStyle() is called with fontSize parameters THEN it SHALL use HeadingSystem instead

### Requirement 3

**User Story:** As a user, I want the text hierarchy to be clear and logical so that I can easily scan and understand the interface.

#### Acceptance Criteria

1. WHEN I view any screen THEN the visual hierarchy SHALL follow: Screen Title > Section Heading > Card Title > List Item Title > Body Text
2. WHEN similar UI elements appear on different screens THEN they SHALL use the same heading level
3. WHEN text serves the same semantic purpose THEN it SHALL have identical styling
4. WHEN viewing the app on different device sizes THEN the heading hierarchy SHALL remain consistent

### Requirement 4

**User Story:** As a user, I want the app to work well with accessibility features so that text scaling works properly.

#### Acceptance Criteria

1. WHEN I enable system text scaling THEN all headings SHALL scale proportionally
2. WHEN using VoiceOver or screen readers THEN heading levels SHALL be semantically correct
3. WHEN accessibility features are enabled THEN the visual hierarchy SHALL remain clear
4. WHEN text size is increased THEN the layout SHALL accommodate larger text gracefully