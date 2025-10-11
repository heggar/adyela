#!/bin/bash
set -e

# Setup Auto-Shutdown when budget is exceeded
# Usage: ./setup-auto-shutdown.sh PROJECT_ID ENVIRONMENT

PROJECT_ID=$1
ENVIRONMENT=$2

if [ -z "$PROJECT_ID" ] || [ -z "$ENVIRONMENT" ]; then
  echo "❌ Usage: ./setup-auto-shutdown.sh PROJECT_ID ENVIRONMENT"
  echo ""
  echo "Examples:"
  echo "  ./setup-auto-shutdown.sh adyela-staging staging"
  echo "  ./setup-auto-shutdown.sh adyela-production production"
  exit 1
fi

echo "🛑 Setting up auto-shutdown for $PROJECT_ID when budget is exceeded..."
echo ""

gcloud config set project $PROJECT_ID

# 1. Create Pub/Sub topic for shutdown commands
TOPIC_NAME="budget-auto-shutdown"
if ! gcloud pubsub topics describe $TOPIC_NAME &>/dev/null; then
  echo "📢 Creating auto-shutdown Pub/Sub topic..."
  gcloud pubsub topics create $TOPIC_NAME
else
  echo "✅ Auto-shutdown topic already exists"
fi

# 2. Create Cloud Function for auto-shutdown
FUNCTION_NAME="budget-auto-shutdown"
FUNCTION_DIR="/tmp/shutdown-function-${PROJECT_ID}"

mkdir -p $FUNCTION_DIR

# Create package.json
cat > $FUNCTION_DIR/package.json <<'EOF'
{
  "name": "budget-auto-shutdown",
  "version": "1.0.0",
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0",
    "@google-cloud/run": "^1.0.0",
    "@google-cloud/compute": "^4.0.0"
  }
}
EOF

# Create index.js
cat > $FUNCTION_DIR/index.js <<'EOFJS'
const functions = require('@google-cloud/functions-framework');
const {RunServiceClient} = require('@google-cloud/run').v2;
const compute = require('@google-cloud/compute');

functions.cloudEvent('autoShutdown', async (cloudEvent) => {
  const data = Buffer.from(cloudEvent.data.message.data, 'base64').toString();
  const alert = JSON.parse(data);

  console.log('🛑 Budget exceeded! Initiating auto-shutdown...');
  console.log('Alert data:', alert);

  const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
  const environment = process.env.ENVIRONMENT;

  // Only allow auto-shutdown for staging
  if (environment !== 'staging') {
    console.log('⚠️ Auto-shutdown disabled for production. Manual intervention required.');
    return;
  }

  try {
    // 1. Scale down Cloud Run services to 0
    const runClient = new RunServiceClient();
    const region = process.env.GCP_REGION || 'us-central1';

    const [services] = await runClient.listServices({
      parent: `projects/${projectId}/locations/${region}`
    });

    for (const service of services) {
      console.log(`Scaling down Cloud Run service: ${service.name}`);

      // Update service to min instances = 0, max instances = 0
      await runClient.updateService({
        service: {
          name: service.name,
          template: {
            scaling: {
              minInstanceCount: 0,
              maxInstanceCount: 0
            }
          }
        },
        allowMissing: false
      });

      console.log(`✅ Scaled down: ${service.name}`);
    }

    // 2. Stop all Compute Engine instances (if any)
    const instancesClient = new compute.InstancesClient();
    const zonesClient = new compute.ZonesClient();

    const [zones] = await zonesClient.list({
      project: projectId,
      filter: 'name eq us-central1-.*'
    });

    for (const zone of zones) {
      const [instances] = await instancesClient.list({
        project: projectId,
        zone: zone.name
      });

      for (const instance of instances) {
        if (instance.status === 'RUNNING') {
          console.log(`Stopping instance: ${instance.name} in ${zone.name}`);
          await instancesClient.stop({
            project: projectId,
            zone: zone.name,
            instance: instance.name
          });
          console.log(`✅ Stopped: ${instance.name}`);
        }
      }
    }

    console.log('✅ Auto-shutdown completed successfully');
  } catch (error) {
    console.error('❌ Error during auto-shutdown:', error);
    throw error;
  }
});
EOFJS

echo ""
echo "☁️ Deploying auto-shutdown Cloud Function..."

# Deploy Cloud Function with appropriate permissions
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=$FUNCTION_DIR \
  --entry-point=autoShutdown \
  --trigger-topic=$TOPIC_NAME \
  --set-env-vars=ENVIRONMENT=$ENVIRONMENT,GCP_REGION=us-central1 \
  --service-account=github-actions-${ENVIRONMENT}@${PROJECT_ID}.iam.gserviceaccount.com

# Grant Cloud Run and Compute Engine admin permissions to function's service account
echo ""
echo "🔐 Granting permissions to function service account..."

SA_EMAIL="github-actions-${ENVIRONMENT}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/run.admin" \
  --condition=None || true

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/compute.instanceAdmin.v1" \
  --condition=None || true

# Cleanup
rm -rf $FUNCTION_DIR

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Auto-Shutdown Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 What was configured:"
echo "   ✅ Pub/Sub topic: projects/$PROJECT_ID/topics/$TOPIC_NAME"
echo "   ✅ Cloud Function: $FUNCTION_NAME"
echo ""
if [ "$ENVIRONMENT" = "staging" ]; then
  echo "   ✅ Auto-shutdown: ENABLED (will shut down when budget exceeded)"
else
  echo "   ⚠️ Auto-shutdown: DISABLED for production (requires manual intervention)"
fi
echo ""
echo "🔔 How it works:"
echo "   1. Budget alert triggers when 100% spent"
echo "   2. Notification function publishes to auto-shutdown topic"
echo "   3. Auto-shutdown function:"
if [ "$ENVIRONMENT" = "staging" ]; then
  echo "      • Scales Cloud Run services to 0 instances"
  echo "      • Stops all Compute Engine instances"
else
  echo "      • Logs alert (no automatic action for production)"
fi
echo ""
echo "🔗 View function logs:"
echo "   gcloud functions logs read $FUNCTION_NAME --region=us-central1"
echo ""
echo "📝 To manually trigger shutdown:"
echo "   gcloud pubsub topics publish $TOPIC_NAME --message='{\"manual\":true}'"
echo ""
