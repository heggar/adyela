#!/bin/bash

# OAuth Testing Environment Setup Script
# This script starts all necessary services for local OAuth testing

set -e

echo "🚀 Starting OAuth Testing Environment..."
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down services...${NC}"
    if [ ! -z "$EMULATOR_PID" ]; then
        kill $EMULATOR_PID 2>/dev/null || true
    fi
    if [ ! -z "$API_PID" ]; then
        kill $API_PID 2>/dev/null || true
    fi
    if [ ! -z "$WEB_PID" ]; then
        kill $WEB_PID 2>/dev/null || true
    fi
    echo -e "${GREEN}✅ Cleanup completed${NC}"
    exit 0
}

# Set trap for cleanup
trap cleanup SIGINT SIGTERM

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI not found. Please install it first:${NC}"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if we're in the project root
if [ ! -f "firebase.json" ]; then
    echo -e "${RED}❌ firebase.json not found. Please run this script from the project root.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Starting Firebase Emulator...${NC}"
firebase emulators:start --only auth,firestore &
EMULATOR_PID=$!

# Wait for emulator to start
echo -e "${YELLOW}⏳ Waiting for Firebase Emulator to start...${NC}"
sleep 10

# Check if emulator is running
if ! curl -s http://localhost:9099 > /dev/null; then
    echo -e "${RED}❌ Firebase Auth Emulator failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Firebase Emulator started successfully${NC}"

echo -e "${BLUE}📋 Starting Backend API...${NC}"
cd apps/api
poetry run python -m adyela_api.main &
API_PID=$!
cd ../..

# Wait for API to start
echo -e "${YELLOW}⏳ Waiting for Backend API to start...${NC}"
sleep 5

# Check if API is running
if ! curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${RED}❌ Backend API failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Backend API started successfully${NC}"

echo -e "${BLUE}📋 Starting Frontend...${NC}"
cd apps/web
npm run dev &
WEB_PID=$!
cd ../..

# Wait for frontend to start
echo -e "${YELLOW}⏳ Waiting for Frontend to start...${NC}"
sleep 5

echo -e "${GREEN}🎉 OAuth Testing Environment Ready!${NC}"
echo "========================================"
echo -e "${BLUE}📱 Frontend:${NC} http://localhost:5173"
echo -e "${BLUE}🔧 Backend API:${NC} http://localhost:8000"
echo -e "${BLUE}🔥 Firebase Emulator UI:${NC} http://localhost:4000"
echo -e "${BLUE}🔐 Firebase Auth Emulator:${NC} http://localhost:9099"
echo ""
echo -e "${YELLOW}📝 Testing Instructions:${NC}"
echo "1. Open http://localhost:5173 in your browser"
echo "2. Navigate to the login page"
echo "3. Try the OAuth buttons (Google, Facebook, Apple, Microsoft)"
echo "4. Check Firebase Emulator UI for user creation"
echo "5. Check backend logs for API calls"
echo ""
echo -e "${YELLOW}🛑 Press Ctrl+C to stop all services${NC}"

# Wait for user to stop
wait
