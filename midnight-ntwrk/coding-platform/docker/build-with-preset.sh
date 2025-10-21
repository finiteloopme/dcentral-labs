#!/bin/bash
#
# Build with predefined proof service configurations
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse preset
PRESET="${1:-local}"

case "$PRESET" in
    local)
        echo -e "${GREEN}Building with LOCAL proof service (simulation)${NC}"
        ./build.sh
        ;;
    
    midnight)
        echo -e "${BLUE}Building with MIDNIGHT proof service${NC}"
        ./build.sh \
            --proof-url "https://proof-api.midnight.network" \
            --proof-mode external
        ;;
    
    midnight-auth)
        if [ -z "$MIDNIGHT_API_KEY" ]; then
            echo -e "${YELLOW}Warning: MIDNIGHT_API_KEY not set${NC}"
            read -p "Enter Midnight API key: " -s MIDNIGHT_API_KEY
            echo
        fi
        echo -e "${BLUE}Building with MIDNIGHT proof service (authenticated)${NC}"
        ./build.sh \
            --proof-url "https://proof-api.midnight.network" \
            --proof-key "$MIDNIGHT_API_KEY" \
            --proof-mode external
        ;;
    
    custom)
        if [ -z "$PROOF_SERVICE_URL" ]; then
            read -p "Enter proof service URL: " PROOF_SERVICE_URL
        fi
        echo -e "${BLUE}Building with CUSTOM proof service${NC}"
        echo "  URL: $PROOF_SERVICE_URL"
        
        ARGS="--proof-url $PROOF_SERVICE_URL --proof-mode external"
        
        if [ -n "$PROOF_SERVICE_API_KEY" ]; then
            ARGS="$ARGS --proof-key $PROOF_SERVICE_API_KEY"
        fi
        
        ./build.sh $ARGS
        ;;
    
    *)
        echo "Usage: $0 [preset]"
        echo ""
        echo "Presets:"
        echo "  local         - Local simulation (default)"
        echo "  midnight      - Midnight proof service (no auth)"
        echo "  midnight-auth - Midnight proof service (with API key)"
        echo "  custom        - Custom proof service (uses env vars)"
        echo ""
        echo "Environment variables:"
        echo "  PROOF_SERVICE_URL     - Custom proof service URL"
        echo "  PROOF_SERVICE_API_KEY - API key for proof service"
        echo "  MIDNIGHT_API_KEY      - API key for Midnight service"
        echo ""
        echo "Examples:"
        echo "  $0 local"
        echo "  $0 midnight"
        echo "  MIDNIGHT_API_KEY=mykey $0 midnight-auth"
        echo "  PROOF_SERVICE_URL=https://my.service $0 custom"
        exit 1
        ;;
esac

echo -e "${GREEN}✓ Build complete${NC}"