# Spiral Journal - TestFlight Release Notes

## Version 1.0.1 (Build 5) - Hotfix Release

**Critical Bug Fixes - January 22, 2025**

This hotfix release addresses three critical user experience issues reported by beta testers:

### 🔧 Fixed Issues

1. **Onboarding Loop Fix** ⭐ **CRITICAL**
   - Fixed issue where users would get stuck in onboarding loop after app termination
   - Enhanced state persistence and atomic checking for onboarding completion
   - Added better debugging and error handling for navigation flow

2. **Keyboard Dismissal Fix** ⭐ **HIGH PRIORITY**
   - Fixed keyboard persistence issues in journal entry text flow
   - Added multiple dismissal methods:
     - Tap outside text field to dismiss keyboard
     - "Done" button on keyboard now properly dismisses
     - Tap-to-dismiss functionality throughout journal screen
   - Improved overall text input experience

3. **AI Commentary Visibility Fix** ⭐ **HIGH PRIORITY**
   - Fixed issue where AI analysis results were not appearing in journal history
   - Enhanced background AI processing with proper UI updates
   - Users can now see when AI analysis is complete and view insights
   - Added visual feedback for AI processing status

### 🎯 Testing Focus for This Build

**Please specifically test these areas:**

1. **Onboarding Persistence**
   - Complete onboarding, then force-quit the app (swipe up and close)
   - Reopen the app - you should go directly to the main screen, NOT back to onboarding
   - Test with fresh app install and existing users

2. **Keyboard Behavior in Journal Entry**
   - Open journal entry screen and start typing
   - Try tapping outside the text field - keyboard should dismiss
   - Try pressing "Done" on keyboard - should dismiss properly
   - Ensure keyboard doesn't persist when navigating between screens

3. **AI Analysis Visibility**
   - Create a new journal entry with some emotional content
   - Save the entry and check journal history
   - Look for AI analysis results/insights appearing in your entries
   - Verify you can see when AI processing is happening

### 📱 How to Test the Fixes

1. **For Onboarding**: Delete and reinstall the app, complete onboarding, force-quit, reopen
2. **For Keyboard**: Focus on the journal writing experience and text input areas
3. **For AI Commentary**: Create entries and check if analysis appears in history view

### Known Issues (Still Present)
- Biometric authentication may not work consistently on some devices
- Search functionality may be slower with very large journal collections

---

## Version 1.0.0 (Build 2)

Thank you for joining the Spiral Journal beta testing program! This TestFlight build includes improvements and bug fixes based on initial testing feedback, with all core functionality implemented for local journaling with AI-powered insights.

### What's New in Build 2

- Improved test coverage and stability
- Enhanced error handling and crash recovery
- Performance optimizations for AI analysis
- Better theme switching reliability
- Refined UI responsiveness across device sizes

### What to Test

1. **PIN Authentication**
   - Setting up a PIN during first launch
   - Using PIN to access the app on subsequent launches
   - Biometric authentication (if your device supports it)
   - PIN reset functionality

2. **Journal Writing**
   - Creating new journal entries
   - Saving entries and viewing them in history
   - Auto-save functionality during writing
   - Crash recovery for unsaved drafts

3. **AI Analysis**
   - Emotional analysis of journal entries
   - Core evolution based on journal content
   - Personalized insights in the emotional mirror
   - AI analysis performance and accuracy

4. **Theme System**
   - Switching between light and dark themes
   - Theme consistency across all screens
   - Automatic system theme detection
   - Theme persistence across app restarts

5. **Data Management**
   - Searching and filtering journal entries
   - Data export functionality
   - Privacy dashboard and data controls
   - Secure data deletion

6. **Performance**
   - App launch time
   - Responsiveness during journal writing
   - Navigation between screens
   - Performance with large journal collections

### Known Issues

- Biometric authentication may not work consistently on some devices
- AI analysis may take longer than expected on first use
- Some UI elements may not be perfectly aligned on certain device sizes
- Search functionality may be slower with very large journal collections

### Feedback Focus Areas

We're particularly interested in your feedback on:

1. **User Experience**
   - Is the journaling flow intuitive and enjoyable?
   - Are the AI insights helpful and meaningful?
   - Is the PIN authentication process smooth?

2. **Performance**
   - Does the app feel responsive and fast?
   - Are there any noticeable lags or freezes?
   - How is battery consumption during use?

3. **Stability**
   - Does the app crash or behave unexpectedly?
   - Are there any data loss issues?
   - Does the app recover properly from background/foreground transitions?

4. **Visual Design**
   - How does the app look in both light and dark themes?
   - Are text and UI elements properly sized and readable?
   - Does the app feel polished and professional?

### How to Provide Feedback

- Use the built-in TestFlight feedback tool by taking a screenshot
- Use the in-app feedback form in the Settings screen
- Email us directly at beta@spiraljournal.com

Thank you for helping us improve Spiral Journal! Your feedback is invaluable as we prepare for public release.
