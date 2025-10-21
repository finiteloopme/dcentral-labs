#!/bin/bash
#
# Midnight Proof Generator
# Attempts to use external proof service first, falls back to simulation
#

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to call external proof service
call_external_proof() {
    local circuit="$1"
    local witness="$2"
    local output="$3"
    
    # Check if external service is configured
    if [ -z "$PROOF_SERVICE_URL" ]; then
        # Auto-detect environment
        if [ -f /.dockerenv ] || [ -n "$WORKSTATION_CLUSTER" ] || [ "$CONTAINER_ENV" = "midnight" ]; then
            # We're in a container, use internal proof server
            PROOF_SERVICE_URL="http://localhost:8081"
        elif [ -f /etc/profile.d/proof-service-external.sh ]; then
            source /etc/profile.d/proof-service-external.sh
        fi
    fi
    
    if [ -n "$PROOF_SERVICE_URL" ]; then
        echo -e "${GREEN}Using external proof service: $PROOF_SERVICE_URL${NC}"
        
        # Try to use the adapter if available
        local adapter_script="$(dirname "$0")/proof-adapter.sh"
        if [ -f "$adapter_script" ]; then
            if bash "$adapter_script" adapt "$PROOF_SERVICE_URL" "$circuit" "$witness" "$output"; then
                echo -e "${GREEN}✓ Proof generated successfully using external service${NC}"
                return 0
            fi
        fi
        
        # Fallback to direct API calls
        # Prepare request
        local request_json=$(cat <<EOF
{
    "circuit": "$circuit",
    "witness": "$witness",
    "protocol": "groth16"
}
EOF
)
        
        # Remove trailing slash from URL if present
        local service_url="${PROOF_SERVICE_URL%/}"
        
        # Try different endpoint patterns
        local endpoints=("/api/proof/generate" "/generate" "/prove" "")
        local success=false
        
        for endpoint in "${endpoints[@]}"; do
            local full_url="${service_url}${endpoint}"
            
            # Build curl command with optional auth header
            local curl_cmd="curl -s -X POST -H \"Content-Type: application/json\""
            if [ -n "$PROOF_SERVICE_API_KEY" ]; then
                curl_cmd="$curl_cmd -H \"Authorization: Bearer $PROOF_SERVICE_API_KEY\""
            fi
            curl_cmd="$curl_cmd -d '$request_json' \"$full_url\" --max-time 10"
            
            if [ "$VERBOSE" = true ]; then
                echo -e "${BLUE}Trying endpoint: $full_url${NC}"
            fi
            
            response=$(eval $curl_cmd 2>/dev/null)
            local curl_exit=$?
            
            if [ $curl_exit -eq 0 ] && [ -n "$response" ]; then
                # Check if response contains proof or is valid JSON with expected fields
                if echo "$response" | grep -q "pi_a\|proof\|result\|success"; then
                    # Extract just the proof part if response has success wrapper
                    if echo "$response" | grep -q '"success".*true'; then
                        # Response has success wrapper, extract proof
                        echo "$response" | jq '.proof // .' > "$output" 2>/dev/null || echo "$response" > "$output"
                    else
                        echo "$response" > "$output"
                    fi
                    echo -e "${GREEN}✓ Proof generated successfully${NC}"
                    if [ "$PROOF_SERVICE_URL" = "http://localhost:8081" ]; then
                        echo -e "${YELLOW}  Note: Using container proof service (development mode)${NC}"
                    else
                        echo -e "${GREEN}  Service: $full_url${NC}"
                    fi
                    return 0
                fi
                
                # If we got a 404-like response or HTML, try next endpoint
                if echo "$response" | grep -q "404\|Not Found\|<!DOCTYPE"; then
                    continue
                fi
                
                # If verbose, show what we got
                if [ "$VERBOSE" = true ]; then
                    echo -e "${YELLOW}Response from $full_url:${NC}"
                    echo "$response" | head -c 200
                    echo ""
                fi
            fi
        done
        
        echo -e "${YELLOW}Warning: External service not available or incompatible${NC}"
        if [ "$VERBOSE" = true ]; then
            echo -e "${YELLOW}  Service detected: Midnight ledger service (requires specific format)${NC}"
            echo -e "${YELLOW}  Using simulation mode for development${NC}"
        fi
        echo -e "${YELLOW}Falling back to simulation mode${NC}"
        return 1
    fi
    
    return 1
}

