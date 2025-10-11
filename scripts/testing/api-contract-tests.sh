#!/bin/bash

# API Contract Testing with Schemathesis
# Validates API against OpenAPI specification

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
API_URL=${1:-"http://localhost:8000"}
SPEC_URL="$API_URL/openapi.json"
OUTPUT_DIR="schemathesis-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  API Contract Testing${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}API URL: $API_URL${NC}"
echo -e "${YELLOW}Spec URL: $SPEC_URL${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if schemathesis is installed
if ! command -v schemathesis &> /dev/null; then
    echo -e "${YELLOW}Schemathesis not found. Installing...${NC}"
    pip install schemathesis
fi

# Check if API is running
echo -e "${YELLOW}Checking if API is running...${NC}"
if ! curl -s "$API_URL/health" > /dev/null; then
    echo -e "${RED}API is not running at $API_URL${NC}"
    echo -e "${YELLOW}Please start the API first:${NC}"
    echo "  make start"
    exit 1
fi
echo -e "${GREEN}✓ API is running${NC}"
echo ""

# Check if OpenAPI spec is available
echo -e "${YELLOW}Checking OpenAPI specification...${NC}"
if ! curl -s "$SPEC_URL" > /dev/null; then
    echo -e "${RED}OpenAPI spec not available at $SPEC_URL${NC}"
    exit 1
fi
echo -e "${GREEN}✓ OpenAPI spec found${NC}"
echo ""

# Run Schemathesis tests
echo -e "${BLUE}Running contract tests...${NC}"
echo ""

schemathesis run "$SPEC_URL" \
    --url "$API_URL" \
    --checks all \
    --max-examples=50 \
    --workers=4 \
    --request-timeout=5000 \
    --validate-schema=true \
    --report="$OUTPUT_DIR/report-$TIMESTAMP.html" \
    --junit-xml="$OUTPUT_DIR/junit-$TIMESTAMP.xml" \
    || EXIT_CODE=$?

echo ""

# Check results
if [ ${EXIT_CODE:-0} -eq 0 ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✓ All contract tests passed!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Report: $OUTPUT_DIR/report-$TIMESTAMP.html${NC}"
    exit 0
else
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ✗ Some contract tests failed${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Report: $OUTPUT_DIR/report-$TIMESTAMP.html${NC}"
    exit 1
fi
