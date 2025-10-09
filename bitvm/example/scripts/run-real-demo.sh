#!/bin/bash

# BitVM3 Real Demo Runner
# This script starts the verification engine and runs the real BitVM demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SERVER_PORT=${PORT:-8080}
API_URL="http://localhost:${SERVER_PORT}"
SERVER_PID=""

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    if [ ! -z "$SERVER_PID" ]; then
        echo -e "${YELLOW}Stopping verification engine (PID: $SERVER_PID)...${NC}"
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    fi
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Check if server is already running
check_server() {
    curl -s -o /dev/null -w "%{http_code}" "${API_URL}/api/v1/health" 2>/dev/null || echo "000"
}

echo -e "${BLUE}🔬 BitVM3 Real Demo Runner${NC}"
echo -e "================================\n"

# Check if server is already running
if [ "$(check_server)" == "200" ]; then
    echo -e "${YELLOW}⚠️  Verification engine already running on port ${SERVER_PORT}${NC}"
    echo -e "${BLUE}Using existing server...${NC}\n"
else
    # Build the verification engine
    echo -e "${YELLOW}Building verification engine...${NC}"
    cd verification-engine
    cargo build --release --bin bitvm3-server 2>/dev/null || {
        echo -e "${RED}❌ Failed to build verification engine${NC}"
        exit 1
    }
    echo -e "${GREEN}✅ Build successful${NC}\n"
    
    # Start the verification engine
    echo -e "${YELLOW}Starting verification engine on port ${SERVER_PORT}...${NC}"
    PORT=${SERVER_PORT} ./target/release/bitvm3-server &
    SERVER_PID=$!
    
    # Wait for server to be ready
    echo -e "${YELLOW}Waiting for server to be ready...${NC}"
    for i in {1..30}; do
        if [ "$(check_server)" == "200" ]; then
            echo -e "${GREEN}✅ Server is ready!${NC}\n"
            break
        fi
        if [ $i -eq 30 ]; then
            echo -e "${RED}❌ Server failed to start${NC}"
            exit 1
        fi
        sleep 1
    done
    
    cd ..
fi

# Run the real BitVM demo
echo -e "${BLUE}🚀 Running real BitVM demo...${NC}"
echo -e "================================\n"

cd vault-protocol
RUST_API_URL=${API_URL} npm run real-demo

echo -e "\n${GREEN}✨ Demo completed successfully!${NC}"