#!/bin/bash

# BCL Convert Pipeline - GitHub Push Script
# This script will help you push your pipeline to GitHub

set -e

echo "🚀 BCL Convert Pipeline - GitHub Push Helper"
echo "============================================"
echo ""

# Check if we're in the right directory
if [ ! -f "main.nf" ]; then
    echo "❌ Error: Please run this script from the bcl-convert-pipeline directory"
    exit 1
fi

# Check git status
echo "📊 Current Git Status:"
git status
echo ""

# Get GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME
if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ Error: GitHub username is required"
    exit 1
fi

# Get repository name (with default)
read -p "Enter repository name [bcl-convert-pipeline]: " REPO_NAME
REPO_NAME=${REPO_NAME:-bcl-convert-pipeline}

echo ""
echo "📝 Configuration:"
echo "   GitHub User: $GITHUB_USERNAME"
echo "   Repository: $REPO_NAME"
echo ""

# Confirm before proceeding
read -p "Is this correct? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "❌ Aborted"
    exit 0
fi

echo ""
echo "🔧 Setting up Git..."

# Set branch to main
git branch -M main

# Set remote
REMOTE_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
echo "   Setting remote: $REMOTE_URL"

# Check if remote already exists
if git remote get-url origin &> /dev/null; then
    echo "   Remote 'origin' already exists, updating URL..."
    git remote set-url origin "$REMOTE_URL"
else
    echo "   Adding remote 'origin'..."
    git remote add origin "$REMOTE_URL"
fi

echo ""
echo "✅ Git configuration complete!"
echo ""
echo "📤 Next Steps:"
echo ""
echo "1. Make sure you've created the repository on GitHub:"
echo "   👉 https://github.com/new"
echo "   Repository name: $REPO_NAME"
echo "   ⚠️  Do NOT initialize with README, .gitignore, or license"
echo ""
echo "2. Push your code:"
echo "   git push -u origin main"
echo ""
echo "3. If prompted for authentication, use:"
echo "   Username: $GITHUB_USERNAME"
echo "   Password: <your GitHub Personal Access Token>"
echo ""
echo "🔐 Generate token at: https://github.com/settings/tokens"
echo "   Required permissions: repo (Full control)"
echo ""
echo "Ready to push? Run: git push -u origin main"
