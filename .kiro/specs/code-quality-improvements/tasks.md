# Code Quality Improvements Implementation Plan

## Phase 1: Foundation and Constants (Low Risk)

- [x] 1. Create centralized constants system
  - Create `lib/constants/app_constants.dart` with UI, database, and validation constants
  - Create `lib/constants/validation_constants.dart` with mood and core validation data
  - Extract all magic numbers from existing code to appropriate constant classes
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 1.1 Replace magic numbers in database layer
  - Update `journal_dao.dart` to use `AppConstants.maxContentLength` instead of hardcoded 10000
  - Update `error_handler.dart` to use `AppConstants.maxHistorySize` instead of hardcoded 100
  - Update timeout values in `main.dart` to use `AppConstants.initializationTimeout`
  - _Requirements: 3.1, 3.5_

- [x] 1.2 Replace hardcoded validation strings
  - Update `journal_dao.dart` validation to use `ValidationConstants.validMoods`
  - Update `journal_service.dart` to use `ValidationConstants.validCoreNames`
  - Update test files to use centralized validation constants
  - _Requirements: 3.2, 3.5_

- [x] 2. Fix deprecated API usage
  - Replace all instances of `Colors.withValues(alpha: x)` with `Colors.withOpacity(x)`
  - Update `app_theme.dart` shadowColor definition to use `withOpacity`
  - Update any other deprecated API calls found in the codebase
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2.1 Verify deprecated API fixes
  - Run `flutter analyze` to ensure no deprecation warnings remain
  - Test all UI components to ensure visual consistency is maintained
  - Update any related documentation or comments
  - _Requirements: 1.4_

- [x] 3. Standardize theme usage across components
  - Update `main_screen.dart` to use `GoogleFonts.notoSansJp()` instead of hardcoded 'NotoSansJP'
  - Create helper methods in `AppTheme` for consistent font application
  - Audit all UI files for hardcoded font families and replace with theme-based approaches
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 3.1 Create theme helper methods
  - Add `AppTheme.getTextStyle()` method for consistent font styling
  - Add `AppTheme.getColorWithOpacity()` method for consistent color application
  - Add theme builder methods for common UI components
  - _Requirements: 2.1, 2.4_

- [x] 3.2 Update all UI components to use theme helpers
  - Update `main_screen.dart` bottom navigation styling
  - Update `mood_selector.dart` to use theme-based styling
  - Audit and update all other UI components for consistency
  - _Requirements: 2.2, 2.5_

## Phase 2: Architecture Refactoring (Medium Risk)

- [x] 4. Design authentication architecture components
  - Create `lib/services/authentication_manager.dart` interface and implementation
  - Create `lib/controllers/splash_screen_controller.dart` for splash logic
  - Create `lib/services/app_initializer.dart` for initialization orchestration
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 4.1 Implement AuthenticationManager
  - Extract authentication logic from `AuthWrapper` to `AuthenticationManager`
  - Implement `checkAuthenticationStatus()`, `isFirstLaunch()`, and `isAuthSystemHealthy()` methods
  - Add comprehensive error handling and logging
  - _Requirements: 4.2, 4.6_

- [x] 4.2 Implement SplashScreenController
  - Extract splash screen logic from `AuthWrapper` to `SplashScreenController`
  - Implement `shouldShowSplash()`, `onSplashComplete()`, and configuration methods
  - Maintain existing splash screen functionality
  - _Requirements: 4.3, 4.6_

- [x] 4.3 Implement AppInitializer
  - Extract initialization logic from `AuthWrapper` to `AppInitializer`
  - Implement `initialize()`, `verifySystemHealth()`, and error handling methods
  - Add timeout management and health check coordination
  - _Requirements: 4.4, 4.6_

- [x] 4.4 Refactor AuthWrapper to use new architecture
  - Simplify `AuthWrapper` to delegate to focused manager classes
  - Reduce state complexity from 10+ boolean flags to essential state only
  - Maintain existing user experience and functionality
  - _Requirements: 4.1, 4.5, 4.6, 4.7_

- [x] 5. Standardize error handling patterns
  - Create `lib/utils/error_handling_patterns.dart` with standard patterns
  - Implement `executeWithStandardErrorHandling()` method for consistent async operations
  - Implement `logError()` and `rethrowWithContext()` methods for consistent error management
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 5.1 Update service layer error handling
  - Update `journal_service.dart` to use standardized error patterns
  - Update `ai_service_manager.dart` to use consistent error handling
  - Update all other service classes to follow standard patterns
  - _Requirements: 5.1, 5.5_

- [x] 5.2 Update database layer error handling
  - Update `journal_dao.dart` to use standardized transaction error patterns
  - Ensure consistent logging and error context throughout database operations
  - Maintain existing transaction safety while improving consistency
  - _Requirements: 5.2, 5.5_

- [x] 6. Update database schema naming consistency
  - Create database migration script to rename snake_case fields to camelCase
  - Update `journal_dao.dart` field mappings to use camelCase consistently
  - Update all database queries and operations to use new field names
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 6.1 Implement database migration
  - Create migration script to update existing database schema
  - Test migration with sample data to ensure data preservation
  - Implement rollback capability for migration safety
  - _Requirements: 6.2, 6.4_

- [x] 6.2 Update DAO layer for new schema
  - Update all database field references in `journal_dao.dart`
  - Update `core_dao.dart` if affected by schema changes
  - Update database helper and initialization code
  - _Requirements: 6.3, 6.5_

## Phase 3: Documentation and Testing (Low Risk)

- [x] 7. Add comprehensive inline documentation
  - Add method documentation to all public APIs in service classes
  - Add class-level documentation explaining purpose and usage
  - Add complex algorithm documentation in database and AI service layers
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 7.1 Document refactored authentication components
  - Add comprehensive documentation to `AuthenticationManager` class
  - Document `SplashScreenController` and `AppInitializer` classes
  - Add usage examples and integration patterns
  - _Requirements: 7.1, 7.2, 7.5_

- [x] 7.2 Document constants and validation systems
  - Add documentation to all constant classes explaining usage and maintenance
  - Document validation patterns and how to extend them
  - Add examples of proper constant usage throughout the codebase
  - _Requirements: 7.2, 7.5_

- [-] 8. Create tests for refactored components
  - Create unit tests for `AuthenticationManager` class
  - Create unit tests for `SplashScreenController` class
  - Create unit tests for `AppInitializer` class
  - _Requirements: 8.1, 8.5_

- [ ] 8.1 Create tests for constants validation
  - Create unit tests validating all constant values and ranges
  - Create tests ensuring constants are used consistently throughout codebase
  - Add tests for validation logic using centralized constants
  - _Requirements: 8.2, 8.5_

- [x] 8.2 Create integration tests for refactored authentication flow
  - Create tests verifying complete authentication flow with new architecture
  - Test error scenarios and recovery patterns
  - Test initialization timeout and health check scenarios
  - _Requirements: 8.4, 8.5_

- [ ] 8.3 Update existing tests for standardized error handling
  - Update `error_handler_test.dart` to test new standardized patterns
  - Update `transaction_safety_test.dart` to use new constants and patterns
  - Ensure all existing tests pass with refactored code
  - _Requirements: 8.3, 8.5_

- [ ] 9. Comprehensive testing and validation
  - Run full test suite to ensure no regressions
  - Perform manual testing of all major user workflows
  - Validate performance benchmarks meet or exceed current levels
  - _Requirements: 8.5_

- [ ] 9.1 Performance validation
  - Measure app startup time before and after changes
  - Profile memory usage to ensure no increase from refactoring
  - Test database query performance with schema updates
  - _Requirements: 8.4_

- [ ] 9.2 User experience validation
  - Test complete user journeys (journal creation, history viewing, settings)
  - Verify all UI components render correctly with theme standardization
  - Test error scenarios to ensure user-friendly error handling
  - _Requirements: 8.4_

- [ ] 10. Final code review and cleanup
  - Remove any unused imports or dead code introduced during refactoring
  - Ensure all new code follows established project conventions
  - Update any remaining documentation or README files
  - _Requirements: All requirements final validation_