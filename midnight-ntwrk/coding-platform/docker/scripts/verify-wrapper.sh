#!/bin/bash
#
# Verify Command Wrapper
# Automatically uses the container proof server for verification
#

# Set container environment flag
export CONTAINER_ENV=midnight

# Auto-detect and set proof service URL if not set
if [ -z "$PROOF_SERVICE_URL" ]; then
    if [ -f /.dockerenv ] || [ -n "$WORKSTATION_CLUSTER" ]; then
        export PROOF_SERVICE_URL="http://localhost:8081"
    fi
fi

# Call the main verify script
exec /docker/scripts/verify.sh "$@"