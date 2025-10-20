#!/bin/bash
# Open Cloud Workstation in browser

set -e

echo "=== Opening Cloud Workstation in Browser ==="
echo ""

# Configuration
WORKSTATION_NAME="${1:-midnight-developer-1}"
CLUSTER="${2:-midnight-dev-cluster}"
CONFIG="${3:-midnight-dev-config}"
REGION="${4:-us-central1}"
PROJECT="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"

if [ -z "$PROJECT" ]; then
    echo "Error: No project ID found"
    echo "Set PROJECT_ID or use: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

# Check if workstation is running
STATUS=$(gcloud workstations describe "$WORKSTATION_NAME" \
    --cluster="$CLUSTER" \
    --config="$CONFIG" \
    --region="$REGION" \
    --project="$PROJECT" \
    --format="value(state)" 2>/dev/null || echo "NOT_FOUND")

if [ "$STATUS" != "STATE_RUNNING" ]; then
    echo "Workstation is not running. Starting it..."
    gcloud workstations start "$WORKSTATION_NAME" \
        --cluster="$CLUSTER" \
        --config="$CONFIG" \
        --region="$REGION" \
        --project="$PROJECT"
    
    echo "Waiting for workstation to be ready..."
    sleep 30
fi

# Get workstation URL
URL=$(gcloud workstations describe "$WORKSTATION_NAME" \
    --cluster="$CLUSTER" \
    --config="$CONFIG" \
    --region="$REGION" \
    --project="$PROJECT" \
    --format="value(host)" 2>/dev/null || echo "")

if [ -n "$URL" ]; then
    FULL_URL="https://$URL"
    echo "Workstation URL: $FULL_URL"
    echo ""
    
    # Try to open in browser
    if command -v xdg-open &>/dev/null; then
        echo "Opening in default browser..."
        xdg-open "$FULL_URL"
    elif command -v open &>/dev/null; then
        echo "Opening in default browser..."
        open "$FULL_URL"
    else
        echo "Please open this URL in your browser:"
        echo "$FULL_URL"
    fi
else
    echo "Could not get workstation URL."
    echo "Access via Cloud Console:"
    echo "https://console.cloud.google.com/workstations/list?project=$PROJECT"
    
    # Try to open console
    if command -v xdg-open &>/dev/null; then
        xdg-open "https://console.cloud.google.com/workstations/list?project=$PROJECT"
    elif command -v open &>/dev/null; then
        open "https://console.cloud.google.com/workstations/list?project=$PROJECT"
    fi
fi