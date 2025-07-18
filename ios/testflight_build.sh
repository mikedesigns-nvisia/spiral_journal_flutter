#!/bin/bash

# TestFlight Build and Upload Script for Spiral Journal
# This script automates the process of building and uploading the app to TestFlight

# Exit on error
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🚀 $1${NC}"
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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --username APPLE_ID    Apple ID email address"
    echo "  -p, --password PASSWORD    App-specific password"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  APPLE_ID                   Apple ID email address"
    echo "  APP_SPECIFIC_PASSWORD      App-specific password"
    echo ""
    echo "Examples:"
    echo "  $0 -u mikejarce@icloud.com -p zwzf-esze-fjzc-aayt"
    echo "  APPLE_ID=mikejarce@icloud.com APP_SPECIFIC_PASSWORD=zwzf-esze-fjzc-aayt $0"
}

# Parse command line arguments
APPLE_ID=""
APP_SPECIFIC_PASSWORD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            APPLE_ID="$2"
            shift 2
            ;;
        -p|--password)
            APP_SPECIFIC_PASSWORD="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check for credentials from environment variables if not provided via command line
if [[ -z "$APPLE_ID" ]]; then
    APPLE_ID="$APPLE_ID"
fi

if [[ -z "$APP_SPECIFIC_PASSWORD" ]]; then
    APP_SPECIFIC_PASSWORD="$APP_SPECIFIC_PASSWORD"
fi

# Load from .env file if it exists
if [[ -f "$(dirname "$0")/../.env" ]]; then
    print_status "Loading environment variables from .env file..."
    source "$(dirname "$0")/../.env"
    
    if [[ -z "$APPLE_ID" ]]; then
        APPLE_ID="$APPLE_ID"
    fi
    
    if [[ -z "$APP_SPECIFIC_PASSWORD" ]]; then
        APP_SPECIFIC_PASSWORD="$APP_SPECIFIC_PASSWORD"
    fi
fi

print_status "Starting TestFlight build process for Spiral Journal..."

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS"
    exit 1
fi

# Check for required tools
command -v flutter >/dev/null 2>&1 || { print_error "Flutter is required but not installed"; exit 1; }
command -v xcrun >/dev/null 2>&1 || { print_error "Xcode command line tools are required"; exit 1; }

# Validate credentials
if [[ -z "$APPLE_ID" ]]; then
    print_error "Apple ID is required. Use -u flag, APPLE_ID environment variable, or .env file"
    show_usage
    exit 1
fi

if [[ -z "$APP_SPECIFIC_PASSWORD" ]]; then
    print_error "App-specific password is required. Use -p flag, APP_SPECIFIC_PASSWORD environment variable, or .env file"
    show_usage
    exit 1
fi

# Validate Apple ID format
if [[ ! "$APPLE_ID" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    print_error "Invalid Apple ID format: $APPLE_ID"
    exit 1
fi

# Navigate to project root
cd "$(dirname "$0")/.."
print_status "Working directory: $(pwd)"

# Clean the project
print_status "Cleaning project..."
flutter clean
rm -rf build/
rm -rf ios/build/

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Run tests
print_status "Running tests..."
if ! flutter test; then
    print_warning "Some tests failed, but continuing with build..."
fi

# Build iOS app for TestFlight
print_status "Building iOS app for TestFlight..."
flutter build ios --release --no-codesign

# Navigate to iOS directory
cd ios

# Pod install
print_status "Running pod install..."
pod install

# Build archive
print_status "Building archive..."
if ! xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive; then
    print_error "Failed to build archive"
    exit 1
fi

# Export archive
print_status "Exporting archive..."
if ! xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportOptionsPlist exportOptions.plist -exportPath build/ios; then
    print_error "Failed to export archive"
    exit 1
fi

# Check if IPA file exists
IPA_FILE="build/ios/spiral_journal.ipa"
if [[ ! -f "$IPA_FILE" ]]; then
    print_error "IPA file not found: $IPA_FILE"
    exit 1
fi

print_success "IPA file created successfully: $IPA_FILE"

# Upload to TestFlight
print_status "Uploading to TestFlight..."
print_status "Using Apple ID: $APPLE_ID"

if xcrun altool --upload-app --file "$IPA_FILE" --type ios --username "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD"; then
    print_success "TestFlight upload complete!"
    print_success "Check App Store Connect for build processing status"
    print_status "Build processing usually takes 5-15 minutes"
    print_status "You'll receive an email when processing is complete"
else
    print_error "Failed to upload to TestFlight"
    print_error "Please check your Apple ID credentials and try again"
    exit 1
fi

print_success "🎉 All done! Your app is now uploading to TestFlight"
