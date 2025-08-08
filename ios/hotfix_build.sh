#!/bin/bash

# Hotfix Build Script for Spiral Journal
# Quick build and TestFlight upload for hotfixes

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Get current branch and version
CURRENT_BRANCH=$(git branch --show-current)
VERSION=$(grep "version:" ../pubspec.yaml | cut -d' ' -f2)

print_status "Building hotfix from branch: $CURRENT_BRANCH"
print_status "Version: $VERSION"

# Confirm this is a hotfix branch
if [[ ! "$CURRENT_BRANCH" =~ ^hotfix/ ]]; then
    print_error "Not on a hotfix branch! Current branch: $CURRENT_BRANCH"
    print_warning "Switch to a hotfix branch first: git checkout hotfix/v1.0.1-personal"
    exit 1
fi

# Navigate to project root
cd "$(dirname "$0")/.."

# Clean and prepare
print_status "Cleaning project..."
flutter clean
rm -rf build/
rm -rf ios/build/

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Build iOS
print_status "Building iOS release..."
flutter build ios --release --no-codesign

# Navigate to iOS directory
cd ios

# Pod install
print_status "Running pod install..."
pod install

# Build archive
print_status "Creating archive..."
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -destination generic/platform=iOS \
           -archivePath build/Runner.xcarchive \
           archive

# Export IPA
print_status "Exporting IPA..."
xcodebuild -exportArchive \
           -archivePath build/Runner.xcarchive \
           -exportOptionsPlist exportOptions.plist \
           -exportPath build/ios

# Check if IPA was created
IPA_FILE="build/ios/spiral_journal.ipa"
if [[ -f "$IPA_FILE" ]]; then
    print_success "Hotfix build complete!"
    print_success "IPA location: ios/$IPA_FILE"
    print_status "File size: $(du -h "$IPA_FILE" | cut -f1)"
    
    echo ""
    print_status "Next steps:"
    echo "1. Test the IPA locally if needed"
    echo "2. Upload to TestFlight:"
    echo "   ./testflight_build.sh -u your-apple-id -p your-app-password"
    echo "3. Or use Xcode Organizer to upload manually"
    echo ""
    print_warning "Remember to test thoroughly before releasing to testers!"
else
    print_error "IPA file not found! Build may have failed."
    exit 1
fi