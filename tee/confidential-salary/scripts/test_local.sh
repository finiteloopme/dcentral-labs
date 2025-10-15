#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo -e "${YELLOW}=== Local Testing Suite ===${NC}"
echo ""

# Check if binaries exist
if [ ! -f "server/target/release/server" ] || [ ! -f "client/target/release/client" ]; then
    echo -e "${YELLOW}Building applications...${NC}"
    ./scripts/build.sh
fi

# Function to cleanup background processes
cleanup() {
    if [ ! -z "$SERVER_PID" ]; then
        echo -e "\n${YELLOW}Stopping server...${NC}"
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Test modes
case "${1:-demo}" in
    demo)
        echo -e "${GREEN}Running demo test...${NC}"
        
        # Start server
        echo "Starting server..."
        RUST_LOG=info ./server/target/release/server &
        SERVER_PID=$!
        sleep 2
        
        # Check health
        echo -e "\n${YELLOW}Health check:${NC}"
        curl -s http://localhost:8080/health | jq . || echo "Health check failed"
        
        # Run demo
        echo -e "\n${YELLOW}Running client demo:${NC}"
        SERVER_URL=http://localhost:8080 ./client/target/release/client demo
        ;;
        
    interactive)
        echo -e "${GREEN}Running interactive test...${NC}"
        
        # Start server
        echo "Starting server..."
        RUST_LOG=info ./server/target/release/server &
        SERVER_PID=$!
        sleep 2
        
        # Run interactive client
        SERVER_URL=http://localhost:8080 ./client/target/release/client interactive
        ;;
        
    attestation)
        echo -e "${GREEN}Testing attestation modes...${NC}"
        
        # Test cloud attestation mode
        echo -e "\n${YELLOW}1. Testing Cloud Attestation Mode${NC}"
        RUST_LOG=info TDX_ENABLED=1 ./server/target/release/server &
        SERVER_PID=$!
        sleep 2
        
        SERVER_URL=http://localhost:8080 ./client/target/release/client health
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
        
        # Test raw attestation mode
        echo -e "\n${YELLOW}2. Testing Raw Attestation Mode${NC}"
        RUST_LOG=info TDX_ENABLED=1 USE_RAW_ATTESTATION=1 ./server/target/release/server &
        SERVER_PID=$!
        sleep 2
        
        SERVER_URL=http://localhost:8080 ./client/target/release/client health
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
        
        echo -e "\n${GREEN}✓ Both attestation modes tested${NC}"
        ;;
        
    stress)
        echo -e "${GREEN}Running stress test...${NC}"
        
        # Start server
        echo "Starting server..."
        RUST_LOG=warn ./server/target/release/server &
        SERVER_PID=$!
        sleep 2
        
        # Submit multiple salary entries
        echo -e "\n${YELLOW}Submitting 10 salary entries...${NC}"
        for i in {1..10}; do
            SALARY=$((80000 + RANDOM % 40000))
            echo "Entry $i: Software Engineer, \$$SALARY"
            SERVER_URL=http://localhost:8080 ./client/target/release/client submit \
                --role "Software Engineer" \
                --salary $SALARY \
                --location "San Francisco" \
                --years $i &
        done
        
        # Wait for all submissions
        wait
        
        echo -e "\n${GREEN}✓ Stress test complete${NC}"
        ;;
        
    compare)
        echo -e "${GREEN}Comparing attestation modes...${NC}"
        ./scripts/compare_attestation.sh
        ;;
        
    *)
        echo "Usage: $0 [demo|interactive|attestation|stress|compare]"
        echo ""
        echo "Modes:"
        echo "  demo         - Run demo with sample data (default)"
        echo "  interactive  - Interactive mode with prompts"
        echo "  attestation  - Test both attestation modes"
        echo "  stress       - Submit multiple entries"
        echo "  compare      - Compare attestation implementations"
        exit 1
        ;;
esac

echo -e "\n${GREEN}✓ Test complete${NC}"