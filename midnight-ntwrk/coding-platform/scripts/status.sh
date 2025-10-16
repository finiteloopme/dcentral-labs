#!/bin/bash
# Check deployment status

set -e
source "$(dirname "$0")/common.sh"

# Check workstation status
check_workstation_status() {
    local project_id=$1
    local environment=$2
    local region=$3
    
    log_info "Checking deployment status..."
    
    echo ""
    echo "Workstation Cluster:"
    gcloud workstations clusters describe "midnight-${environment}-cluster" \
        --region="$region" \
        --project="$project_id" \
        --format="value(state)" 2>/dev/null || echo "Not deployed"
    
    echo ""
    echo "Workstation Config:"
    gcloud workstations configs describe "midnight-${environment}-config" \
        --cluster="midnight-${environment}-cluster" \
        --region="$region" \
        --project="$project_id" \
        --format="value(state)" 2>/dev/null || echo "Not deployed"
    
    echo ""
    echo "Workstation Instance:"
    gcloud workstations describe midnight-developer-1 \
        --config="midnight-${environment}-config" \
        --cluster="midnight-${environment}-cluster" \
        --region="$region" \
        --project="$project_id" \
        --format="value(state)" 2>/dev/null || echo "Not deployed"
}

# Get workstation URL
get_workstation_url() {
    if [ -f terraform/terraform.tfstate ]; then
        echo ""
        echo "Workstation URL:"
        cd terraform && terraform output workstation_url 2>/dev/null || echo "Not available"
        cd ..
    fi
}

# Main execution
main() {
    local project_id="${1:-$(get_project_id)}"
    local environment="${2:-mvp}"
    local region="${3:-us-central1}"
    
    if [ -z "$project_id" ]; then
        log_error "PROJECT_ID not set"
        exit 1
    fi
    
    check_workstation_status "$project_id" "$environment" "$region"
    get_workstation_url
}

main "$@"