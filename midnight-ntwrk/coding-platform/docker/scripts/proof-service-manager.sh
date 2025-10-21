#!/bin/bash
#
# Unified Proof Service Manager for Midnight Development Platform
# 
# This script handles all proof service operations within the container.
# Port 8081: Internal mock server (inside container)
# Port 6300: External real server (outside container)
#

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INTERNAL_PORT=8081  # Mock server inside container
EXTERNAL_PORT=6300  # Real server outside container
PROOF_SERVER_DIR="/opt/midnight/proof-server"
LOG_FILE="/tmp/proof-server.log"
PID_FILE="/tmp/proof-server.pid"

# Function to check if we're in a container
is_container() {
    [ -f /.dockerenv ] || [ -n "$WORKSTATION_CLUSTER" ] || [ "$CONTAINER_ENV" = "midnight" ]
}

# Function to get the correct port based on environment
get_proof_port() {
    if [ "$PROOF_SERVICE_MODE" = "external" ]; then
        echo "$EXTERNAL_PORT"
    elif is_container; then
        echo "$INTERNAL_PORT"
    else
        echo "$EXTERNAL_PORT"
    fi
}

# Function to get the proof service URL
get_proof_url() {
    if [ -n "$PROOF_SERVICE_URL" ]; then
        echo "$PROOF_SERVICE_URL"
    elif [ "$PROOF_SERVICE_MODE" = "external" ]; then
        echo "${PROOF_SERVICE_URL:-http://localhost:$EXTERNAL_PORT}"
    elif is_container; then
        echo "http://localhost:$INTERNAL_PORT"
    else
        echo "http://localhost:$EXTERNAL_PORT"
    fi
}

# Start the mock proof server (container only)
start_mock_server() {
    if ! is_container; then
        echo -e "${RED}Error: Mock server only runs inside the container${NC}"
        echo "Use 'docker compose -f proof-server.yml up -d' to start the real server"
        return 1
    fi

    if [ ! -d "$PROOF_SERVER_DIR" ]; then
        echo -e "${RED}Error: Proof server not installed at $PROOF_SERVER_DIR${NC}"
        return 1
    fi

    # Check if already running
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo -e "${YELLOW}Mock proof server already running (PID: $(cat $PID_FILE))${NC}"
        return 0
    fi

    echo -e "${GREEN}Starting mock proof server on port $INTERNAL_PORT...${NC}"
    
    cd "$PROOF_SERVER_DIR"
    
    # Ensure dependencies are installed
    if [ ! -d "node_modules" ]; then
        echo "Installing dependencies..."
        npm install --production --silent
    fi
    
    # Start the server
    PORT=$INTERNAL_PORT nohup node src/server.js > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    
    # Wait and verify
    sleep 2
    if kill -0 $pid 2>/dev/null; then
        echo -e "${GREEN}✓ Mock proof server started${NC}"
        echo "  PID: $pid"
        echo "  Port: $INTERNAL_PORT"
        echo "  Logs: $LOG_FILE"
        echo "  URL: http://localhost:$INTERNAL_PORT"
        return 0
    else
        echo -e "${RED}✗ Failed to start mock proof server${NC}"
        [ -f "$LOG_FILE" ] && tail -5 "$LOG_FILE"
        return 1
    fi
}

# Stop the proof server
stop_server() {
    echo -e "${YELLOW}Stopping proof server...${NC}"
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            kill $pid
            rm -f "$PID_FILE"
            echo -e "${GREEN}✓ Proof server stopped (PID: $pid)${NC}"
        else
            echo -e "${YELLOW}Process not found, cleaning up PID file${NC}"
            rm -f "$PID_FILE"
        fi
    else
        echo -e "${YELLOW}No PID file found${NC}"
    fi
    
    # Also check for any orphaned processes
    pkill -f "proof-server.js" 2>/dev/null || true
}

