#!/bin/bash

# Verify App Store Connect Setup Script
# This script helps diagnose and fix TestFlight upload issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APPLE_ID="mikejarce@icloud.com"
APP_SPECIFIC_PASSWORD="zwzf-esze-fjzc-aayt"
BUNDLE_ID="com.mikearce.spiralJournal"
TEAM_ID="3PH38QP73Z"

echo -e "${BLUE}🔍 Verifying App Store Connect Setup${NC}"
echo "=================================================="

# Function to print status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Verify credentials are set
print_status "Step 1: Verifying credentials..."
if [[ -z "$APPLE_ID" || -z "$APP_SPECIFIC_PASSWORD" ]]; then
    print_error "Apple ID or app-specific password not set"
    exit 1
fi
print_success "Credentials configured"

# Step 2: Check if altool is available
print_status "Step 2: Checking altool availability..."
if ! command -v xcrun &> /dev/null; then
    print_error "Xcode command line tools not installed"
    echo "Install with: xcode-select --install"
    exit 1
fi
print_success "Xcode command line tools available"

# Step 3: Verify Apple ID authentication
print_status "Step 3: Testing Apple ID authentication..."
if xcrun altool --list-providers -u "$APPLE_ID" -p "$APP_SPECIFIC_PASSWORD" &> /dev/null; then
    print_success "Apple ID authentication successful"
    
    # Show available providers/teams
    echo -e "${BLUE}Available teams:${NC}"
    xcrun altool --list-providers -u "$APPLE_ID" -p "$APP_SPECIFIC_PASSWORD" 2>/dev/null || true
else
    print_error "Apple ID authentication failed"
    echo "Please verify:"
    echo "1. Apple ID: $APPLE_ID"
    echo "2. App-specific password: $APP_SPECIFIC_PASSWORD"
    echo "3. Generate new app-specific password at: https://appleid.apple.com/"
    exit 1
fi

# Step 4: List existing apps
print_status "Step 4: Checking existing apps in App Store Connect..."
echo -e "${BLUE}Existing apps:${NC}"
if xcrun altool --list-apps -u "$APPLE_ID" -p "$APP_SPECIFIC_PASSWORD" 2>/dev/null; then
    print_success "Successfully retrieved app list"
else
    print_warning "Could not retrieve app list (this might be normal for new accounts)"
fi

# Step 5: Check current bundle ID in project
print_status "Step 5: Verifying current bundle ID in project..."
CURRENT_BUNDLE_ID=$(grep -A1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | grep -o "com\.[^;]*" | head -1)
if [[ "$CURRENT_BUNDLE_ID" == "$BUNDLE_ID" ]]; then
    print_success "Bundle ID matches: $BUNDLE_ID"
else
    print_warning "Bundle ID mismatch!"
    echo "Expected: $BUNDLE_ID"
    echo "Found: $CURRENT_BUNDLE_ID"
fi

# Step 6: Check if IPA file exists
print_status "Step 6: Checking for existing IPA file..."
IPA_PATH="build/ios/spiral_journal.ipa"
if [[ -f "$IPA_PATH" ]]; then
    print_success "IPA file found: $IPA_PATH"
    echo "File size: $(du -h "$IPA_PATH" | cut -f1)"
    echo "Created: $(stat -f "%Sm" "$IPA_PATH")"
else
    print_warning "IPA file not found: $IPA_PATH"
    echo "You may need to build the app first"
fi

echo ""
echo "=================================================="
echo -e "${BLUE}📋 DIAGNOSIS SUMMARY${NC}"
echo "=================================================="

# Provide recommendations
if xcrun altool --list-apps -u "$APPLE_ID" -p "$APP_SPECIFIC_PASSWORD" 2>/dev/null | grep -q "$BUNDLE_ID"; then
    print_success "✅ App exists in App Store Connect"
    echo -e "${GREEN}READY TO UPLOAD!${NC}"
    echo ""
    echo "Run this command to upload:"
    echo "cd ios && ./quick_upload.sh"
else
    print_error "❌ App NOT found in App Store Connect"
    echo ""
    echo -e "${YELLOW}REQUIRED ACTIONS:${NC}"
    echo "1. Go to: https://appstoreconnect.apple.com/"
    echo "2. Sign in with: $APPLE_ID"
    echo "3. Click 'My Apps' → '+' → 'New App'"
    echo "4. Use these details:"
    echo "   - Name: Spiral Journal"
    echo "   - Bundle ID: $BUNDLE_ID"
    echo "   - SKU: spiral-journal-ios"
    echo "5. Complete the app setup"
    echo "6. Then retry the upload"
fi

echo ""
echo "=================================================="
echo -e "${BLUE}🔗 HELPFUL LINKS${NC}"
echo "=================================================="
echo "• App Store Connect: https://appstoreconnect.apple.com/"
echo "• Apple Developer: https://developer.apple.com/account/"
echo "• Generate App Password: https://appleid.apple.com/"
echo "• TestFlight Guide: https://developer.apple.com/testflight/"

echo ""
echo -e "${BLUE}📞 SUPPORT${NC}"
echo "If you need help, check the detailed guide:"
echo "cat TESTFLIGHT_BUNDLE_ID_FIX.md"
