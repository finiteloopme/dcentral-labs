#!/bin/bash
#
# Midnight Proof Verifier
# Attempts to use external proof service first, falls back to simulation
#

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to call external verification service
call_external_verify() {
    local proof_file="$1"
    local public_inputs="$2"
    
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
        echo -e "${GREEN}Using external verification service: $PROOF_SERVICE_URL${NC}"
        
        # Read proof file
        if [ ! -f "$proof_file" ]; then
            echo -e "${RED}Error: Proof file '$proof_file' not found${NC}"
            return 1
        fi
        
        local proof_content=$(cat "$proof_file")
        
        # Prepare request
        local request_json=$(cat <<EOF
{
    "proof": $proof_content,
    "publicInputs": ${public_inputs:-"[]"}
}
EOF
)
        
        # Call external service
        # Build curl command with optional auth header
        local curl_cmd="curl -s -X POST -H \"Content-Type: application/json\""
        if [ -n "$PROOF_SERVICE_API_KEY" ]; then
            curl_cmd="$curl_cmd -H \"Authorization: Bearer $PROOF_SERVICE_API_KEY\""
        fi
        # Remove trailing slash and add endpoint
        local service_url="${PROOF_SERVICE_URL%/}"
        curl_cmd="$curl_cmd -d '$request_json' \"${service_url}/api/proof/verify\""
        
        response=$(eval $curl_cmd 2>/dev/null)
        
        if [ $? -eq 0 ] && [ -n "$response" ]; then
            # Check verification result
            if echo "$response" | grep -q '"valid":\s*true'; then
                echo -e "${GREEN}✓ PROOF VERIFICATION SUCCESSFUL${NC}"
                if [ "$PROOF_SERVICE_URL" = "http://localhost:8081" ]; then
                    echo -e "${YELLOW}  Note: Using container proof service (development mode)${NC}"
                else
                    echo -e "${GREEN}  Service: ${service_url}${NC}"
                fi
                return 0
            elif echo "$response" | grep -q '"valid":\s*false'; then
                echo -e "${RED}✗ PROOF VERIFICATION FAILED${NC}"
                return 1
            fi
        fi
        
        echo -e "${YELLOW}Warning: Proof service not available, falling back to simulation${NC}"
        return 2
    fi
    
    return 2
}

# Function to perform simulated verification
simulate_verification() {
    local proof_file="$1"
    local public_inputs="$2"
    
    if [ ! -f "$proof_file" ]; then
        echo -e "${RED}Error: Proof file '$proof_file' not found${NC}"
        return 1
    fi
    
    # Check if this is a simulated proof
    local is_simulated=$(grep -q "_simulated" "$proof_file" 2>/dev/null && echo "true" || echo "false")
    
    if [ "$is_simulated" = "true" ]; then
        echo ""
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║                 ⚠️  SIMULATED VERIFICATION ⚠️                ║${NC}"
        echo -e "${YELLOW}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║  This proof was SIMULATED and is NOT cryptographically      ║${NC}"
        echo -e "${YELLOW}║  valid! Verification is being SIMULATED for testing only.   ║${NC}"
        echo -e "${YELLOW}║                                                              ║${NC}"
        echo -e "${YELLOW}║  Real verification requires:                                ║${NC}"
        echo -e "${YELLOW}║  1. Real proof from external service                        ║${NC}"
        echo -e "${YELLOW}║  2. Valid verification key                                  ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    else
        echo ""
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║               ⚠️  SIMULATION MODE WARNING ⚠️                  ║${NC}"
        echo -e "${YELLOW}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║  No external verification service configured!               ║${NC}"
        echo -e "${YELLOW}║  Running SIMULATED verification for development only.       ║${NC}"
        echo -e "${YELLOW}║                                                              ║${NC}"
        echo -e "${YELLOW}║  To verify real proofs, configure:                          ║${NC}"
        echo -e "${YELLOW}║    export PROOF_SERVICE_URL=https://your-proof-service      ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi
    
    echo -e "${BLUE}Simulating verification process...${NC}"
    echo "Loading proof from: $proof_file"
    echo "Checking proof structure..."
    
    # Check if proof has required fields
    local has_structure=true
    for field in "pi_a" "pi_b" "pi_c"; do
        if ! grep -q "\"$field\"" "$proof_file" 2>/dev/null; then
            has_structure=false
            echo -e "${RED}  Missing field: $field${NC}"
        else
            echo -e "  ✓ Found field: $field"
        fi
    done
    
    # Simulate verification delay
    echo -n "Simulating elliptic curve operations"
    for i in {1..5}; do
        echo -n "."
        sleep 0.1
    done
    echo ""
    
    # Result based on proof structure
    if [ "$has_structure" = "true" ]; then
        echo ""
        echo -e "${GREEN}✓ SIMULATED VERIFICATION: PASS${NC}"
        echo -e "${YELLOW}   (This is NOT a real cryptographic verification!)${NC}"
        echo ""
        echo "Simulated details:"
        echo "  Protocol: groth16"
        echo "  Curve: bn128"
        echo "  Public inputs: ${public_inputs:-none}"
        echo -e "  ${YELLOW}Status: SIMULATION ONLY - NOT VALID${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}✗ SIMULATED VERIFICATION: FAIL${NC}"
        echo "  Proof structure is invalid"
        return 1
    fi
}

