# Claude AI Integration Debugging Requirements

## Introduction

The Claude API is working perfectly at the infrastructure level (all diagnostic tests pass), but the Flutter app is not successfully using Claude AI in production. This spec addresses the gap between the working API and the Flutter app integration.

## Requirements

### Requirement 1: Flutter Service Initialization Debugging

**User Story:** As a developer, I want to identify why the Flutter app's AI services aren't initializing properly, so that Claude AI analysis works in the production app.

#### Acceptance Criteria

1. WHEN the app starts THEN the AIServiceManager SHALL properly initialize with the Claude API key
2. WHEN the app loads the .env file THEN the CLAUDE_API_KEY SHALL be accessible to Flutter services
3. WHEN AIServiceManager.initialize() is called THEN it SHALL successfully configure the ClaudeAIProvider
4. WHEN the app attempts to use AI analysis THEN it SHALL not fall back to FallbackProvider unnecessarily
5. IF initialization fails THEN the app SHALL log specific error messages for debugging

### Requirement 2: Production Environment Configuration

**User Story:** As a developer, I want to ensure the production Flutter build properly loads environment variables, so that the Claude API key is available at runtime.

#### Acceptance Criteria

1. WHEN the Flutter app builds for production THEN the .env file SHALL be properly bundled
2. WHEN EnvironmentConfig.claudeApiKey is accessed THEN it SHALL return the valid API key
3. WHEN the app runs in production mode THEN environment variables SHALL be loaded correctly
4. WHEN DevConfigService checks for dev mode THEN it SHALL correctly identify production vs development
5. IF environment loading fails THEN the app SHALL provide clear error messages

### Requirement 3: Service Integration Flow Debugging

**User Story:** As a developer, I want to trace the complete flow from journal entry creation to AI analysis, so that I can identify where the integration breaks.

#### Acceptance Criteria

1. WHEN a user creates a journal entry THEN the JournalService SHALL attempt AI analysis
2. WHEN JournalService calls AIServiceManager.analyzeJournalEntry THEN it SHALL use the ClaudeAIProvider
3. WHEN ClaudeAIProvider makes an API call THEN it SHALL use the correct API key and headers
4. WHEN the API returns a response THEN the app SHALL properly parse and store the analysis
5. IF any step fails THEN the app SHALL log the specific failure point and reason

### Requirement 4: Error Handling and Fallback Behavior

**User Story:** As a user, I want to understand when AI analysis is unavailable, so that I know whether my entries are being analyzed by Claude or using basic analysis.

#### Acceptance Criteria

1. WHEN Claude AI is unavailable THEN the app SHALL clearly indicate fallback mode to the user
2. WHEN using FallbackProvider THEN the app SHALL still provide meaningful analysis
3. WHEN AI analysis fails THEN the app SHALL retry appropriately before falling back
4. WHEN network issues occur THEN the app SHALL queue analysis for later processing
5. IF the user has no API key THEN the app SHALL gracefully handle this scenario

### Requirement 5: Production Debugging Tools

**User Story:** As a developer, I want debugging tools that work in production builds, so that I can diagnose issues without development mode.

#### Acceptance Criteria

1. WHEN the app encounters AI service issues THEN it SHALL log detailed information for debugging
2. WHEN running diagnostic commands THEN they SHALL work with production builds
3. WHEN checking service status THEN the app SHALL provide clear status indicators
4. WHEN troubleshooting THEN developers SHALL have access to relevant error logs
5. IF issues persist THEN the app SHALL provide actionable troubleshooting steps

### Requirement 6: Integration Testing and Validation

**User Story:** As a developer, I want comprehensive tests that validate the complete Claude AI integration, so that I can verify the fix works end-to-end.

#### Acceptance Criteria

1. WHEN running integration tests THEN they SHALL test the complete journal-to-analysis flow
2. WHEN testing with real API keys THEN the tests SHALL validate actual Claude API integration
3. WHEN testing error scenarios THEN the tests SHALL verify proper fallback behavior
4. WHEN testing production builds THEN the tests SHALL work with compiled Flutter apps
5. IF tests fail THEN they SHALL provide specific information about what broke