# Check server status
check_status() {
    echo -e "${BLUE}=== Proof Service Status ===${NC}"
    echo ""
    
    # Show configuration
    echo -e "${BLUE}Configuration:${NC}"
    echo "  Environment: $(is_container && echo 'Container' || echo 'Standalone')"
    echo "  Mode: ${PROOF_SERVICE_MODE:-local}"
    
    if [ "$PROOF_SERVICE_MODE" = "external" ]; then
        echo "  External URL: ${PROOF_SERVICE_URL:-Not set}"
        
        # Test external service
        if [ -n "$PROOF_SERVICE_URL" ]; then
            if curl -s -f "$PROOF_SERVICE_URL/health" > /dev/null 2>&1; then
                echo -e "  Status: ${GREEN}✓ External service reachable${NC}"
            else
                echo -e "  Status: ${YELLOW}⚠ Cannot reach external service${NC}"
            fi
        fi
    else
        # Check local/mock server
        local port=$(get_proof_port)
        echo "  Port: $port"
        echo "  URL: http://localhost:$port"
        
        if [ -f "$PID_FILE" ]; then
            local pid=$(cat "$PID_FILE")
            if kill -0 $pid 2>/dev/null; then
                echo -e "  Status: ${GREEN}✓ Running (PID: $pid)${NC}"
                
                # Test endpoint
                if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
                    echo -e "  Health: ${GREEN}✓ Responding${NC}"
                else
                    echo -e "  Health: ${YELLOW}⚠ Not responding${NC}"
                fi
            else
                echo -e "  Status: ${RED}✗ Not running (stale PID)${NC}"
            fi
        else
            echo -e "  Status: ${RED}✗ Not running${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}Endpoints:${NC}"
    local url=$(get_proof_url)
    echo "  Health:   $url/health"
    echo "  Info:     $url/api/info"
    echo "  Generate: $url/api/proof/generate"
    echo "  Verify:   $url/api/proof/verify"
}

# Show logs
show_logs() {
    if [ "$PROOF_SERVICE_MODE" = "external" ]; then
        echo -e "${YELLOW}External service logs not available${NC}"
        return 1
    fi
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "${GREEN}=== Proof Server Logs ===${NC}"
        tail -f "$LOG_FILE"
    else
        echo -e "${RED}No log file found at $LOG_FILE${NC}"
        return 1
    fi
}

# Test the proof service
test_service() {
    echo -e "${BLUE}Testing proof service...${NC}"
    
    local url=$(get_proof_url)
    echo "Testing: $url"
    echo ""
    
    # Test health endpoint
    echo -n "Health check... "
    if response=$(curl -s "$url/health" 2>/dev/null); then
        echo -e "${GREEN}✓${NC}"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
    
    echo ""
    
    # Test proof generation
    echo -n "Proof generation... "
    local test_data='{"contract":"test","inputs":"test","protocol":"groth16"}'
    if response=$(curl -s -X POST "$url/api/proof/generate" \
        -H "Content-Type: application/json" \
        -d "$test_data" 2>/dev/null); then
        if echo "$response" | grep -q "proof\|pi_a"; then
            echo -e "${GREEN}✓${NC}"
            echo "$response" | jq '.proof' 2>/dev/null || echo "Proof generated"
        else
            echo -e "${YELLOW}⚠ Unexpected response${NC}"
            echo "$response" | head -c 100
        fi
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# Show help
show_help() {
    echo "Midnight Proof Service Manager"
    echo ""
    echo "Usage: $0 {start|stop|restart|status|logs|test|help}"
    echo ""
    echo "Commands:"
    echo "  start    - Start the proof server"
    echo "  stop     - Stop the proof server"
    echo "  restart  - Restart the proof server"
    echo "  status   - Check server status and configuration"
    echo "  logs     - Show server logs (tail -f)"
    echo "  test     - Test the proof service endpoints"
    echo "  help     - Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  PROOF_SERVICE_MODE    - 'local' or 'external' (default: local)"
    echo "  PROOF_SERVICE_URL     - URL for external service"
    echo "  PROOF_SERVICE_API_KEY - API key for external service (optional)"
    echo ""
    echo "Ports:"
    echo "  8081 - Internal mock server (container only)"
    echo "  6300 - External real server (Docker or remote)"
    echo ""
    echo "Examples:"
    echo "  # Inside container (uses mock server on 8081)"
    echo "  $0 start"
    echo ""
    echo "  # Use external service"
    echo "  export PROOF_SERVICE_MODE=external"
    echo "  export PROOF_SERVICE_URL=http://35.193.49.149:6300"
    echo "  $0 status"
}

# Main command handler
case "${1:-help}" in
    start)
        if [ "$PROOF_SERVICE_MODE" = "external" ]; then
            echo -e "${YELLOW}Using external proof service${NC}"
            check_status
        else
            start_mock_server
        fi
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        sleep 1
        start_mock_server
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs
        ;;
    test)
        test_service
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac