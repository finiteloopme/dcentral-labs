#!/bin/bash

# Open workstation in browser

set -e

WORKSTATION_NAME="$1"
CLUSTER_NAME="$2"
CONFIG_NAME="$3"
REGION="$4"

if [ -z "$WORKSTATION_NAME" ] || [ -z "$CLUSTER_NAME" ] || [ -z "$CONFIG_NAME" ] || [ -z "$REGION" ]; then
    echo "Usage: $0 WORKSTATION_NAME CLUSTER_NAME CONFIG_NAME REGION"
    exit 1
fi

# Get the workstation URL
URL=$(gcloud workstations describe "$WORKSTATION_NAME" \
    --cluster="$CLUSTER_NAME" \
    --config="$CONFIG_NAME" \
    --region="$REGION" \
    --format="value(host)")

if [ -z "$URL" ]; then
    echo "Failed to get workstation URL. Is the workstation running?"
    exit 1
fi

# Open in browser
if command -v xdg-open &> /dev/null; then
    xdg-open "https://$URL"
elif command -v open &> /dev/null; then
    open "https://$URL"
else
    echo "Could not open browser. Please visit: https://$URL"
fi