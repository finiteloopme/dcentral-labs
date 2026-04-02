#!/usr/bin/env bash
#
# health.sh - Probe the load balancer health endpoint.
#
# Usage:
#   bash scripts/health.sh          # auto-discover LB IP from gcloud
#   bash scripts/health.sh <IP>     # use a specific IP
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ---------------------------------------------------------------------------
# Discover LB IP
# ---------------------------------------------------------------------------
get_lb_ip() {
    local ip
    ip="$(gcloud compute addresses describe "${APP_NAME}-lb-ip" \
        --global \
        --project="$GCP_PROJECT_ID" \
        --format='value(address)' 2>/dev/null || true)"

    if [[ -z "$ip" ]]; then
        log_error "Could not find LB IP. Is the infrastructure deployed?"
        exit 1
    fi

    echo "$ip"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
LB_IP="${1:-$(get_lb_ip)}"

echo ""
log_info "Probing load balancer at $LB_IP"
echo ""

echo "--- GET /health ---"
curl -sf "http://${LB_IP}/health" | python3 -m json.tool 2>/dev/null || \
    curl -s "http://${LB_IP}/health"
echo ""

echo "--- GET / ---"
curl -sf "http://${LB_IP}/" | python3 -m json.tool 2>/dev/null || \
    curl -s "http://${LB_IP}/"
echo ""

log_info "Done."
