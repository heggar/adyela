#!/bin/bash
set -e

# Setup GCP Budgets with alerts
# Usage: ./setup-budgets.sh PROJECT_ID BUDGET_AMOUNT [BILLING_ACCOUNT]

PROJECT_ID=$1
BUDGET_AMOUNT=$2
BILLING_ACCOUNT=$3

if [ -z "$PROJECT_ID" ] || [ -z "$BUDGET_AMOUNT" ]; then
  echo "❌ Usage: ./setup-budgets.sh PROJECT_ID BUDGET_AMOUNT [BILLING_ACCOUNT]"
  echo ""
  echo "Examples:"
  echo "  ./setup-budgets.sh adyela-staging 10"
  echo "  ./setup-budgets.sh adyela-production 100 012345-67890A-BCDEF1"
  exit 1
fi

echo "💰 Setting up budget for $PROJECT_ID with \$$BUDGET_AMOUNT/month limit..."
echo ""

# Get billing account if not provided
if [ -z "$BILLING_ACCOUNT" ]; then
  echo "📋 Fetching billing account..."
  BILLING_ACCOUNT=$(gcloud billing projects describe $PROJECT_ID --format='value(billingAccountName)' | sed 's/billingAccounts\///')

  if [ -z "$BILLING_ACCOUNT" ]; then
    echo "❌ Could not find billing account for project $PROJECT_ID"
    echo "Please provide billing account ID as third parameter"
    exit 1
  fi

  echo "   Found: $BILLING_ACCOUNT"
fi

# Create budget configuration
BUDGET_NAME="${PROJECT_ID}-monthly-budget"
TEMP_FILE="/tmp/budget-${PROJECT_ID}.json"

cat > $TEMP_FILE <<EOF
{
  "displayName": "${BUDGET_NAME}",
  "budgetFilter": {
    "projects": ["projects/${PROJECT_ID}"],
    "creditTypesTreatment": "INCLUDE_ALL_CREDITS"
  },
  "amount": {
    "specifiedAmount": {
      "currencyCode": "USD",
      "units": "${BUDGET_AMOUNT}"
    }
  },
  "thresholdRules": [
    {
      "thresholdPercent": 0.5,
      "spendBasis": "CURRENT_SPEND"
    },
    {
      "thresholdPercent": 0.8,
      "spendBasis": "CURRENT_SPEND"
    },
    {
      "thresholdPercent": 1.0,
      "spendBasis": "CURRENT_SPEND"
    },
    {
      "thresholdPercent": 1.2,
      "spendBasis": "CURRENT_SPEND"
    }
  ],
  "notificationsRule": {
    "pubsubTopic": "",
    "monitoringNotificationChannels": [],
    "disableDefaultIamRecipients": false
  }
}
EOF

echo ""
echo "📊 Budget Configuration:"
cat $TEMP_FILE | jq .
echo ""

# Check if budget already exists
EXISTING_BUDGET=$(gcloud billing budgets list --billing-account=$BILLING_ACCOUNT \
  --filter="displayName:${BUDGET_NAME}" \
  --format="value(name)" 2>/dev/null | head -1)

if [ -n "$EXISTING_BUDGET" ]; then
  echo "⚠️  Budget already exists: $EXISTING_BUDGET"
  read -p "Do you want to update it? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Updating existing budget..."
    gcloud billing budgets update $EXISTING_BUDGET \
      --billing-account=$BILLING_ACCOUNT \
      --budget-file=$TEMP_FILE
    echo "✅ Budget updated successfully!"
  else
    echo "Skipping budget update"
  fi
else
  echo "Creating new budget..."
  gcloud billing budgets create \
    --billing-account=$BILLING_ACCOUNT \
    --display-name="${BUDGET_NAME}" \
    --budget-amount=${BUDGET_AMOUNT}USD \
    --threshold-rule=percent=0.5 \
    --threshold-rule=percent=0.8 \
    --threshold-rule=percent=1.0 \
    --threshold-rule=percent=1.2

  echo "✅ Budget created successfully!"
fi

rm -f $TEMP_FILE

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Budget Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Budget Details:"
echo "   Project: $PROJECT_ID"
echo "   Amount: \$$BUDGET_AMOUNT/month"
echo "   Alerts: 50%, 80%, 100%, 120%"
echo ""
echo "🔔 Alert Thresholds:"
echo "   • 50% (\$$(echo "$BUDGET_AMOUNT * 0.5" | bc)) - Info"
echo "   • 80% (\$$(echo "$BUDGET_AMOUNT * 0.8" | bc)) - Warning"
echo "   • 100% (\$${BUDGET_AMOUNT}) - Critical"
echo "   • 120% (\$$(echo "$BUDGET_AMOUNT * 1.2" | bc)) - Emergency"
echo ""
echo "📧 Notifications will be sent to project billing admins"
echo ""
echo "🔗 View budget:"
echo "   https://console.cloud.google.com/billing/${BILLING_ACCOUNT}/budgets"
echo ""
echo "📝 Next steps:"
echo "   1. Configure Slack/PagerDuty notifications (optional)"
echo "   2. Set up Cloud Functions for auto-shutdown (optional)"
echo "   3. Monitor daily: ./scripts/check-daily-costs.sh $PROJECT_ID"