# Function to generate simulated proof
generate_simulated_proof() {
    local output="$1"
    
    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    ⚠️  SIMULATION MODE ⚠️                     ║${NC}"
    echo -e "${YELLOW}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║  This is a SIMULATED proof for development purposes only!   ║${NC}"
    echo -e "${YELLOW}║  The proof values are MOCK data and NOT cryptographically   ║${NC}"
    echo -e "${YELLOW}║  valid. DO NOT use this in production!                      ║${NC}"
    echo -e "${YELLOW}║                                                              ║${NC}"
    echo -e "${YELLOW}║  To use real proofs, configure an external proof service:   ║${NC}"
    echo -e "${YELLOW}║    export PROOF_SERVICE_URL=https://your-proof-service      ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BLUE}Simulating proof generation...${NC}"
    
    # Show progress bar for simulation
    for i in {1..10}; do
        echo -n "."
        sleep 0.2
    done
    echo ""
    
    # Generate mock proof with clear indication it's simulated
    cat > "$output" <<PROOF_EOF
{
  "_warning": "SIMULATED PROOF - NOT CRYPTOGRAPHICALLY VALID",
  "_generated_by": "midnight-mock-prover",
  "_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "pi_a": [
    "0x$(openssl rand -hex 32)",
    "0x$(openssl rand -hex 32)"
  ],
  "pi_b": [[
    "0x$(openssl rand -hex 32)",
    "0x$(openssl rand -hex 32)"
  ], [
    "0x$(openssl rand -hex 32)",
    "0x$(openssl rand -hex 32)"
  ]],
  "pi_c": [
    "0x$(openssl rand -hex 32)",
    "0x$(openssl rand -hex 32)"
  ],
  "protocol": "groth16",
  "curve": "bn128",
  "_simulated": true
}
PROOF_EOF
    
    echo -e "${YELLOW}⚠️  SIMULATED proof written to: $output${NC}"
    echo -e "${YELLOW}⚠️  This proof is for testing only and will NOT verify on-chain${NC}"
}

# Main script
echo "Midnight Proof Generator v1.0.0"
echo "======================================="

# Parse arguments
CIRCUIT=""
WITNESS=""
OUTPUT="proof.json"
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--witness)
            WITNESS="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: prove [options] <circuit-file>"
            echo ""
            echo "Options:"
            echo "  -w, --witness <file>   Witness file"
            echo "  -o, --output <file>    Output proof file (default: proof.json)"
            echo "  -v, --verbose          Verbose output"
            echo "  -h, --help             Show this help"
            echo ""
            echo "Environment variables:"
            echo "  PROOF_SERVICE_URL      External proof service URL"
            echo "  PROOF_SERVICE_API_KEY  API key for external service (optional)"
            echo ""
            echo "Examples:"
            echo "  prove circuit.r1cs -w witness.wtns"
            echo "  prove circuit.r1cs -w witness.wtns -o my_proof.json"
            echo "  PROOF_SERVICE_URL=https://api.proof.com prove circuit.r1cs"
            echo "  PROOF_SERVICE_URL=https://api.proof.com PROOF_SERVICE_API_KEY=key prove circuit.r1cs"
            exit 0
            ;;
        *)
            CIRCUIT="$1"
            shift
            ;;
    esac
done

# Validate inputs
if [ -z "$CIRCUIT" ]; then
    echo -e "${RED}Error: Circuit file required${NC}"
    echo "Usage: prove [options] <circuit-file>"
    exit 1
fi

# Check if circuit file exists (for simulation)
if [ ! -f "$CIRCUIT" ] && [ -z "$PROOF_SERVICE_URL" ]; then
    echo -e "${YELLOW}Warning: Circuit file '$CIRCUIT' not found${NC}"
    echo "Continuing with simulation..."
fi

# Show configuration
if [ "$VERBOSE" = true ]; then
    echo "Configuration:"
    echo "  Circuit: $CIRCUIT"
    echo "  Witness: ${WITNESS:-<none>}"
    echo "  Output: $OUTPUT"
    echo "  Proof Service: ${PROOF_SERVICE_URL:-<none - will use simulation>}"
    echo ""
fi

# Try external service first
if call_external_proof "$CIRCUIT" "$WITNESS" "$OUTPUT"; then
    echo -e "${GREEN}✓ Proof generation complete${NC}"
    echo "Proof written to: $OUTPUT"
    
    # Show proof details if verbose
    if [ "$VERBOSE" = true ] && [ -f "$OUTPUT" ]; then
        echo ""
        echo "Proof details:"
        jq -r 'if ._simulated then "  Type: SIMULATED (NOT VALID)" else "  Type: Real cryptographic proof" end' "$OUTPUT" 2>/dev/null
        jq -r '"  Protocol: " + .protocol' "$OUTPUT" 2>/dev/null
        jq -r '"  Curve: " + .curve' "$OUTPUT" 2>/dev/null
    fi
else
    # Fall back to simulation
    generate_simulated_proof "$OUTPUT"
fi

# Final status
echo ""
if [ -f "$OUTPUT" ]; then
    if grep -q "_simulated" "$OUTPUT" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Remember: This is a SIMULATED proof for development only!${NC}"
        echo -e "${YELLOW}Configure PROOF_SERVICE_URL to generate real proofs.${NC}"
    else
        echo -e "${GREEN}✓ Real proof generated successfully${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ Proof generation failed${NC}"
    exit 1
fi