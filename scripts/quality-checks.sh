#!/bin/bash

# Comprehensive Quality Checks Script
# Runs various quality checks, validations, and security scans

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Track failures and warnings
FAILURES=0
WARNINGS=0
TOTAL_CHECKS=0

# Configuration
COVERAGE_THRESHOLD=80
BUNDLE_SIZE_LIMIT=2000000  # 2MB in bytes
MAX_FILE_SIZE=10485760     # 10MB in bytes

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🚀 Adyela Comprehensive Quality Checks${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to run a check with detailed output
run_check() {
    local name=$1
    local command=$2
    local critical=${3:-true}  # Default to critical check

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -e "${CYAN}▶ [$TOTAL_CHECKS] Running: $name${NC}"
    
    local start_time=$(date +%s)
    
    if eval "$command" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${GREEN}✓ $name passed (${duration}s)${NC}"
        echo ""
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        if [ "$critical" = true ]; then
            echo -e "${RED}✗ $name failed (${duration}s)${NC}"
            FAILURES=$((FAILURES + 1))
        else
            echo -e "${YELLOW}⚠ $name failed (${duration}s) - Non-critical${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
        echo ""
        return 1
    fi
}

# Function to check file sizes
check_file_sizes() {
    echo -e "${PURPLE}📁 Checking file sizes...${NC}"
    local large_files=$(find . -type f -size +${MAX_FILE_SIZE}c -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./.turbo/*" -not -path "./dist/*" -not -path "./dev-dist/*" 2>/dev/null || true)
    
    if [ -n "$large_files" ]; then
        echo -e "${YELLOW}⚠ Large files detected (>10MB):${NC}"
        echo "$large_files" | while read -r file; do
            local size=$(du -h "$file" | cut -f1)
            echo -e "  ${YELLOW}$file ($size)${NC}"
        done
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓ No large files detected${NC}"
    fi
    echo ""
}

# Function to check for TODO/FIXME comments
check_todos() {
    echo -e "${PURPLE}📝 Checking for TODO/FIXME comments...${NC}"
    local todos=$(grep -r -n -E "TODO|FIXME|HACK|XXX" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.py" apps/ 2>/dev/null || true)
    
    if [ -n "$todos" ]; then
        echo -e "${YELLOW}⚠ TODO/FIXME comments found:${NC}"
        echo "$todos" | head -10 | while read -r line; do
            echo -e "  ${YELLOW}$line${NC}"
        done
        if [ $(echo "$todos" | wc -l) -gt 10 ]; then
            echo -e "  ${YELLOW}... and $(( $(echo "$todos" | wc -l) - 10 )) more${NC}"
        fi
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓ No TODO/FIXME comments found${NC}"
    fi
    echo ""
}

# Function to check bundle size
check_bundle_size() {
    echo -e "${PURPLE}📦 Checking bundle size...${NC}"
    if [ -d "apps/web/dist" ]; then
        local total_size=$(du -sb apps/web/dist | cut -f1)
        local total_size_mb=$((total_size / 1024 / 1024))
        
        echo -e "Total bundle size: ${total_size_mb}MB"
        
        if [ $total_size -gt $BUNDLE_SIZE_LIMIT ]; then
            echo -e "${YELLOW}⚠ Bundle size exceeds limit (${total_size_mb}MB > 2MB)${NC}"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "${GREEN}✓ Bundle size within limits${NC}"
        fi
        
        echo -e "${CYAN}Largest files:${NC}"
        find apps/web/dist -type f -exec du -h {} + | sort -hr | head -5
    else
        echo -e "${YELLOW}⚠ No build artifacts found. Run 'pnpm build' first.${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
    echo ""
}

# Pre-flight checks
echo -e "${PURPLE}🔍 Pre-flight checks...${NC}"
check_file_sizes
check_todos

# 1. Code Quality - Frontend
echo -e "${BLUE}📱 Frontend Quality Checks${NC}"
run_check "ESLint" "pnpm lint" || true
run_check "TypeScript Type Check" "pnpm type-check" || true
run_check "Prettier Format Check" "pnpm format:check" || true

# 2. Code Quality - Backend
echo -e "${BLUE}🐍 Backend Quality Checks${NC}"
if [ -d "apps/api" ]; then
    run_check "Ruff Linting" "cd apps/api && poetry run ruff check ." || true
    run_check "Black Format Check" "cd apps/api && poetry run black --check ." || true
    run_check "MyPy Type Check" "cd apps/api && poetry run mypy adyela_api" || true
    run_check "Import Sorting" "cd apps/api && poetry run ruff check --select I ." || true
fi

# 3. Security Checks
echo -e "${BLUE}🔒 Security Checks${NC}"
if command -v gitleaks &> /dev/null; then
    run_check "Gitleaks Secret Scan" "gitleaks detect --source . --config .gitleaks.toml" false || true
else
    echo -e "${YELLOW}⚠ Gitleaks not installed, skipping secret scan${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

run_check "NPM Security Audit" "pnpm audit --audit-level=moderate" false || true

if [ -d "apps/api" ]; then
    run_check "Python Security Audit" "cd apps/api && poetry run safety check" false || true
    run_check "Bandit Security Scan" "cd apps/api && poetry run bandit -r . -f json" false || true
fi

# 4. Testing
echo -e "${BLUE}🧪 Testing${NC}"
run_check "Frontend Unit Tests" "pnpm test:unit" || true

if [ -d "apps/api" ]; then
    run_check "Backend Unit Tests" "cd apps/api && poetry run pytest tests/unit -v --tb=short" || true
    run_check "Backend Integration Tests" "cd apps/api && poetry run pytest tests/integration -v --tb=short" false || true
fi

# 5. Build & Bundle Analysis
echo -e "${BLUE}🏗️ Build & Bundle Analysis${NC}"
run_check "Frontend Build" "pnpm build" || true
check_bundle_size

if [ -d "apps/api" ]; then
    run_check "Backend Import Check" "cd apps/api && poetry run python -c 'import adyela_api; print(\"✓ Backend imports successfully\")'" || true
fi

# 6. Infrastructure Checks
echo -e "${BLUE}🏗️ Infrastructure Checks${NC}"
if [ -d "infra" ]; then
    run_check "Terraform Format Check" "cd infra && terraform fmt -check -recursive" false || true
    run_check "Terraform Validate" "cd infra/environments/staging && terraform init -backend=false && terraform validate" false || true
fi

# 7. Documentation Checks
echo -e "${BLUE}📚 Documentation Checks${NC}"
run_check "README Exists" "test -f README.md" || true
run_check "API Documentation" "test -f apps/api/README.md" false || true
run_check "Web Documentation" "test -f apps/web/README.md" false || true

# 8. Performance Checks
echo -e "${BLUE}⚡ Performance Checks${NC}"
if [ -d "apps/web/dist" ]; then
    echo -e "${PURPLE}📊 Performance metrics:${NC}"
    echo -e "Bundle size: $(du -sh apps/web/dist | cut -f1)"
    echo -e "Number of files: $(find apps/web/dist -type f | wc -l)"
    echo -e "Largest file: $(find apps/web/dist -type f -exec du -h {} + | sort -hr | head -1 | cut -f2)"
    echo ""
fi

# 9. Coverage Analysis
echo -e "${BLUE}📊 Coverage Analysis${NC}"
if [ -d "apps/web/coverage" ]; then
    echo -e "${GREEN}✓ Frontend coverage report available${NC}"
else
    echo -e "${YELLOW}⚠ Frontend coverage report not found. Run 'pnpm test:coverage'${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -d "apps/api/htmlcov" ]; then
    echo -e "${GREEN}✓ Backend coverage report available${NC}"
else
    echo -e "${YELLOW}⚠ Backend coverage report not found. Run 'cd apps/api && poetry run pytest --cov=adyela_api --cov-report=html'${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Final Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  📋 Quality Check Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "Total checks run: ${TOTAL_CHECKS}"
echo -e "Critical failures: ${FAILURES}"
echo -e "Warnings: ${WARNINGS}"
echo ""

if [ $FAILURES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 All quality checks passed! Code is ready for production.${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
elif [ $FAILURES -eq 0 ]; then
    echo -e "${YELLOW}⚠ All critical checks passed, but $WARNINGS warning(s) found.${NC}"
    echo -e "${YELLOW}Consider addressing warnings before production deployment.${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILURES critical check(s) failed.${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Additionally, $WARNINGS warning(s) found.${NC}"
    fi
    echo -e "${RED}Please fix critical issues before proceeding.${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
