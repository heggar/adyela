#!/bin/bash
# scripts/dev-setup.sh - One-time developer setup

set -e

echo "🚀 Setting up Adyela development environment..."

# Install dependencies
pnpm install

# Setup husky hooks
pnpm prepare

# Install gitleaks for secret scanning
if ! command -v gitleaks &> /dev/null; then
  echo "📦 Installing gitleaks..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install gitleaks
  else
    echo "Please install gitleaks: https://github.com/gitleaks/gitleaks#installing"
  fi
fi

# Install Task Master globally
npm install -g task-master-ai

# Verify Task Master config
if [ ! -f ".taskmaster/config.json" ]; then
  echo "❌ Task Master not initialized. Run: npx task-master-ai init"
  exit 1
fi

# Create task context directory
mkdir -p .task-context

# Add to .gitignore
if ! grep -q ".task-context" .gitignore; then
  echo ".task-context/" >> .gitignore
fi

echo "✓ Development environment ready!"
echo ""
echo "Quick start:"
echo "  1. Start a task: make task-start ID=<task-id>"
echo "  2. Develop and commit (hooks will run automatically)"
echo "  3. Run quality checks: make quality-local"
echo "  4. Complete task: make task-complete ID=<task-id>"

