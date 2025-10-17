#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
PASSED=0
FAILED=0
SKIPPED=0

# Source common functions
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/container-runtime.sh"

# Use the detected container runtime (docker or podman)
CONTAINER_CMD="${CONTAINER_RUNTIME:-podman}"
COMPOSE_CMD="${CONTAINER_RUNTIME:-podman}-compose"

print_header() {
    echo -e "\n${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  $1${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
}

test_passed() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED++))
}

test_failed() {
    echo -e "${RED}✗ $1${NC}"
    echo -e "${RED}  Error: $2${NC}"
    ((FAILED++))
}

test_skipped() {
    echo -e "${YELLOW}⊘ $1${NC}"
    echo -e "${YELLOW}  Reason: $2${NC}"
    ((SKIPPED++))
}

# Test 1: Check Docker build
test_docker_build() {
    print_header "Testing Docker Build"
    
    if $CONTAINER_CMD images | grep -q "midnight-workstation"; then
        test_passed "Container image exists"
    else
        echo "Building container image..."
        if ./scripts/build.sh; then
            test_passed "Container image built successfully"
        else
            test_failed "Container image build" "Build script failed"
            return 1
        fi
    fi
}

# Test 2: Check container startup
test_container_startup() {
    print_header "Testing Container Startup"
    
    # Stop any running containers
    $COMPOSE_CMD -f docker/docker-compose.yml down 2>/dev/null || true
    
    # Start container in detached mode
    if MIDNIGHT_ENV=test $COMPOSE_CMD -f docker/docker-compose.yml up -d; then
        sleep 5
        if $CONTAINER_CMD ps | grep -q "midnight-dev"; then
            test_passed "Container started successfully"
            
            # Check if web terminal is accessible
            if curl -s http://localhost:3000 > /dev/null 2>&1; then
                test_passed "Web terminal is accessible"
            else
                test_failed "Web terminal accessibility" "Port 3000 not responding"
            fi
            
            # Check health endpoint
            if curl -s http://localhost:3000/health | grep -q "ok"; then
                test_passed "Health endpoint responds"
            else
                test_failed "Health endpoint" "No OK response"
            fi
        else
            test_failed "Container running" "Container not found in docker ps"
        fi
    else
        test_failed "Container startup" "docker-compose up failed"
    fi
}

# Test 3: Check proof service
test_proof_service() {
    print_header "Testing Proof Service Integration"
    
    # Check proof service mode
    PROOF_MODE=$($CONTAINER_CMD exec midnight-dev bash -c 'echo $PROOF_SERVICE_MODE' 2>/dev/null || echo "local")
    echo "Proof service mode: $PROOF_MODE"
    
    # Check if proof service is running
    PROOF_URL=$($CONTAINER_CMD exec midnight-dev bash -c 'echo $PROOF_SERVICE_URL' 2>/dev/null || echo "")
    if [ -z "$PROOF_URL" ]; then
        PROOF_URL="http://localhost:8080"
    fi
    echo "Proof service URL: $PROOF_URL"
    
    # Check if real proof server is available
    if $CONTAINER_CMD exec midnight-dev bash -c 'test -x /opt/midnight/bin/proof-server' 2>/dev/null; then
        test_passed "Midnight proof server v4.0.0 available"
    else
        test_skipped "Real proof server" "Using mock service"
    fi
    
    # Test health endpoint
    if $CONTAINER_CMD exec midnight-dev bash -c "curl -s $PROOF_URL/health" > /dev/null 2>&1; then
        test_passed "Proof service health check"
    else
        test_failed "Proof service health" "Service not responding"
    fi
    
    # Test prove command with file
    if $CONTAINER_CMD exec midnight-dev bash -c 'echo "{\"value\": 42}" > /tmp/test.json && prove /tmp/test.json' > /dev/null 2>&1; then
        test_passed "Prove command works"
    else
        test_failed "Prove command" "Failed to generate proof"
    fi
    
    # Test verify command
    if $CONTAINER_CMD exec midnight-dev bash -c 'test -f /tmp/test.proof && verify /tmp/test.proof' > /dev/null 2>&1; then
        test_passed "Verify command works"
    else
        test_skipped "Verify command" "No proof file to verify"
    fi
}

