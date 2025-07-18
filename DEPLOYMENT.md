# Spiral Journal - Deployment Guide

This document provides comprehensive instructions for deploying Spiral Journal to TestFlight and eventually to the App Store.

## Prerequisites

- macOS with Xcode 14.0 or later
- Flutter SDK 3.0.0 or later
- Apple Developer Program membership
- App Store Connect access
- Provisioning profiles and certificates set up

## TestFlight Deployment Process

### 1. Pre-Deployment Checklist

- [ ] All critical bugs fixed
- [ ] All tests passing
- [ ] App icon and launch screen properly configured
- [ ] Info.plist properly configured with required permissions
- [ ] Privacy policy URL added to App Store Connect
- [ ] App Store screenshots prepared
- [ ] App Store description and metadata prepared
- [ ] Version number and build number updated

### 2. Update Version Numbers

Update the version number in `pubspec.yaml`:

```yaml
version: 1.0.0+1  # Format: version_number+build_number
```

### 3. Run Final Tests

```bash
flutter test
```

### 4. Build and Upload to TestFlight

#### Option 1: Using the Automated Script (Recommended)

The automated script now supports secure credential management. You have several options:

**Using Environment Variables (Most Secure):**
```bash
cd ios
./testflight_build.sh
```
This will automatically load credentials from the `.env` file in the project root.

**Using Command Line Parameters:**
```bash
cd ios
./testflight_build.sh -u mikejarce@icloud.com -p zwzf-esze-fjzc-aayt
```

**Using Environment Variables Directly:**
```bash
APPLE_ID=mikejarce@icloud.com APP_SPECIFIC_PASSWORD=zwzf-esze-fjzc-aayt cd ios && ./testflight_build.sh
```

**Getting Help:**
```bash
cd ios
./testflight_build.sh --help
```

#### Option 2: Manual Process
### 4. Credential Setup

Before using the automated script, ensure your Apple Developer credentials are properly configured:

1. **Create App-Specific Password:**
   - Go to [appleid.apple.com](https://appleid.apple.com)
   - Sign in with your Apple ID
   - Navigate to "Security" section
   - Under "App-Specific Passwords", click "Generate Password"
   - Label it "TestFlight Upload" or similar
   - Copy the generated password (format: `abcd-efgh-ijkl-mnop`)

2. **Configure Credentials:**
   The project includes a `.env` file with your credentials already configured:
   ```
   APPLE_ID=mikejarce@icloud.com
   APP_SPECIFIC_PASSWORD=zwzf-esze-fjzc-aayt
   TEAM_ID=3PH38QP73Z
   ```

   **Security Note:** The `.env` file is automatically excluded from version control via `.gitignore`.

### 5. Build and Upload to TestFlight

#### Option 1: Using the Automated Script (Recommended)

The automated script now supports secure credential management. You have several options:

**Using Environment Variables (Most Secure):**
```bash
cd ios
./testflight_build.sh
```
This will automatically load credentials from the `.env` file in the project root.

**Using Command Line Parameters:**
```bash
cd ios
./testflight_build.sh -u mikejarce@icloud.com -p zwzf-esze-fjzc-aayt
```

**Using Environment Variables Directly:**
```bash
APPLE_ID=mikejarce@icloud.com APP_SPECIFIC_PASSWORD=zwzf-esze-fjzc-aayt cd ios && ./testflight_build.sh
```

**Getting Help:**
```bash
cd ios
./testflight_build.sh --help
```

#### Option 2: Manual Process

1. Clean the project:
```bash
flutter clean
```

2. Get dependencies:
```bash
flutter pub get
```

3. Build the iOS app:
```bash
flutter build ios --release --no-codesign
```

4. Open the Xcode workspace:
```bash
open ios/Runner.xcworkspace
```

5. In Xcode:
   - Select the "Runner" project
   - Select "Generic iOS Device" as the build target
   - Select Product > Archive
   - Once archiving is complete, click "Distribute App"
   - Select "App Store Connect" and follow the prompts
   - Click "Upload" to send the build to App Store Connect

### 5. Configure TestFlight Groups

#### Option 1: Using the Automated Script

```bash
cd ios
./configure_testflight_groups.sh
```

#### Option 2: Manual Process in App Store Connect

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app
3. Go to the "TestFlight" tab
4. Create testing groups:
   - Core Team (internal testers)
   - Feature Testers
   - UX Testers
   - Performance Testers
   - Security Testers
5. Add testers to each group
6. Configure build access for each group

### 6. Prepare TestFlight Release Notes

Create release notes in App Store Connect or use the prepared notes from `TESTFLIGHT_RELEASE_NOTES.md`.

### 7. Distribute to Testers

1. Wait for the build to finish processing in App Store Connect
2. Enable the build for testing
3. Add build to testing groups
4. Send invitations to testers

## App Store Deployment Process

Once TestFlight testing is complete and you're ready to release to the App Store:

### 1. Final Pre-Release Checklist

- [ ] All TestFlight feedback addressed
- [ ] Final version number set
- [ ] App Store screenshots updated
- [ ] App Store description and metadata finalized
- [ ] Privacy policy URL confirmed
- [ ] App Review Information completed
- [ ] Price and availability set
- [ ] In-app purchases configured (if applicable)

### 2. Submit for Review

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app
3. Go to the "App Store" tab
4. Complete all required metadata
5. Select the build to submit
6. Click "Submit for Review"

### 3. Monitor Review Status

Monitor the review status in App Store Connect. The review process typically takes 1-3 days.

### 4. Respond to Reviewer Questions

Be prepared to respond quickly to any questions from the App Review team.

### 5. Release the App

Once approved, you can release the app immediately or schedule a release date.

## Post-Release Tasks

- Monitor crash reports in Firebase Crashlytics
- Track user analytics in Firebase Analytics
- Collect and analyze user feedback
- Plan for updates based on user feedback and analytics

## Troubleshooting

### Common TestFlight Issues

- **Processing Never Completes**: Check that your app meets all requirements and doesn't use private APIs
- **Missing Compliance**: Complete the export compliance questions in App Store Connect
- **Beta App Review Rejection**: Address the specific issues mentioned in the rejection email

### Common App Store Review Issues

- **Metadata Rejection**: Update screenshots, description, or other metadata as requested
- **Functionality Issues**: Fix any functionality issues identified by the review team
- **Guideline Violations**: Address any App Store guideline violations

## Contact Information

For deployment assistance, contact:

- Technical Lead: [tech-lead@spiraljournal.com](mailto:tech-lead@spiraljournal.com)
- App Store Manager: [appstore@spiraljournal.com](mailto:appstore@spiraljournal.com)
