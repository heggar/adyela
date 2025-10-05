#!/bin/bash

# Quality Checks Script
# Runs various quality checks and validations

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Track failures
FAILURES=0

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Adyela Quality Checks${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to run a check
run_check() {
    local name=$1
    local command=$2

    echo -e "${YELLOW}▶ Running: $name${NC}"

    if eval "$command"; then
        echo -e "${GREEN}✓ $name passed${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ $name failed${NC}"
        echo ""
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

# 1. Linting
echo -e "${BLUE}[1/8] Code Linting${NC}"
run_check "ESLint" "pnpm lint" || true

# 2. Type Checking
echo -e "${BLUE}[2/8] Type Checking${NC}"
run_check "TypeScript" "pnpm type-check" || true

# 3. Python Linting (API)
echo -e "${BLUE}[3/8] Python Linting${NC}"
if [ -d "apps/api" ]; then
    run_check "Ruff" "cd apps/api && poetry run ruff check ." || true
    run_check "MyPy" "cd apps/api && poetry run mypy adyela_api" || true
fi

# 4. Unit Tests
echo -e "${BLUE}[4/8] Unit Tests${NC}"
run_check "Frontend Tests" "pnpm test:unit" || true

# 5. API Tests
echo -e "${BLUE}[5/8] API Tests${NC}"
if [ -d "apps/api" ]; then
    run_check "Python Tests" "cd apps/api && poetry run pytest tests/unit -v" || true
fi

# 6. Build Check
echo -e "${BLUE}[6/8] Build Validation${NC}"
run_check "Build" "pnpm build" || true

# 7. Security Audit
echo -e "${BLUE}[7/8] Security Audit${NC}"
run_check "NPM Audit" "pnpm audit --audit-level=high --production" || true

# 8. Bundle Size Check
echo -e "${BLUE}[8/8] Bundle Size Analysis${NC}"
if [ -f "apps/web/dist" ]; then
    echo -e "${YELLOW}Bundle size analysis:${NC}"
    du -sh apps/web/dist/* 2>/dev/null || echo "No build artifacts found"
    echo ""
fi

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}  ✓ All quality checks passed!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${RED}  ✗ $FAILURES check(s) failed${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