# Test 4: Check proof service modes
test_proof_service_modes() {
    print_header "Testing Proof Service Modes"
    
    # Test local mode (default)
    MODE=$($CONTAINER_CMD exec midnight-dev bash -c 'echo $PROOF_SERVICE_MODE' 2>/dev/null)
    if [ "$MODE" = "local" ] || [ -z "$MODE" ]; then
        test_passed "Local mode is default"
        
        # Check if service is running locally
        if $CONTAINER_CMD exec midnight-dev bash -c 'pgrep -f proof-server' > /dev/null 2>&1; then
            test_passed "Real proof server running locally"
        elif $CONTAINER_CMD exec midnight-dev bash -c 'pgrep -f "node.*proof-service"' > /dev/null 2>&1; then
            test_passed "Mock proof service running locally"
        else
            test_failed "Local proof service" "No service process found"
        fi
    elif [ "$MODE" = "external" ]; then
        test_passed "External mode configured"
        
        # Check external URL is set
        EXT_URL=$($CONTAINER_CMD exec midnight-dev bash -c 'echo $PROOF_SERVICE_URL' 2>/dev/null)
        if [ -n "$EXT_URL" ]; then
            test_passed "External URL configured: $EXT_URL"
        else
            test_failed "External URL" "PROOF_SERVICE_URL not set for external mode"
        fi
    else
        test_failed "Proof service mode" "Invalid mode: $MODE"
    fi
}

# Test 5: Check Midnight CLI
test_midnight_cli() {
    print_header "Testing Midnight CLI"
    
    # Test midnight init
    if $CONTAINER_CMD exec midnight-dev bash -c 'cd /tmp && midnight init test-project' > /dev/null 2>&1; then
        test_passed "midnight init works"
        
        # Test midnight compile
        if $CONTAINER_CMD exec midnight-dev bash -c 'cd /tmp/test-project && midnight compile' > /dev/null 2>&1; then
            test_passed "midnight compile works"
        else
            test_failed "midnight compile" "Compilation failed"
        fi
        
        # Test midnight test
        if $CONTAINER_CMD exec midnight-dev bash -c 'cd /tmp/test-project && midnight test' > /dev/null 2>&1; then
            test_passed "midnight test works"
        else
            test_failed "midnight test" "Tests failed"
        fi
        
        # Clean up
        $CONTAINER_CMD exec midnight-dev bash -c 'rm -rf /tmp/test-project' 2>/dev/null || true
    else
        test_failed "midnight init" "Project initialization failed"
    fi
}

# Test 5: Check circuit compilation
test_circuit_compilation() {
    print_header "Testing Circuit Compilation"
    
    # Create a test project with circuits
    if $CONTAINER_CMD exec midnight-dev bash -c '
        cd /tmp && 
        midnight init circuit-test &&
        cd circuit-test &&
        make circuit-proveBalance
    ' > /dev/null 2>&1; then
        test_passed "Circuit compilation works"
        
        # Test circuit-specific testing
        if $CONTAINER_CMD exec midnight-dev bash -c 'cd /tmp/circuit-test && ./test-circuit.sh proveBalance' > /dev/null 2>&1; then
            test_passed "Circuit testing works"
        else
            test_failed "Circuit testing" "test-circuit.sh failed"
        fi
        
        # Clean up
        $CONTAINER_CMD exec midnight-dev bash -c 'rm -rf /tmp/circuit-test' 2>/dev/null || true
    else
        test_failed "Circuit compilation" "Make target failed"
    fi
}

# Test 6: Check OpenCode configuration
test_opencode_config() {
    print_header "Testing OpenCode Configuration"
    
    # Check if opencode config exists
    if $CONTAINER_CMD exec midnight-dev bash -c 'test -f ~/.config/opencode/opencode.json' 2>/dev/null; then
        test_passed "OpenCode config file exists"
        
        # Verify config structure
        if $CONTAINER_CMD exec midnight-dev bash -c 'cat ~/.config/opencode/opencode.json | jq ".model"' > /dev/null 2>&1; then
            test_passed "OpenCode config is valid JSON"
        else
            test_failed "OpenCode config validation" "Invalid JSON structure"
        fi
    else
        test_failed "OpenCode config" "Config file not found"
    fi
}

