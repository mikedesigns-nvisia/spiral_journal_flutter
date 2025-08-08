# Implementation Plan

- [x] 1. Audit and document all manual fontSize usage across the app
  - Create comprehensive inventory of all screens with manual fontSize overrides
  - Document current font sizes and their semantic purposes
  - Map each usage to appropriate HeadingSystem method
  - _Requirements: 1.1, 2.2, 2.3_

- [x] 2. Refactor splash screen text styling
  - Replace manual fontSize: 32 with HeadingSystem.pageHeading()
  - Replace manual fontSize: 16 with HeadingSystem.getBodyLarge()
  - Replace manual fontSize: 12 with HeadingSystem.caption()
  - Test splash screen renders correctly with new styling
  - _Requirements: 1.1, 2.2, 3.1_

- [x] 3. Standardize core library screen headings
  - Replace Theme.of(context).textTheme usage with HeadingSystem methods
  - Fix manual fontSize: 8, 11 overrides with HeadingSystem.caption()
  - Ensure section headings use HeadingSystem.sectionHeading()
  - Test core library screen maintains visual hierarchy
  - _Requirements: 1.2, 1.3, 2.1, 3.2_

- [x] 4. Fix journal screen text inconsistencies
  - Replace manual fontSize in analysis results with HeadingSystem.caption()
  - Standardize mood selector text using HeadingSystem methods
  - Ensure journal input uses consistent text styling
  - Test journal screen functionality with new text styles
  - _Requirements: 1.1, 2.2, 3.1_

- [x] 5. Standardize settings screen text hierarchy
  - Replace AppTheme.getTextStyle(fontSize: X) calls with HeadingSystem methods
  - Use HeadingSystem.sectionHeading() for section titles
  - Apply HeadingSystem.listItemTitle() for settings items
  - Test settings screen maintains proper visual hierarchy
  - _Requirements: 1.2, 2.1, 2.4, 3.1_

- [x] 6. Refactor journal history screen text elements
  - Replace all manual fontSize overrides (12, 8, 9, 10) with appropriate HeadingSystem methods
  - Standardize mood chip text using HeadingSystem.getLabelSmall()
  - Apply consistent styling to entry metadata
  - Test journal history screen with various entry types
  - _Requirements: 1.4, 2.2, 3.2_

- [ ] 7. Fix profile setup screen text styling
  - Replace manual fontSize: 16, 14 with HeadingSystem methods
  - Standardize form field labels and error messages
  - Ensure button text follows theme standards
  - Test profile setup flow with new text styles
  - _Requirements: 1.1, 2.2, 3.1_

- [ ] 8. Standardize authentication screen text
  - Replace AppTheme.getTextStyle(fontSize: X) with HeadingSystem methods
  - Apply consistent error message styling
  - Standardize button and link text
  - Test authentication flow maintains usability
  - _Requirements: 1.1, 2.4, 3.1_

- [x] 9. Update emotional mirror screen headings
  - Ensure all slide titles use consistent HeadingSystem methods
  - Standardize chart labels and metadata text
  - Apply consistent styling to analysis cards
  - Test emotional mirror screen across all slides
  - _Requirements: 1.2, 1.3, 3.1, 3.2_

- [ ] 10. Validate text hierarchy across all screens
  - Verify screen titles are consistently sized
  - Check section headings maintain proper hierarchy
  - Ensure card titles and list items are uniform
  - Test visual hierarchy on different device sizes
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 11. Test accessibility compliance
  - Verify text scaling works with system accessibility settings
  - Test screen reader compatibility with standardized headings
  - Check color contrast ratios remain compliant
  - Validate touch targets meet accessibility guidelines
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 12. Perform visual regression testing
  - Take screenshots of all screens before and after changes
  - Compare visual hierarchy and spacing
  - Verify no unintended layout changes occurred
  - Test on multiple device sizes and orientations
  - _Requirements: 1.1, 1.2, 1.3, 3.1_

- [ ] 13. Update theme switching compatibility
  - Test all screens in light and dark themes
  - Verify HeadingSystem methods work correctly with theme changes
  - Check text color consistency across themes
  - Test theme switching maintains heading hierarchy
  - _Requirements: 2.1, 3.1, 3.2_

- [ ] 14. Create comprehensive test suite for text consistency
  - Write unit tests for HeadingSystem method usage
  - Create widget tests for each refactored screen
  - Add integration tests for text hierarchy validation
  - Test responsive text scaling behavior
  - _Requirements: 2.1, 3.4, 4.1_

- [ ] 15. Document standardized text usage patterns
  - Update development guidelines with HeadingSystem usage
  - Create examples of correct vs incorrect text styling
  - Document semantic meaning of each heading level
  - Provide migration guide for future text implementations
  - _Requirements: 2.1, 2.2, 2.3, 2.4_