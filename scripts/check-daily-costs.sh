#!/bin/bash
set -e

# Check daily costs for a GCP project
# Usage: ./check-daily-costs.sh PROJECT_ID [DAILY_BUDGET]

PROJECT_ID=$1
DAILY_BUDGET=$2

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Usage: ./check-daily-costs.sh PROJECT_ID [DAILY_BUDGET]"
  echo ""
  echo "Examples:"
  echo "  ./check-daily-costs.sh adyela-staging"
  echo "  ./check-daily-costs.sh adyela-staging 0.33  # \$10/month = \$0.33/day"
  echo "  ./check-daily-costs.sh adyela-production 3.33  # \$100/month = \$3.33/day"
  exit 1
fi

echo "💰 Checking costs for $PROJECT_ID..."
echo ""

# Get billing account
BILLING_ACCOUNT=$(gcloud billing projects describe $PROJECT_ID --format='value(billingAccountName)' 2>/dev/null)

if [ -z "$BILLING_ACCOUNT" ]; then
  echo "❌ Could not find billing account for project $PROJECT_ID"
  exit 1
fi

BILLING_ID=$(echo $BILLING_ACCOUNT | sed 's/billingAccounts\///')

# Date ranges
MONTH_START=$(date -u +%Y-%m-01)
TODAY=$(date -u +%Y-%m-%d)
YESTERDAY=$(date -u -d "yesterday" +%Y-%m-%d 2>/dev/null || date -u -v-1d +%Y-%m-%d)

echo "📅 Date Range:"
echo "   Month start: $MONTH_START"
echo "   Today: $TODAY"
echo ""

# Get current month costs
echo "📊 Fetching cost data..."

# Use BigQuery export if available (more accurate)
# Otherwise use billing API (may have delay)

