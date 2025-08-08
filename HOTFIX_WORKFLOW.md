# Spiral Journal Hotfix Workflow

## Current Status: TestFlight Accepted ✅

Your app has been accepted into TestFlight! Here's the structured workflow for handling the upcoming testing phases and hotfixes.

## Branch Strategy

### Main Branches
- `main` - Production-ready code, stable releases
- `release/v1.0.0-testflight` - Current TestFlight release branch
- `develop` - Integration branch for new features (future)

### Hotfix Branches
- `hotfix/v1.0.1-personal` - Your personal testing fixes
- `hotfix/v1.0.2-apple-review` - Apple team feedback fixes  
- `hotfix/v1.0.3-beta-users` - External TestFlight user fixes
- `hotfix/v1.0.4-appstore-prep` - Final App Store preparation

## Testing Phases

### Phase 1: Personal Testing (Current)
**Branch:** `hotfix/v1.0.1-personal`
**Tester:** You (whitelisted)
**Focus:** Core functionality, critical bugs, UX issues

**Workflow:**
```bash
git checkout -b hotfix/v1.0.1-personal release/v1.0.0-testflight
# Make fixes
git commit -m "hotfix: Fix critical issue X"
git push origin hotfix/v1.0.1-personal
# Build and upload to TestFlight
```

### Phase 2: Apple Review Team
**Branch:** `hotfix/v1.0.2-apple-review`  
**Testers:** Apple internal review team
**Focus:** App Store guidelines, technical compliance, security

**Workflow:**
```bash
git checkout -b hotfix/v1.0.2-apple-review hotfix/v1.0.1-personal
# Address Apple feedback
git commit -m "hotfix: Address Apple review feedback"
```

### Phase 3: Beta TestFlight Users
**Branch:** `hotfix/v1.0.3-beta-users`
**Testers:** External TestFlight beta users
**Focus:** Real-world usage, edge cases, device compatibility

### Phase 4: App Store Preparation
**Branch:** `hotfix/v1.0.4-appstore-prep`
**Focus:** Final polish, performance optimization, store assets

## Quick Commands

### Create Personal Hotfix
```bash
git checkout release/v1.0.0-testflight
git pull origin release/v1.0.0-testflight
git checkout -b hotfix/v1.0.1-personal
```

### Build and Deploy
```bash
# Test the fix
flutter test
flutter analyze

# Build for TestFlight
./ios/testflight_build.sh

# Commit and push
git add .
git commit -m "hotfix: [description]"
git push origin hotfix/v1.0.1-personal
```

### Merge Hotfix Back
```bash
# Merge to release branch
git checkout release/v1.0.0-testflight
git merge hotfix/v1.0.1-personal
git push origin release/v1.0.0-testflight

# Merge to main
git checkout main
git merge hotfix/v1.0.1-personal
git push origin main
```

## Version Numbering

- `v1.0.0` - Initial TestFlight release
- `v1.0.1` - Personal testing hotfix
- `v1.0.2` - Apple review hotfix
- `v1.0.3` - Beta user hotfix
- `v1.0.4` - App Store release candidate
- `v1.1.0` - First post-launch feature update

## Critical Files to Monitor

### Build Files
- `ios/Runner/Info.plist` - Version numbers, bundle info
- `pubspec.yaml` - App version, dependencies
- `ios/exportOptions.plist` - Distribution settings

### Core App Files
- `lib/main.dart` - App initialization
- `lib/screens/profile_setup_screen.dart` - Recently fixed syntax
- `lib/services/navigation_flow_controller.dart` - Flow management

### TestFlight Specific
- `lib/widgets/testflight_feedback_widget.dart` - Feedback collection
- `TESTFLIGHT_RELEASE_NOTES.md` - Release documentation

## Emergency Hotfix Process

If you discover a critical bug during testing:

1. **Immediate Fix**
   ```bash
   git checkout -b hotfix/emergency-fix release/v1.0.0-testflight
   # Fix the issue
   git commit -m "hotfix: CRITICAL - Fix [issue]"
   git push origin hotfix/emergency-fix
   ```

2. **Fast Track Build**
   ```bash
   ./ios/testflight_build.sh
   # Upload to TestFlight immediately
   ```

3. **Merge Back**
   ```bash
   git checkout release/v1.0.0-testflight
   git merge hotfix/emergency-fix
   git push origin release/v1.0.0-testflight
   ```

## Next Steps

1. **Start Personal Testing** - Use the app extensively, document any issues
2. **Create First Hotfix Branch** - When you find issues
3. **Iterate Quickly** - Fast feedback loop for personal testing
4. **Prepare for Apple Review** - Clean up code, add comments, ensure compliance

## Success Metrics

- **Personal Phase:** App works smoothly for core journaling workflow
- **Apple Phase:** Passes all App Store review guidelines  
- **Beta Phase:** Positive user feedback, no critical crashes
- **Store Phase:** Ready for public release

---

**Current Branch:** `release/v1.0.0-testflight`
**Next Action:** Begin personal testing and create hotfix branch when needed
**Goal:** Smooth progression through all testing phases to App Store release