# Main script
echo "Midnight Proof Verifier v1.0.0"
echo "======================================="

# Parse arguments
PROOF_FILE=""
PUBLIC_INPUTS=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--public-inputs)
            PUBLIC_INPUTS="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: verify [options] <proof-file>"
            echo ""
            echo "Options:"
            echo "  -p, --public-inputs <json>  Public inputs (JSON array)"
            echo "  -v, --verbose               Verbose output"
            echo "  -h, --help                  Show this help"
            echo ""
            echo "Environment variables:"
            echo "  PROOF_SERVICE_URL      External verification service URL"
            echo "  PROOF_SERVICE_API_KEY  API key for external service (optional)"
            echo ""
            echo "Examples:"
            echo "  verify proof.json"
            echo "  verify proof.json -p '[1, 2, 3]'"
            echo "  PROOF_SERVICE_URL=https://api.proof.com verify proof.json"
            echo "  PROOF_SERVICE_URL=https://api.proof.com PROOF_SERVICE_API_KEY=key verify proof.json"
            exit 0
            ;;
        *)
            PROOF_FILE="$1"
            shift
            ;;
    esac
done

# Validate inputs
if [ -z "$PROOF_FILE" ]; then
    echo -e "${RED}Error: Proof file required${NC}"
    echo "Usage: verify [options] <proof-file>"
    exit 1
fi

# Show configuration
if [ "$VERBOSE" = true ]; then
    echo "Configuration:"
    echo "  Proof file: $PROOF_FILE"
    echo "  Public inputs: ${PUBLIC_INPUTS:-<none>}"
    echo "  Verification Service: ${PROOF_SERVICE_URL:-<none - will use simulation>}"
    echo ""
fi

# Try external service first
call_external_verify "$PROOF_FILE" "$PUBLIC_INPUTS"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    # External verification succeeded
    echo -e "${GREEN}✓ Verification complete${NC}"
    exit 0
elif [ $exit_code -eq 1 ]; then
    # External verification failed (proof invalid)
    echo -e "${RED}✗ Verification failed - proof is invalid${NC}"
    exit 1
else
    # External service not available, fall back to simulation
    simulate_verification "$PROOF_FILE" "$PUBLIC_INPUTS"
    exit_code=$?
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Remember: This was a SIMULATED verification!${NC}"
        echo -e "${YELLOW}Configure PROOF_SERVICE_URL for real verification.${NC}"
    fi
    
    exit $exit_code
fi