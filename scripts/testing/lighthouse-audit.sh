#!/bin/bash

# Lighthouse Performance Audit Script
# Runs Lighthouse audits and checks against thresholds

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
URL=${1:-"http://localhost:3000"}
OUTPUT_DIR="lighthouse-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Thresholds (0-100)
PERFORMANCE_THRESHOLD=80
ACCESSIBILITY_THRESHOLD=90
BEST_PRACTICES_THRESHOLD=85
SEO_THRESHOLD=90

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Lighthouse Performance Audit${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Target URL: $URL${NC}"
echo -e "${YELLOW}Output: $OUTPUT_DIR/report-$TIMESTAMP${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if lighthouse is installed
if ! command -v lighthouse &> /dev/null; then
    echo -e "${RED}Lighthouse is not installed${NC}"
    echo -e "${YELLOW}Installing Lighthouse...${NC}"
    npm install -g lighthouse
fi

# Check if server is running
echo -e "${YELLOW}Checking if server is running...${NC}"
if ! curl -s "$URL" > /dev/null; then
    echo -e "${RED}Server is not running at $URL${NC}"
    echo -e "${YELLOW}Please start the development server first:${NC}"
    echo "  make start"
    exit 1
fi
echo -e "${GREEN}✓ Server is running${NC}"
echo ""

# Run Lighthouse audit
echo -e "${BLUE}Running Lighthouse audit...${NC}"
lighthouse "$URL" \
    --output=html \
    --output=json \
    --output-path="$OUTPUT_DIR/report-$TIMESTAMP" \
    --chrome-flags="--headless" \
    --quiet

# Parse results
REPORT_JSON="$OUTPUT_DIR/report-$TIMESTAMP.report.json"

if [ ! -f "$REPORT_JSON" ]; then
    echo -e "${RED}Failed to generate report${NC}"
    exit 1
fi

# Extract scores (multiply by 100 to get percentage)
PERFORMANCE=$(jq '.categories.performance.score * 100' "$REPORT_JSON")
ACCESSIBILITY=$(jq '.categories.accessibility.score * 100' "$REPORT_JSON")
BEST_PRACTICES=$(jq '.categories["best-practices"].score * 100' "$REPORT_JSON")
SEO=$(jq '.categories.seo.score * 100' "$REPORT_JSON")

# Display results
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Audit Results${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to display score with color
display_score() {
    local name=$1
    local score=$2
    local threshold=$3

    local score_int=${score%.*}

    if (( $(echo "$score >= $threshold" | bc -l) )); then
        echo -e "${GREEN}✓ $name: $score_int/100${NC} (threshold: $threshold)"
    else
        echo -e "${RED}✗ $name: $score_int/100${NC} (threshold: $threshold)"
    fi
}

display_score "Performance    " "$PERFORMANCE" "$PERFORMANCE_THRESHOLD"
display_score "Accessibility  " "$ACCESSIBILITY" "$ACCESSIBILITY_THRESHOLD"
display_score "Best Practices " "$BEST_PRACTICES" "$BEST_PRACTICES_THRESHOLD"
display_score "SEO            " "$SEO" "$SEO_THRESHOLD"

echo ""
echo -e "${YELLOW}Full report: $OUTPUT_DIR/report-$TIMESTAMP.report.html${NC}"
echo ""

# Check if all thresholds are met
FAILED=0
if (( $(echo "$PERFORMANCE < $PERFORMANCE_THRESHOLD" | bc -l) )); then FAILED=1; fi
if (( $(echo "$ACCESSIBILITY < $ACCESSIBILITY_THRESHOLD" | bc -l) )); then FAILED=1; fi
if (( $(echo "$BEST_PRACTICES < $BEST_PRACTICES_THRESHOLD" | bc -l) )); then FAILED=1; fi
if (( $(echo "$SEO < $SEO_THRESHOLD" | bc -l) )); then FAILED=1; fi

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}  ✓ All thresholds met!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${RED}  ✗ Some thresholds not met${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
