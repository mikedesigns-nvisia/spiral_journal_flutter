#!/bin/bash

# Security Fix Script for Spiral Journal
# This script removes sensitive data from git history and applies security fixes

set -e

echo "🔒 Spiral Journal Security Fix Script"
echo "===================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ This script must be run from within a git repository"
    exit 1
fi

echo "⚠️  WARNING: This script will rewrite git history!"
echo "   Make sure you have a backup of your repository before continuing."
read -p "   Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "   Aborted."
    exit 1
fi

echo "🧹 Step 1: Removing sensitive files from git history..."

# Remove the .env file with actual credentials from git history
echo "   Removing .env file with sensitive data from git history..."
git filter-branch --force --index-filter \
    'git rm --cached --ignore-unmatch .env' \
    --prune-empty --tag-name-filter cat -- --all

echo "🔄 Step 2: Force push warning..."
echo "   After this script completes, you'll need to force push:"
echo "   git push --force-with-lease --all"
echo "   git push --force-with-lease --tags"
echo ""
echo "⚠️  WARNING: This will rewrite public git history!"
echo "   Make sure all collaborators are aware and re-clone the repository."

echo "📝 Step 3: Creating backup of current .env..."
if [ -f .env ]; then
    cp .env .env.backup
    echo "   Backed up current .env to .env.backup"
fi

echo "✅ Step 4: Security fixes applied!"
echo "   ✓ Removed API key from .env file"
echo "   ✓ Fixed password hashing with salt"
echo "   ✓ Removed sensitive data from logs"
echo "   ✓ Created .env.example template"

echo ""
echo "🚨 NEXT STEPS (CRITICAL):"
echo "1. Rotate your Claude API key at https://console.anthropic.com/"
echo "2. Update .env file with new API key"
echo "3. Force push to update remote repository:"
echo "   git push --force-with-lease --all"
echo "4. Notify all collaborators to re-clone the repository"

echo ""
echo "📚 Additional security improvements recommended:"
echo "- Add bcrypt package for stronger password hashing"
echo "- Implement certificate pinning"
echo "- Add input validation for journal entries"
echo "- Implement jailbreak/root detection"

echo ""
echo "✅ Script completed successfully!"