# Try BigQuery first
if gcloud config get-value project >/dev/null 2>&1; then
  # Check if BigQuery export is configured
  DATASET=$(bq ls -d --project_id=$PROJECT_ID 2>/dev/null | grep billing | awk '{print $1}' | head -1)

  if [ -n "$DATASET" ]; then
    echo "   Using BigQuery export for accurate costs..."

    QUERY="
      SELECT
        SUM(cost) as total_cost,
        ROUND(SUM(cost) / DATE_DIFF(CURRENT_DATE(), DATE('$MONTH_START'), DAY), 2) as daily_avg
      FROM \`$PROJECT_ID.$DATASET.gcp_billing_export_v1_*\`
      WHERE
        _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE('$MONTH_START'))
        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
        AND project.id = '$PROJECT_ID'
    "

    RESULT=$(bq query --use_legacy_sql=false --format=json "$QUERY" 2>/dev/null)
    TOTAL_COST=$(echo $RESULT | jq -r '.[0].total_cost // 0')
    DAILY_AVG=$(echo $RESULT | jq -r '.[0].daily_avg // 0')

  else
    echo "   ⚠️  BigQuery export not configured, using billing API (may have delay)..."
    TOTAL_COST="N/A"
    DAILY_AVG="N/A"
  fi
else
  echo "   Using billing API..."
  TOTAL_COST="N/A"
  DAILY_AVG="N/A"
fi

# Get service breakdown
echo ""
echo "📈 Cost Breakdown by Service:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TOTAL_COST" != "N/A" ]; then
  QUERY="
    SELECT
      service.description as service,
      ROUND(SUM(cost), 2) as cost,
      ROUND((SUM(cost) / $TOTAL_COST) * 100, 1) as percentage
    FROM \`$PROJECT_ID.$DATASET.gcp_billing_export_v1_*\`
    WHERE
      _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE('$MONTH_START'))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
      AND project.id = '$PROJECT_ID'
      AND cost > 0
    GROUP BY service
    ORDER BY cost DESC
    LIMIT 10
  "

  bq query --use_legacy_sql=false --format=prettyjson "$QUERY" 2>/dev/null | \
    jq -r '.[] | "\(.service): $\(.cost) (\(.percentage)%)"' | \
    awk '{printf "   %-40s %s\n", $1, $2}'
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Summary
echo ""
echo "💵 Cost Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TOTAL_COST" != "N/A" ]; then
  echo "   Total MTD: \$$TOTAL_COST"
  echo "   Daily Average: \$$DAILY_AVG"

  # Calculate projected monthly cost
  DAYS_IN_MONTH=$(date -d "$MONTH_START +1 month -1 day" +%d 2>/dev/null || echo 30)
  PROJECTED=$(echo "$DAILY_AVG * $DAYS_IN_MONTH" | bc -l | xargs printf "%.2f")

  echo "   Projected Month: \$$PROJECTED"

  # Check against budget if provided
  if [ -n "$DAILY_BUDGET" ]; then
    MONTHLY_BUDGET=$(echo "$DAILY_BUDGET * $DAYS_IN_MONTH" | bc -l | xargs printf "%.2f")
    PERCENT=$(echo "scale=1; ($TOTAL_COST / $MONTHLY_BUDGET) * 100" | bc -l)

    echo ""
    echo "   Budget (Monthly): \$$MONTHLY_BUDGET"
    echo "   Budget Used: ${PERCENT}%"

    # Alert if over threshold
    if (( $(echo "$PERCENT >= 120" | bc -l) )); then
      echo ""
      echo "   🚨 CRITICAL: Budget exceeded 120%!"
    elif (( $(echo "$PERCENT >= 100" | bc -l) )); then
      echo ""
      echo "   ⚠️  WARNING: Budget exceeded 100%"
    elif (( $(echo "$PERCENT >= 80" | bc -l) )); then
      echo ""
      echo "   ⚠️  CAUTION: Budget at 80%"
    elif (( $(echo "$PERCENT >= 50" | bc -l) )); then
      echo ""
      echo "   ℹ️  INFO: Budget at 50%"
    else
      echo ""
      echo "   ✅ Budget on track"
    fi
  fi
else
  echo "   ⚠️  Cost data not available (configure BigQuery export)"
  echo ""
  echo "   To enable detailed cost tracking:"
  echo "   1. Go to: https://console.cloud.google.com/billing/$BILLING_ID"
  echo "   2. Navigate to: Billing export → BigQuery export"
  echo "   3. Click: Edit settings → Enable"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Recommendations
if [ "$TOTAL_COST" != "N/A" ] && [ -n "$DAILY_BUDGET" ]; then
  PERCENT_NUM=$(echo "$PERCENT" | sed 's/%//')

  if (( $(echo "$PERCENT_NUM >= 80" | bc -l) )); then
    echo ""
    echo "💡 Recommendations:"

    # Top 3 services
    echo ""
    echo "   Top cost drivers to review:"

    QUERY="
      SELECT
        service.description as service,
        ROUND(SUM(cost), 2) as cost
      FROM \`$PROJECT_ID.$DATASET.gcp_billing_export_v1_*\`
      WHERE
        _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE('$MONTH_START'))
        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
        AND project.id = '$PROJECT_ID'
        AND cost > 0
      GROUP BY service
      ORDER BY cost DESC
      LIMIT 3
    "

    bq query --use_legacy_sql=false --format=csv "$QUERY" 2>/dev/null | tail -n +2 | \
      awk -F',' '{printf "   • %s: $%s\n", $1, $2}'

    echo ""
    echo "   Suggested actions:"
    echo "   1. Review Cloud Run min-instances settings"
    echo "   2. Check for unused resources"
    echo "   3. Optimize auto-scaling configuration"
    echo "   4. Enable CPU throttling"
    echo "   5. Review logs retention periods"
  fi
fi

echo ""
echo "🔗 View detailed costs:"
echo "   https://console.cloud.google.com/billing/$BILLING_ID/reports?project=$PROJECT_ID"
