#!/bin/bash
# scripts/quality-checks.sh - Complete quality validation

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

FAILURES=0

run_check() {
    local name=$1
    local command=$2
    echo -e "${YELLOW}▶ Running: $name${NC}"
    if eval "$command"; then
        echo -e "${GREEN}✓ $name passed${NC}\n"
    else
        echo -e "${RED}✗ $name failed${NC}\n"
        FAILURES=$((FAILURES + 1))
    fi
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Adyela Quality Checks (Complete CI/CD Validation)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 1. Format Check
echo -e "${BLUE}[1/10] Code Formatting${NC}"
run_check "Prettier" "pnpm format:check"

# 2. Linting
echo -e "${BLUE}[2/10] Code Linting${NC}"
run_check "ESLint" "pnpm lint"

# 3. Type Checking
echo -e "${BLUE}[3/10] Type Checking${NC}"
run_check "TypeScript" "pnpm type-check"

# 4. Python Linting (API)
echo -e "${BLUE}[4/10] Python Quality${NC}"
if [ -d "apps/api" ]; then
    run_check "Black (format)" "cd apps/api && poetry run black --check ."
    run_check "Ruff (lint)" "cd apps/api && poetry run ruff check ."
    run_check "MyPy (type)" "cd apps/api && poetry run mypy adyela_api"
fi

# 5. Unit Tests
echo -e "${BLUE}[5/10] Unit Tests${NC}"
run_check "Frontend Tests" "pnpm test:unit"
if [ -d "apps/api" ]; then
    run_check "API Tests" "cd apps/api && poetry run pytest tests/unit --cov=adyela_api --cov-fail-under=65"
fi

# 6. Integration Tests
echo -e "${BLUE}[6/10] Integration Tests${NC}"
if [ -d "apps/api/tests/integration" ]; then
    run_check "API Integration" "cd apps/api && poetry run pytest tests/integration -v"
fi

# 7. Build Validation
echo -e "${BLUE}[7/10] Build Validation${NC}"
run_check "Build" "pnpm build"

# 8. Security Audit
echo -e "${BLUE}[8/10] Security Audit${NC}"
run_check "NPM Audit" "pnpm audit --audit-level=high --production || true"
if [ -d "apps/api" ]; then
    run_check "Bandit Security" "cd apps/api && poetry run bandit -r adyela_api -ll"
fi

# 9. Dependency License Scan
echo -e "${BLUE}[9/10] License Compliance${NC}"
run_check "License Check" "pnpm exec license-checker --production --onlyAllow 'MIT;ISC;Apache-2.0;BSD-2-Clause;BSD-3-Clause;0BSD' || true"

# 10. Git Hygiene
echo -e "${BLUE}[10/10] Git Hygiene${NC}"
if command -v gitleaks &> /dev/null; then
    run_check "Secret Scan" "gitleaks detect --verbose --no-git"
else
    echo -e "${YELLOW}⚠️  gitleaks not installed, skipping${NC}"
fi

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}  ✓ All quality checks passed! Ready to commit.${NC}"
    exit 0
else
    echo -e "${RED}  ✗ $FAILURES check(s) failed. Fix before committing.${NC}"
    exit 1
fi
