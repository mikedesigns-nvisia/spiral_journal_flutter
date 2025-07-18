# Requirements Document

## Introduction

This feature adds a branded splash screen to Spiral Journal that displays when the app launches. The splash screen will showcase the app's identity with the Spiral Journal branding while providing proper attribution to both the AI technology provider (Anthropic) and the creator (Mike). This creates a professional first impression and ensures proper crediting of key contributors.

## Requirements

### Requirement 1

**User Story:** As a user launching the app, I want to see a branded splash screen that introduces Spiral Journal, so that I understand what app I'm using and feel confident about its quality.

#### Acceptance Criteria

1. WHEN the app launches THEN the system SHALL display a splash screen before the main authentication screen
2. WHEN the splash screen is displayed THEN the system SHALL show the "Spiral Journal" app name prominently
3. WHEN the splash screen is displayed THEN the system SHALL use the app's established color scheme (warm oranges and cream backgrounds)
4. WHEN the splash screen is displayed THEN the system SHALL display for a minimum of 2 seconds to ensure visibility

### Requirement 2

**User Story:** As a user, I want to see proper attribution for the AI technology, so that I understand what powers the app's intelligent features.

#### Acceptance Criteria

1. WHEN the splash screen is displayed THEN the system SHALL show "Powered by Anthropic" text
2. WHEN the "Powered by Anthropic" text is displayed THEN the system SHALL use appropriate styling that is visible but not overpowering
3. WHEN the attribution is shown THEN the system SHALL position it in a way that doesn't interfere with the main branding

### Requirement 3

**User Story:** As a user, I want to see creator attribution, so that I know who built this app.

#### Acceptance Criteria

1. WHEN the splash screen is displayed THEN the system SHALL show "Made by Mike" text
2. WHEN the creator attribution is displayed THEN the system SHALL use consistent styling with other attribution text
3. WHEN both attributions are shown THEN the system SHALL position them harmoniously on the screen

### Requirement 4

**User Story:** As a user, I want the splash screen to transition smoothly to the main app, so that the experience feels polished and professional.

#### Acceptance Criteria

1. WHEN the splash screen display duration is complete THEN the system SHALL automatically transition to the authentication screen
2. WHEN the transition occurs THEN the system SHALL use a smooth animation or fade effect
3. WHEN the app is already authenticated THEN the system SHALL transition to the appropriate main screen after the splash
4. IF the user taps the splash screen THEN the system MAY allow early dismissal after a minimum display time