# Spiral Journal Hotfix Workflow

## Current Release Status
- ✅ **TestFlight Accepted**: App is live in TestFlight
- 👤 **Current Tester**: Single whitelisted tester (you)
- 🎯 **Next Steps**: Hotfix → Beta → Public TestFlight → App Store

## Branch Strategy

### Main Branches
- `main` - Production-ready code
- `develop` - Integration branch for features
- `ios-testflight-build` - Current TestFlight version

### Hotfix Branches
- `hotfix/v1.0.1-personal` - Personal hotfix for single tester
- `hotfix/v1.0.2-beta` - Beta hotfix for Apple team review
- `hotfix/v1.0.3-testflight` - Public TestFlight hotfix
- `hotfix/v1.0.4-appstore` - App Store release hotfix

## Hotfix Process

### 1. Personal Hotfix (Current Phase)
```bash
# Create hotfix branch from current TestFlight build
git checkout ios-testflight-build
git checkout -b hotfix/v1.0.1-personal

# Make fixes
# Test locally
# Build and upload to TestFlight

# Merge back to main when stable
git checkout main
git merge hotfix/v1.0.1-personal
git tag v1.0.1
```

### 2. Beta Hotfix (Apple Team Review)
```bash
git checkout main
git checkout -b hotfix/v1.0.2-beta

# Address Apple team feedback
# Build and upload to TestFlight
# Tag when approved
git tag v1.0.2
```

### 3. Public TestFlight Hotfix
```bash
git checkout main
git checkout -b hotfix/v1.0.3-testflight

# Address user feedback from expanded testing
# Build and upload to TestFlight
git tag v1.0.3
```

### 4. App Store Release Hotfix
```bash
git checkout main
git checkout -b hotfix/v1.0.4-appstore

# Final fixes before App Store submission
# Build and submit to App Store
git tag v1.0.4
```

## Version Numbering
- **Personal**: 1.0.1, 1.0.2, 1.0.3...
- **Beta**: 1.1.0, 1.1.1, 1.1.2...
- **TestFlight**: 1.2.0, 1.2.1, 1.2.2...
- **App Store**: 2.0.0

## Build Commands

### Quick Hotfix Build
```bash
# Clean and build
flutter clean
flutter pub get
flutter build ios --release

# Archive and export (from ios directory)
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -destination generic/platform=iOS -archivePath build/Runner.xcarchive archive
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportOptionsPlist exportOptions.plist -exportPath build/ios
```

### TestFlight Upload
```bash
# Use your existing script
./ios/testflight_build.sh -u your-apple-id -p your-app-password
```

## Critical Files to Monitor
- `lib/screens/profile_setup_screen.dart` - Recently fixed syntax error
- `ios/exportOptions.plist` - Export configuration
- `pubspec.yaml` - Version numbers
- `ios/Runner/Info.plist` - App metadata

## Testing Checklist for Each Hotfix
- [ ] App launches without crashes
- [ ] Profile setup flow works
- [ ] Journal entry creation/editing
- [ ] Navigation between screens
- [ ] Data persistence
- [ ] Claude AI integration (if applicable)
- [ ] Fresh install experience

## Emergency Hotfix Process
If critical bug found in TestFlight:
1. Create hotfix branch immediately
2. Fix the specific issue only
3. Test thoroughly
4. Build and upload same day
5. Notify Apple if needed

## Communication
- Document all issues found in GitHub issues
- Tag releases with detailed release notes
- Keep TestFlight release notes updated
- Maintain changelog for App Store submission