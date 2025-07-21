#!/bin/bash

# Test script to verify the provisioning profile fix
# This script tests the build without doing a full TestFlight upload

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}🚀 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_status "Testing iOS build fix for provisioning profile issue..."

# Navigate to project root
cd "$(dirname "$0")/.."
print_status "Working directory: $(pwd)"

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Build iOS app for release (no codesign to test build process)
print_status "Building iOS app for release..."
flutter build ios --release --no-codesign

# Navigate to iOS directory
cd ios

# Pod install
print_status "Running pod install..."
pod install

# Test archive build with explicit iOS destination
print_status "Testing archive build with iOS destination..."
if xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -destination generic/platform=iOS -archivePath build/test.xcarchive archive; then
    print_success "🎉 Build test successful! The provisioning profile issue is fixed."
    print_success "You can now run the full TestFlight build script."
    
    # Clean up test archive
    rm -rf build/test.xcarchive
    
    print_status "Next steps:"
    echo "1. Run: ./ios/testflight_build.sh -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD"
    echo "2. Or set environment variables and run: ./ios/testflight_build.sh"
else
    print_error "Build test failed. There may be other issues to resolve."
    exit 1
fi
