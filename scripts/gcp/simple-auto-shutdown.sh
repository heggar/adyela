#!/bin/bash
set -e

# Simple Auto-Shutdown Script (manual trigger)
# This script scales down Cloud Run services when budget is exceeded
# Usage: ./simple-auto-shutdown.sh PROJECT_ID

PROJECT_ID=$1

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Usage: ./simple-auto-shutdown.sh PROJECT_ID"
  exit 1
fi

echo "🛑 Auto-Shutdown Script for $PROJECT_ID"
echo ""
echo "⚠️  WARNING: This will scale down all Cloud Run services to 0 instances"
read -p "Are you sure you want to proceed? (yes/NO) " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo "Cancelled."
  exit 0
fi

gcloud config set project $PROJECT_ID

# Get all Cloud Run services
SERVICES=$(gcloud run services list --region=us-central1 --format="value(metadata.name)")

if [ -z "$SERVICES" ]; then
  echo "No Cloud Run services found"
  exit 0
fi

echo "📋 Services to scale down:"
echo "$SERVICES"
echo ""

for service in $SERVICES; do
  echo "🔄 Scaling down $service..."

  gcloud run services update $service \
    --region=us-central1 \
    --min-instances=0 \
    --max-instances=0 \
    --quiet

  echo "✅ Scaled down: $service"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Auto-Shutdown Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "All Cloud Run services have been scaled to 0 instances."
echo ""
echo "To restore services, run:"
echo "  gcloud run services update SERVICE_NAME --region=us-central1 --min-instances=0 --max-instances=1"
echo ""
