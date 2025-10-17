#!/bin/bash
# Mock proof server startup script

echo "Starting Midnight Proof Server..."
echo "Mode: ${PROOF_SERVICE_MODE:-local}"
echo "Port: ${PROOF_SERVICE_PORT:-8080}"

if [ "${PROOF_SERVICE_MODE}" = "external" ]; then
    echo "Using external proof service at: ${PROOF_SERVICE_URL}"
    exit 0
fi

echo "Starting local proof service..."
cd /opt/midnight/proof-service
npm start