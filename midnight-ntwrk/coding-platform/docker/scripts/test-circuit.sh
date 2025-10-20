#!/bin/bash
# Test a specific circuit by generating and verifying a proof

set -e

CIRCUIT_NAME="${1:-proveBalance}"
BUILD_DIR="build/circuits"

echo "Testing circuit: $CIRCUIT_NAME"
echo "================================"

# Check if circuit is compiled
if [ ! -f "$BUILD_DIR/${CIRCUIT_NAME}.json" ]; then
    echo "Circuit not compiled. Running compilation..."
    make compile-circuits
fi

if [ ! -f "$BUILD_DIR/${CIRCUIT_NAME}.json" ]; then
    echo "Error: Circuit compilation failed or circuit not found"
    exit 1
fi

echo ""
echo "1. Generating proof for $CIRCUIT_NAME..."
echo "-----------------------------------"

# Generate proof
prove "$BUILD_DIR/${CIRCUIT_NAME}.json" -o "$BUILD_DIR/${CIRCUIT_NAME}.proof"

if [ ! -f "$BUILD_DIR/${CIRCUIT_NAME}.proof" ]; then
    echo "Error: Proof generation failed"
    exit 1
fi

echo "✓ Proof generated: $BUILD_DIR/${CIRCUIT_NAME}.proof"

echo ""
echo "2. Verifying proof..."
echo "--------------------"

# Verify proof
verify "$BUILD_DIR/${CIRCUIT_NAME}.proof"

if [ $? -eq 0 ]; then
    echo "✓ Proof verification successful!"
else
    echo "✗ Proof verification failed"
    exit 1
fi

echo ""
echo "3. Proof details:"
echo "----------------"

# Show proof details
if command -v jq &> /dev/null; then
    echo "Proof commitment:"
    jq -r '.proof.commitment // .commitment' "$BUILD_DIR/${CIRCUIT_NAME}.proof" 2>/dev/null || echo "N/A"
    
    echo "Proof metadata:"
    jq '.metadata' "$BUILD_DIR/${CIRCUIT_NAME}.proof" 2>/dev/null || echo "N/A"
else
    echo "Proof file contents:"
    head -20 "$BUILD_DIR/${CIRCUIT_NAME}.proof"
fi

echo ""
echo "================================"
echo "✅ Circuit test completed successfully!"
echo ""
echo "Next steps:"
echo "  - Test other circuits: $0 proveTransfer"
echo "  - Run all tests: make test"
echo "  - Deploy contract: make deploy"