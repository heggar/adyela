#!/bin/bash

# Deploy Static Assets to Cloud Storage CDN
# This script separates static assets from the web app and uploads them to Cloud Storage

set -e

# Configuration
PROJECT_ID="adyela-staging"
BUCKET_NAME="adyela-staging-static-assets"
WEB_DIST_DIR="apps/web/dist"
STATIC_ASSETS_DIR="static-assets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting static assets deployment to CDN...${NC}"

# Check if web dist directory exists
if [ ! -d "$WEB_DIST_DIR" ]; then
    echo -e "${RED}❌ Error: Web dist directory not found at $WEB_DIST_DIR${NC}"
    echo -e "${YELLOW}💡 Please build the web app first: pnpm --filter @adyela/web build${NC}"
    exit 1
fi

# Create temporary directory for static assets
echo -e "${YELLOW}📁 Creating temporary directory for static assets...${NC}"
rm -rf "$STATIC_ASSETS_DIR"
mkdir -p "$STATIC_ASSETS_DIR"

# Copy static assets (JS, CSS, images, fonts, etc.)
echo -e "${YELLOW}📦 Copying static assets...${NC}"

# Copy JS and CSS files
find "$WEB_DIST_DIR" -name "*.js" -o -name "*.css" -o -name "*.js.map" -o -name "*.css.map" | while read file; do
    relative_path=${file#$WEB_DIST_DIR/}
    mkdir -p "$STATIC_ASSETS_DIR/$(dirname "$relative_path")"
    cp "$file" "$STATIC_ASSETS_DIR/$relative_path"
done

# Copy images and other static assets
find "$WEB_DIST_DIR" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.ico" -o -name "*.svg" -o -name "*.woff" -o -name "*.woff2" -o -name "*.ttf" -o -name "*.eot" | while read file; do
    relative_path=${file#$WEB_DIST_DIR/}
    mkdir -p "$STATIC_ASSETS_DIR/$(dirname "$relative_path")"
    cp "$file" "$STATIC_ASSETS_DIR/$relative_path"
done

# Copy assets directory if it exists
if [ -d "$WEB_DIST_DIR/assets" ]; then
    echo -e "${YELLOW}📁 Copying assets directory...${NC}"
    cp -r "$WEB_DIST_DIR/assets" "$STATIC_ASSETS_DIR/"
fi

# Set proper cache headers for different file types
echo -e "${YELLOW}⚙️  Setting cache headers...${NC}"

# Upload to Cloud Storage with appropriate cache headers
echo -e "${YELLOW}☁️  Uploading to Cloud Storage...${NC}"

# Upload JS and CSS files with short cache (for development)
find "$STATIC_ASSETS_DIR" -name "*.js" -o -name "*.css" | while read file; do
    relative_path=${file#$STATIC_ASSETS_DIR/}
    gsutil -h "Cache-Control:public,max-age=3600" cp "$file" "gs://$BUCKET_NAME/$relative_path"
done

# Upload images and fonts with long cache
find "$STATIC_ASSETS_DIR" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.ico" -o -name "*.svg" -o -name "*.woff" -o -name "*.woff2" -o -name "*.ttf" -o -name "*.eot" | while read file; do
    relative_path=${file#$STATIC_ASSETS_DIR/}
    gsutil -h "Cache-Control:public,max-age=31536000,immutable" cp "$file" "gs://$BUCKET_NAME/$relative_path"
done

# Upload assets directory
if [ -d "$STATIC_ASSETS_DIR/assets" ]; then
    gsutil -m -h "Cache-Control:public,max-age=31536000,immutable" cp -r "$STATIC_ASSETS_DIR/assets" "gs://$BUCKET_NAME/"
fi

# Make bucket publicly readable
echo -e "${YELLOW}🔓 Making bucket publicly readable...${NC}"
gsutil iam ch allUsers:objectViewer "gs://$BUCKET_NAME"

# Clean up temporary directory
echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
rm -rf "$STATIC_ASSETS_DIR"

echo -e "${GREEN}✅ Static assets successfully deployed to CDN!${NC}"
echo -e "${GREEN}🌐 CDN URL: https://storage.googleapis.com/$BUCKET_NAME/${NC}"
echo -e "${YELLOW}💡 Note: It may take a few minutes for CDN cache to propagate${NC}"

# Show uploaded files
echo -e "${YELLOW}📋 Uploaded files:${NC}"
gsutil ls -r "gs://$BUCKET_NAME" | head -20
if [ $(gsutil ls -r "gs://$BUCKET_NAME" | wc -l) -gt 20 ]; then
    echo -e "${YELLOW}... and $(($(gsutil ls -r "gs://$BUCKET_NAME" | wc -l) - 20)) more files${NC}"
fi
