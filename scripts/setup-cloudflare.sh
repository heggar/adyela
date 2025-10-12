#!/bin/bash

# Setup Cloudflare CDN for Adyela
# This script helps configure Cloudflare for the Adyela project

set -e

echo "🚀 Setting up Cloudflare CDN for Adyela..."

# Check if CLOUDFLARE_API_TOKEN is set
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "❌ Error: CLOUDFLARE_API_TOKEN environment variable is not set"
    echo ""
    echo "To get your Cloudflare API token:"
    echo "1. Go to https://dash.cloudflare.com/profile/api-tokens"
    echo "2. Click 'Create Token'"
    echo "3. Use 'Custom token' template"
    echo "4. Set permissions:"
    echo "   - Zone:Zone:Read"
    echo "   - Zone:DNS:Edit"
    echo "   - Zone:Page Rules:Edit"
    echo "   - Zone:Cache Purge:Edit"
    echo "   - Zone:Zone Settings:Edit"
    echo "5. Set Zone Resources: Include - Specific zone - adyela.care"
    echo "6. Copy the token and set it as CLOUDFLARE_API_TOKEN"
    echo ""
    echo "Example:"
    echo "export CLOUDFLARE_API_TOKEN='your-token-here'"
    exit 1
fi

# Check if domain is already in Cloudflare
echo "🔍 Checking if adyela.care is already in Cloudflare..."

if curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=adyela.care" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" | grep -q '"name":"adyela.care"'; then
    echo "✅ Domain adyela.care is already in Cloudflare"
else
    echo "❌ Domain adyela.care is not in Cloudflare"
    echo ""
    echo "To add your domain to Cloudflare:"
    echo "1. Go to https://dash.cloudflare.com/"
    echo "2. Click 'Add a Site'"
    echo "3. Enter 'adyela.care'"
    echo "4. Choose the Free plan"
    echo "5. Follow the setup instructions"
    echo ""
    echo "After adding the domain, run this script again."
    exit 1
fi

# Get zone ID
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=adyela.care" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" | \
    jq -r '.result[0].id')

if [ "$ZONE_ID" = "null" ] || [ -z "$ZONE_ID" ]; then
    echo "❌ Could not get zone ID for adyela.care"
    exit 1
fi

echo "✅ Zone ID: $ZONE_ID"

# Check current DNS records
echo "🔍 Checking current DNS records..."

curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" | \
    jq '.result[] | {name: .name, type: .type, content: .content, proxied: .proxied}'

echo ""
echo "✅ Cloudflare setup verification complete!"
echo ""
echo "Next steps:"
echo "1. Run 'terraform plan' to see what will be created"
echo "2. Run 'terraform apply' to create Cloudflare resources"
echo "3. Update your domain's nameservers to point to Cloudflare"
echo ""
echo "Current Load Balancer IP: 34.96.108.162"
echo "This will be used for the DNS records."