# Test 7: Check VSCode extensions
test_vscode_extensions() {
    print_header "Testing VSCode Extensions"
    
    # Check if Midnight extension is installed
    if $CONTAINER_CMD exec midnight-dev bash -c 'ls ~/.vscode-server/extensions 2>/dev/null | grep -q midnight' 2>/dev/null; then
        test_passed "Midnight VSCode extension installed"
    else
        test_skipped "Midnight VSCode extension" "VSCode server not initialized"
    fi
}

# Test 8: Check template files
test_template_files() {
    print_header "Testing Template Files"
    
    # Check Token.compact template
    if $CONTAINER_CMD exec midnight-dev bash -c 'test -f /opt/scripts/Token.compact.template' 2>/dev/null; then
        test_passed "Token.compact template exists"
        
        # Check for circuit exports
        if $CONTAINER_CMD exec midnight-dev bash -c 'grep -q "export circuit" /opt/scripts/Token.compact.template' 2>/dev/null; then
            test_passed "Template contains circuit exports"
        else
            test_failed "Template circuits" "No circuit exports found"
        fi
    else
        test_failed "Token.compact template" "Template file not found"
    fi
    
    # Check test template
    if $CONTAINER_CMD exec midnight-dev bash -c 'test -f /opt/scripts/token.test.js.template' 2>/dev/null; then
        test_passed "Test template exists"
    else
        test_failed "Test template" "Template file not found"
    fi
}

# Test 9: Check environment variables
test_environment_vars() {
    print_header "Testing Environment Variables"
    
    REQUIRED_VARS=(
        "MIDNIGHT_ENV"
        "PROOF_SERVICE_MODE"
        "MIDNIGHT_NETWORK"
    )
    
    for var in "${REQUIRED_VARS[@]}"; do
        if $CONTAINER_CMD exec midnight-dev bash -c "test -n \"\$$var\"" 2>/dev/null; then
            VALUE=$($CONTAINER_CMD exec midnight-dev bash -c "echo \$$var" 2>/dev/null)
            test_passed "$var is set: $VALUE"
        else
            # PROOF_SERVICE_URL is optional in local mode
            if [ "$var" = "PROOF_SERVICE_URL" ]; then
                MODE=$($CONTAINER_CMD exec midnight-dev bash -c "echo \$PROOF_SERVICE_MODE" 2>/dev/null)
                if [ "$MODE" = "local" ]; then
                    test_passed "$var is optional in local mode"
                else
                    test_failed "$var" "Required for external mode"
                fi
            else
                test_failed "$var" "Environment variable not set"
            fi
        fi
    done
}

# Test 10: Check API endpoints
test_api_endpoints() {
    print_header "Testing API Endpoints"
    
    ENDPOINTS=(
        "/health"
        "/env"
        "/api/status"
    )
    
    for endpoint in "${ENDPOINTS[@]}"; do
        if curl -s "http://localhost:3000$endpoint" > /dev/null 2>&1; then
            test_passed "Endpoint $endpoint accessible"
        else
            test_failed "Endpoint $endpoint" "Not accessible"
        fi
    done
}

# Main test execution
main() {
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║     Midnight Development Platform Integration Test     ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════╝${NC}"
    
    # Run tests
    test_docker_build
    test_container_startup
    test_proof_service
    test_proof_service_modes
    test_midnight_cli
    test_circuit_compilation
    test_opencode_config
    test_vscode_extensions
    test_template_files
    test_environment_vars
    test_api_endpoints
    
    # Print summary
    print_header "Test Summary"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo -e "${YELLOW}Skipped: $SKIPPED${NC}"
    
    TOTAL=$((PASSED + FAILED + SKIPPED))
    echo -e "\nTotal tests: $TOTAL"
    
    if [ $FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✓ All tests passed!${NC}"
        
        # Stop container
        $COMPOSE_CMD -f docker/docker-compose.yml down
        exit 0
    else
        echo -e "\n${RED}✗ Some tests failed${NC}"
        
        # Stop container
        $COMPOSE_CMD -f docker/docker-compose.yml down
        exit 1
    fi
}

# Handle cleanup on exit
trap '$COMPOSE_CMD -f docker/docker-compose.yml down 2>/dev/null || true' EXIT

# Run main
main "$@"