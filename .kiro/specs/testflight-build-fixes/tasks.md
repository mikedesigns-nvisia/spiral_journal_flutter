# TestFlight Build Test Fixes - Implementation Plan

- [x] 1. Create test utility classes for service management
  - Implement TestServiceManager class with proper service lifecycle handling
  - Create TestWidgetHelper class for improved widget testing utilities
  - Add TestConfig class with appropriate timeout configurations
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Fix SettingsService disposal issues in tests
  - Update test setup to use proper Provider scoping for SettingsService
  - Add service validity checks before service access in tests
  - Implement proper service disposal in test teardown methods
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 3. Remove PIN authentication and simplify to biometrics-only
  - Remove PIN setup screens and related authentication flows
  - Update authentication to use only biometric authentication (Face ID/Touch ID)
  - Remove PIN-related tests that are causing widget finding failures
  - Update fresh install flow to skip PIN setup and go directly to biometric setup
  - _Requirements: 2.1, 2.2, 2.4_

- [x] 4. Fix theme switching integration test timeouts
  - Update theme_switching_integration_test.dart with proper async handling
  - Add appropriate timeouts for theme switching operations
  - Implement proper service cleanup to prevent disposal errors
  - _Requirements: 3.1, 3.2, 3.3, 1.1_

- [x] 5. Improve MaterialApp widget instantiation in tests
  - Fix MaterialApp widget finding issues in theme tests
  - Ensure proper widget tree initialization before assertions
  - Add retry logic for widget finding operations
  - _Requirements: 2.3, 2.4, 3.4_

- [x] 6. Implement proper test isolation and cleanup
  - Add comprehensive test cleanup procedures for all integration tests
  - Ensure service instances are properly isolated between tests
  - Implement resource cleanup even on test failures or timeouts
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 7. Update test configuration and timeouts
  - Configure appropriate timeouts for different types of tests
  - Add timeout monitoring and early termination for stuck tests
  - Implement progressive timeout strategies for complex operations
  - _Requirements: 3.1, 3.2, 3.4_

- [x] 8. Update authentication flow to biometrics-only
  - Update main authentication logic to use only biometric authentication
  - Remove PIN-related service classes and dependencies
  - Update settings to show only biometric authentication options
  - Simplify onboarding flow to focus on biometric setup
  - _Requirements: 2.1, 2.2, 4.2_

- [-] 9. Validate test fixes and run complete test suite
  - Run all previously failing tests to verify fixes
  - Ensure no regressions in passing tests
  - Validate that TestFlight build process completes successfully
  - _Requirements: 1.1, 2.1, 3.1, 4.1_