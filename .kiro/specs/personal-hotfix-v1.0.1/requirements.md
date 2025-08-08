# Personal Hotfix v1.0.1 Requirements

## Overview
Critical UX fixes for personal TestFlight testing phase. These issues are blocking core app functionality and user experience.

## Priority: CRITICAL - Personal Testing Blockers

## Requirements

### Requirement 1: Fix Onboarding Loop Issue

**User Story:** As a returning user, I want the app to remember that I've completed onboarding, so that I don't have to go through the slides and profile setup every time I restart the app.

#### Acceptance Criteria
1. WHEN a user completes the onboarding flow THEN the app SHALL persist the completion state
2. WHEN a user restarts the app after completing onboarding THEN the app SHALL navigate directly to the main journal screen
3. WHEN the onboarding completion state is saved THEN it SHALL survive app kills and device restarts
4. IF the user has existing journal entries THEN the app SHALL recognize them as an existing user
5. WHEN checking onboarding status THEN the app SHALL use a reliable persistence mechanism (SharedPreferences/UserDefaults)

### Requirement 2: Fix Keyboard Dismissal Issue

**User Story:** As a user writing journal entries, I want to be able to dismiss the keyboard easily, so that I can navigate the app without the keyboard blocking the interface.

#### Acceptance Criteria
1. WHEN a user taps outside the text input area THEN the keyboard SHALL dismiss automatically
2. WHEN a user swipes down on the text input area THEN the keyboard SHALL dismiss
3. WHEN a user taps a "Done" or "Return" button THEN the keyboard SHALL dismiss appropriately
4. WHEN the keyboard is open THEN there SHALL be a clear way to close it
5. WHEN navigating between screens THEN the keyboard SHALL not persist inappropriately

### Requirement 3: Fix AI Commentary Update Issue

**User Story:** As a user who has written journal entries, I want to see the personalized AI commentary appear in my journal history after analysis, so that I can benefit from the AI insights feature.

#### Acceptance Criteria
1. WHEN a journal entry is analyzed by Claude API THEN the AI commentary SHALL be saved to the database
2. WHEN viewing journal history THEN entries with AI commentary SHALL display the analysis
3. WHEN AI analysis completes THEN the journal history view SHALL refresh to show new commentary
4. IF AI analysis fails THEN the app SHALL retry or show appropriate error handling
5. WHEN AI commentary is available THEN it SHALL be visually distinct from the original journal entry

## Technical Investigation Areas

### Onboarding Loop
- Check `NavigationFlowController` state persistence
- Verify `SharedPreferences` or equivalent storage
- Review app initialization logic in `main.dart`
- Examine `SplashScreen` routing logic

### Keyboard Issues
- Review `TextField` and `TextFormField` configurations
- Check for missing `GestureDetector` for tap-to-dismiss
- Verify keyboard action buttons (Done, Return)
- Review focus management

### AI Commentary
- Check Claude API integration and response handling
- Verify database schema for AI commentary storage
- Review journal history data loading
- Check for UI refresh after AI analysis completion

## Success Criteria
- App remembers onboarding completion across restarts
- Keyboard can be dismissed reliably in all text input scenarios
- AI commentary appears in journal history after analysis
- No regressions in existing functionality
- Smooth user experience for core journaling workflow

## Out of Scope
- New features or enhancements
- Performance optimizations beyond fixing the bugs
- UI/UX improvements beyond fixing the specific issues
- Additional AI analysis features