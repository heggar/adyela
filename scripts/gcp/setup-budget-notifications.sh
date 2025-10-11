#!/bin/bash
set -e

# Setup Budget Notifications and Auto-Shutdown
# Usage: ./setup-budget-notifications.sh PROJECT_ID ENVIRONMENT SLACK_WEBHOOK_URL

PROJECT_ID=$1
ENVIRONMENT=$2
SLACK_WEBHOOK_URL=$3

if [ -z "$PROJECT_ID" ] || [ -z "$ENVIRONMENT" ]; then
  echo "❌ Usage: ./setup-budget-notifications.sh PROJECT_ID ENVIRONMENT [SLACK_WEBHOOK_URL]"
  echo ""
  echo "Examples:"
  echo "  ./setup-budget-notifications.sh adyela-staging staging"
  echo "  ./setup-budget-notifications.sh adyela-production production https://hooks.slack.com/services/..."
  exit 1
fi

echo "🔔 Setting up budget notifications for $PROJECT_ID..."
echo ""

gcloud config set project $PROJECT_ID

# 1. Create Pub/Sub topic if not exists
TOPIC_NAME="budget-alerts"
if ! gcloud pubsub topics describe $TOPIC_NAME &>/dev/null; then
  echo "📢 Creating Pub/Sub topic..."
  gcloud pubsub topics create $TOPIC_NAME
else
  echo "✅ Pub/Sub topic already exists"
fi

# 2. Create Cloud Function for notifications
FUNCTION_NAME="budget-notification-handler"
FUNCTION_DIR="/tmp/budget-function-${PROJECT_ID}"

mkdir -p $FUNCTION_DIR

# Create package.json
cat > $FUNCTION_DIR/package.json <<'EOF'
{
  "name": "budget-notification-handler",
  "version": "1.0.0",
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0",
    "axios": "^1.6.0"
  }
}
EOF

# Create index.js
cat > $FUNCTION_DIR/index.js <<'EOFJS'
const functions = require('@google-cloud/functions-framework');
const axios = require('axios');

functions.cloudEvent('handleBudgetAlert', async (cloudEvent) => {
  const budgetData = Buffer.from(cloudEvent.data.message.data, 'base64').toString();
  const budget = JSON.parse(budgetData);

  const costAmount = budget.costAmount || 0;
  const budgetAmount = budget.budgetAmount || 0;
  const percentageUsed = (costAmount / budgetAmount * 100).toFixed(2);

  console.log(`Budget Alert: ${percentageUsed}% used ($${costAmount}/$${budgetAmount})`);

  // Send to Slack if webhook URL is configured
  const slackWebhook = process.env.SLACK_WEBHOOK_URL;
  if (slackWebhook) {
    const severity = percentageUsed >= 100 ? '🚨' : percentageUsed >= 80 ? '⚠️' : '📊';
    const color = percentageUsed >= 100 ? 'danger' : percentageUsed >= 80 ? 'warning' : 'good';

    await axios.post(slackWebhook, {
      attachments: [{
        color: color,
        title: `${severity} Budget Alert - ${budget.budgetDisplayName || 'Unknown Budget'}`,
        fields: [
          {
            title: 'Current Spend',
            value: `$${costAmount}`,
            short: true
          },
          {
            title: 'Budget',
            value: `$${budgetAmount}`,
            short: true
          },
          {
            title: 'Percentage Used',
            value: `${percentageUsed}%`,
            short: true
          },
          {
            title: 'Environment',
            value: process.env.ENVIRONMENT || 'unknown',
            short: true
          }
        ],
        footer: 'GCP Budget Alert',
        ts: Math.floor(Date.now() / 1000)
      }]
    });
  }

  // Trigger auto-shutdown if over 100%
  if (percentageUsed >= 100) {
    console.log('⚠️ Budget exceeded! Auto-shutdown should be triggered.');
    // Publish to auto-shutdown topic
    const topicName = process.env.AUTO_SHUTDOWN_TOPIC;
    if (topicName) {
      const {PubSub} = require('@google-cloud/pubsub');
      const pubsub = new PubSub();
      await pubsub.topic(topicName).publishMessage({
        data: Buffer.from(JSON.stringify({
          project: budget.name,
          costAmount,
          budgetAmount
        }))
      });
      console.log('✅ Auto-shutdown triggered');
    }
  }
});
EOFJS

echo ""
echo "☁️ Deploying Cloud Function..."

# Deploy Cloud Function
DEPLOY_CMD="gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=$FUNCTION_DIR \
  --entry-point=handleBudgetAlert \
  --trigger-topic=$TOPIC_NAME \
  --set-env-vars=ENVIRONMENT=$ENVIRONMENT"

if [ -n "$SLACK_WEBHOOK_URL" ]; then
  DEPLOY_CMD="$DEPLOY_CMD,SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_URL"
fi

eval $DEPLOY_CMD

# 3. Grant permissions to Cloud Billing to publish to topic
echo ""
echo "🔐 Granting permissions..."

# The Billing service account needs publisher role
gcloud pubsub topics add-iam-policy-binding $TOPIC_NAME \
  --member=serviceAccount:cloud-billing-budget@system.gserviceaccount.com \
  --role=roles/pubsub.publisher || echo "⚠️ Could not grant permissions - may need to be done manually"

# 4. Update budget to use Pub/Sub topic
echo ""
echo "🔄 Budget update instructions:"
echo ""
echo "Run this command to update your budget:"
echo ""
echo "gcloud billing budgets update BUDGET_ID \\"
echo "  --billing-account=BILLING_ACCOUNT \\"
echo "  --notifications-rule-pubsub-topic=projects/$PROJECT_ID/topics/$TOPIC_NAME"
echo ""

# Cleanup
rm -rf $FUNCTION_DIR

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Budget Notifications Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 What was configured:"
echo "   ✅ Pub/Sub topic: projects/$PROJECT_ID/topics/$TOPIC_NAME"
echo "   ✅ Cloud Function: $FUNCTION_NAME"
if [ -n "$SLACK_WEBHOOK_URL" ]; then
  echo "   ✅ Slack notifications: Enabled"
else
  echo "   ⚠️ Slack notifications: Not configured (no webhook provided)"
fi
echo ""
echo "🔗 View function logs:"
echo "   gcloud functions logs read $FUNCTION_NAME --region=us-central1"
echo ""
