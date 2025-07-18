#!/bin/bash

# TestFlight Group Configuration Script for Spiral Journal
# This script helps set up and manage TestFlight testing groups

# Exit on error
set -e

echo "👥 TestFlight Group Configuration for Spiral Journal"
echo "----------------------------------------------------"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "❌ Error: This script must be run on macOS"
  exit 1
fi

# Check for required tools
command -v xcrun >/dev/null 2>&1 || { echo "❌ Error: Xcode command line tools are required"; exit 1; }

# Define testing groups
CORE_TESTERS="Core Team"
FEATURE_TESTERS="Feature Testers"
UX_TESTERS="UX Testers"
PERFORMANCE_TESTERS="Performance Testers"
SECURITY_TESTERS="Security Testers"

# Function to create a testing group
create_group() {
  local group_name=$1
  local group_description=$2
  
  echo "📝 Creating testing group: $group_name"
  echo "   Description: $group_description"
  
  # In a real implementation, this would use App Store Connect API
  # For now, this is a placeholder that prints the command
  echo "   Command: xcrun altool --create-testing-group --group-name \"$group_name\" --description \"$group_description\""
}

# Function to add testers to a group
add_testers() {
  local group_name=$1
  shift
  local emails=("$@")
  
  echo "👤 Adding testers to group: $group_name"
  for email in "${emails[@]}"; do
    echo "   Adding: $email"
    # In a real implementation, this would use App Store Connect API
    # For now, this is a placeholder that prints the command
    echo "   Command: xcrun altool --add-tester --email \"$email\" --group-name \"$group_name\""
  done
}

# Main menu
while true; do
  echo ""
  echo "📋 TestFlight Group Management Menu:"
  echo "1. Create Core Team group"
  echo "2. Create Feature Testers group"
  echo "3. Create UX Testers group"
  echo "4. Create Performance Testers group"
  echo "5. Create Security Testers group"
  echo "6. Add testers to a group"
  echo "7. Exit"
  echo ""
  read -p "Select an option (1-7): " option
  
  case $option in
    1)
      create_group "$CORE_TESTERS" "Internal development team for critical testing"
      ;;
    2)
      create_group "$FEATURE_TESTERS" "Testers focused on specific feature functionality"
      ;;
    3)
      create_group "$UX_TESTERS" "Testers focused on user experience and interface"
      ;;
    4)
      create_group "$PERFORMANCE_TESTERS" "Testers focused on app performance and optimization"
      ;;
    5)
      create_group "$SECURITY_TESTERS" "Testers focused on security and data protection"
      ;;
    6)
      echo ""
      echo "Available groups:"
      echo "1. $CORE_TESTERS"
      echo "2. $FEATURE_TESTERS"
      echo "3. $UX_TESTERS"
      echo "4. $PERFORMANCE_TESTERS"
      echo "5. $SECURITY_TESTERS"
      read -p "Select a group (1-5): " group_option
      
      case $group_option in
        1) selected_group="$CORE_TESTERS" ;;
        2) selected_group="$FEATURE_TESTERS" ;;
        3) selected_group="$UX_TESTERS" ;;
        4) selected_group="$PERFORMANCE_TESTERS" ;;
        5) selected_group="$SECURITY_TESTERS" ;;
        *) echo "Invalid option"; continue ;;
      esac
      
      echo "Enter email addresses (comma-separated):"
      read email_list
      IFS=',' read -ra emails <<< "$email_list"
      add_testers "$selected_group" "${emails[@]}"
      ;;
    7)
      echo "👋 Exiting TestFlight group configuration"
      exit 0
      ;;
    *)
      echo "❌ Invalid option. Please select 1-7."
      ;;
  esac
done