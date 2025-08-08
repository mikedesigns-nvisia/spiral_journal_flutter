# Requirements Document

## Introduction

The Core Library feature in Spiral Journal is not receiving data from journal entries, preventing users from seeing their emotional core progress. Additionally, the icon colors need to be modeled in the same way as the emotional mirror UI for consistency. This feature will fix these issues to ensure the Core Library properly displays emotional core data derived from journal entries.

## Requirements

### Requirement 1

**User Story:** As a user, I want my journal entries to properly update my emotional cores in the Core Library, so that I can track my emotional growth over time.

#### Acceptance Criteria

1. WHEN a user writes a journal entry THEN the system SHALL analyze the entry and update the relevant emotional cores
2. WHEN a user views the Core Library THEN the system SHALL display accurate core data based on their journal entries
3. WHEN the journal analysis service processes entries THEN the system SHALL properly store updated core data in SharedPreferences
4. WHEN the Core Library service loads cores THEN the system SHALL retrieve the most recent core data
5. IF no journal entries exist THEN the system SHALL display default initial core values

### Requirement 2

**User Story:** As a user, I want the Core Library icons to use the same color scheme as the emotional mirror UI, so that the app has a consistent visual design.

#### Acceptance Criteria

1. WHEN a user views the Core Library THEN the system SHALL display core icons with colors matching the emotional mirror UI
2. WHEN displaying core progress circles THEN the system SHALL use the same color model as other parts of the app
3. WHEN rendering core cards THEN the system SHALL apply consistent color opacity and styling
4. IF a core has a custom color defined THEN the system SHALL properly parse and apply that color
5. WHEN displaying core details THEN the system SHALL maintain color consistency throughout the UI