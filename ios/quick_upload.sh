#!/bin/bash

# Quick TestFlight Upload Script for Spiral Journal
# This script uploads an existing .ipa file to TestFlight without rebuilding

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
    echo "  -f, --file IPA_FILE        Path to .ipa file (default: build/ios/spiral_journal.ipa)"
    echo "  -u, --username APPLE_ID    Apple ID email address"
    echo "  -p, --password PASSWORD    App-specific password"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  APPLE_ID                   Apple ID email address"
    echo "  APP_SPECIFIC_PASSWORD      App-specific password"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 -f build/ios/spiral_journal.ipa"
    echo "  $0 -u mikejarce@icloud.com -p zwzf-esze-fjzc-aayt"
}

# Parse command line arguments
IPA_FILE="build/ios/spiral_journal.ipa"
APPLE_ID=""
APP_SPECIFIC_PASSWORD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            IPA_FILE="$2"
            shift 2
            ;;
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

# Load from .env file if it exists
if [[ -f "$(dirname "$0")/../.env" ]]; then
    print_status "Loading environment variables from .env file..."
    source "$(dirname "$0")/../.env"
fi

# Check for credentials from environment variables if not provided via command line
if [[ -z "$APPLE_ID" ]]; then
    APPLE_ID="$APPLE_ID"
fi

if [[ -z "$APP_SPECIFIC_PASSWORD" ]]; then
    APP_SPECIFIC_PASSWORD="$APP_SPECIFIC_PASSWORD"
fi

print_status "Quick TestFlight upload for Spiral Journal..."

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS"
    exit 1
fi

# Check for required tools
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

# Navigate to iOS directory
cd "$(dirname "$0")"
print_status "Working directory: $(pwd)"

# Check if IPA file exists
if [[ ! -f "$IPA_FILE" ]]; then
    print_error "IPA file not found: $IPA_FILE"
    print_status "Available files in build/ios/:"
    ls -la build/ios/ 2>/dev/null || print_warning "build/ios/ directory not found"
    exit 1
fi

print_success "Found IPA file: $IPA_FILE"
print_status "File size: $(du -h "$IPA_FILE" | cut -f1)"

# Upload to TestFlight
print_status "Uploading to TestFlight..."
print_status "Using Apple ID: $APPLE_ID"

if xcrun altool --upload-app --file "$IPA_FILE" --type ios --username "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD"; then
    print_success "TestFlight upload complete!"
    print_success "Check App Store Connect for build processing status"
    print_status "Build processing usually takes 5-15 minutes"
    print_status "You'll receive an email when processing is complete"
    print_status "App Store Connect: https://appstoreconnect.apple.com/"
else
    print_error "Failed to upload to TestFlight"
    print_error "Please check your Apple ID credentials and try again"
    print_warning "Common issues:"
    print_warning "- Invalid Apple ID or app-specific password"
    print_warning "- Network connectivity issues"
    print_warning "- IPA file corruption"
    print_warning "- Apple Developer account issues"
    exit 1
fi

print_success "🎉 Upload complete! Your app is now processing on TestFlight"
