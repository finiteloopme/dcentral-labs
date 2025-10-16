#!/bin/bash
# Workstation management script

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Default configuration
DEFAULT_PROJECT_ID=$(get_project_id)
DEFAULT_REGION="us-central1"
DEFAULT_ENV="mvp"
DEFAULT_WORKSTATION="midnight-developer-1"

# Parse command line arguments
parse_args() {
    PROJECT_ID="${PROJECT_ID:-$DEFAULT_PROJECT_ID}"
    REGION="${REGION:-$DEFAULT_REGION}"
    ENV="${ENV:-$DEFAULT_ENV}"
    WORKSTATION_ID="${WORKSTATION_ID:-$DEFAULT_WORKSTATION}"
    
    # Parse named arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project-id|--project)
                PROJECT_ID="$2"
                shift 2
                ;;
            --region)
                REGION="$2"
                shift 2
                ;;
            --env|--environment)
                ENV="$2"
                shift 2
                ;;
            --workstation|--id)
                WORKSTATION_ID="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                COMMAND="$1"
                shift
                break
                ;;
        esac
    done
    
    # Remaining arguments
    ARGS=("$@")
}

# Show help message
show_help() {
    cat << EOF
Workstation Management Tool

Usage: $0 [OPTIONS] COMMAND [ARGS]

OPTIONS:
    --project-id PROJECT    GCP project ID (default: $DEFAULT_PROJECT_ID)
    --region REGION        GCP region (default: $DEFAULT_REGION)
    --env ENV             Environment name (default: $DEFAULT_ENV)
    --workstation ID      Workstation ID (default: $DEFAULT_WORKSTATION)
    --help, -h           Show this help message

COMMANDS:
    list                 List all workstations
    status              Show workstation status
    create [NAME]       Create a new workstation
    start [ID]          Start workstation
    stop [ID]           Stop workstation
    restart [ID]        Restart workstation
    delete [ID]         Delete workstation
    ssh [ID]            SSH into workstation
    port-forward [ID]   Set up port forwarding
    logs [ID]           View workstation logs
    info [ID]           Show detailed workstation info
    url [ID]            Get workstation URL
    update-config       Update workstation configuration

EXAMPLES:
    # List all workstations
    $0 list

    # Start default workstation
    $0 start

    # Create new workstation
    $0 create my-workstation

    # SSH into specific workstation
    $0 ssh --workstation my-workstation

    # Port forward with custom project
    $0 --project-id my-project port-forward

    # View logs for specific environment
    $0 --env production logs
EOF
}

# Validate prerequisites
validate_prereqs() {
    if [ -z "$PROJECT_ID" ]; then
        log_error "PROJECT_ID not set. Use --project-id or set PROJECT_ID environment variable"
        exit 1
    fi
    
    if ! command_exists gcloud; then
        log_error "gcloud CLI not found. Please install: https://cloud.google.com/sdk"
        exit 1
    fi
}

# Get cluster and config names
get_resource_names() {
    CLUSTER_NAME="midnight-${ENV}-cluster"
    CONFIG_NAME="midnight-${ENV}-config"
}

# List all workstations
list_workstations() {
    log_info "Listing workstations in project: $PROJECT_ID"
    get_resource_names
    
    gcloud workstations list \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format="table(name.segment(-1):label=ID,state,createTime,displayName)" \
        2>/dev/null || {
            log_warn "No workstations found or cluster not deployed"
            log_info "Run 'make deploy' to set up the infrastructure"
        }
}

# Show workstation status
show_status() {
    local workstation_id="${1:-$WORKSTATION_ID}"
    get_resource_names
    
    log_info "Checking status for: $workstation_id"
    
    gcloud workstations describe "$workstation_id" \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format="yaml(name,state,host,createTime,updateTime)" \
        2>/dev/null || {
            log_error "Workstation '$workstation_id' not found"
            exit 1
        }
}

# Create new workstation
create_workstation() {
    local workstation_id="${1:-}"
    if [ -z "$workstation_id" ]; then
        log_error "Workstation ID required"
        echo "Usage: $0 create <workstation-id>"
        exit 1
    fi
    
    get_resource_names
    
    log_info "Creating workstation: $workstation_id"
    
    gcloud workstations create "$workstation_id" \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --display-name="$workstation_id" \
        --labels="environment=$ENV,created_by=script" \
        --async
    
    log_success "Workstation creation started"
    log_info "Check status with: $0 status --workstation $workstation_id"
}

# Start workstation
start_workstation() {
    local workstation_id="${1:-$WORKSTATION_ID}"
    get_resource_names
    
    log_info "Starting workstation: $workstation_id"
    
    gcloud workstations start "$workstation_id" \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID"
    
    log_success "Workstation started"
    
    # Get and display URL
    get_workstation_url "$workstation_id"
}

# Stop workstation
stop_workstation() {
    local workstation_id="${1:-$WORKSTATION_ID}"
    get_resource_names
    
    log_info "Stopping workstation: $workstation_id"
    
    gcloud workstations stop "$workstation_id" \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID"
    
    log_success "Workstation stopped"
}

# Restart workstation
restart_workstation() {
    local workstation_id="${1:-$WORKSTATION_ID}"
    
    log_info "Restarting workstation: $workstation_id"
    stop_workstation "$workstation_id"
    sleep 5
    start_workstation "$workstation_id"
}

# Delete workstation
delete_workstation() {
    local workstation_id="${1:-}"
    if [ -z "$workstation_id" ]; then
        log_error "Workstation ID required for deletion"
        echo "Usage: $0 delete <workstation-id>"
        exit 1
    fi
    
    get_resource_names
    
    log_warn "⚠️  This will permanently delete workstation: $workstation_id"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_info "Deletion cancelled"
        exit 0
    fi
    
    log_info "Deleting workstation: $workstation_id"
    
    gcloud workstations delete "$workstation_id" \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --quiet
    
    log_success "Workstation deleted"
}

# SSH into workstation
ssh_workstation() {
    local workstation_id="${1:-$WORKSTATION_ID}"
    get_resource_names
    
    log_info "Connecting to workstation: $workstation_id"
    
    gcloud workstations ssh "$workstation_id" \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --command="${2:-bash}"
}

# Port forwarding
port_forward() {
    local workstation_id="${1:-$WORKSTATION_ID}"
    get_resource_names
    
    log_info "Setting up port forwarding for: $workstation_id"
    log_info "Forwarding ports: 3000 (app), 8080 (proof service)"
    
    # Check if workstation is running
    local state=$(gcloud workstations describe "$workstation_id" \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format="value(state)" 2>/dev/null)
    
    if [ "$state" != "STATE_RUNNING" ]; then
        log_warn "Workstation is not running. Starting it..."
        start_workstation "$workstation_id"
    fi
    
    log_info "Starting port forwarding (Ctrl+C to stop)..."
    
    gcloud workstations ssh "$workstation_id" \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --local-host-port=localhost:3000 \
        --port=3000 \
        --local-host-port=localhost:8080 \
        --port=8080 \
        --command="echo 'Port forwarding active. Press Ctrl+C to stop.'; sleep infinity"
}

# View logs
view_logs() {
    local workstation_id="${1:-$WORKSTATION_ID}"
    get_resource_names
    
    log_info "Fetching logs for: $workstation_id"
    
    gcloud logging read \
        "resource.type=gce_instance AND \
         labels.workstation_config_id=$CONFIG_NAME AND \
         labels.workstation_id=$workstation_id" \
        --limit=50 \
        --project="$PROJECT_ID" \
        --format="table(timestamp,severity,textPayload)" \
        2>/dev/null || {
            log_warn "No logs found. The workstation might not have been started yet."
        }
}

# Show detailed info
show_info() {
    local workstation_id="${1:-$WORKSTATION_ID}"
    get_resource_names
    
    log_info "Detailed information for: $workstation_id"
    
    # Get workstation details
    echo ""
    echo "=== Workstation Details ==="
    gcloud workstations describe "$workstation_id" \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format="yaml" 2>/dev/null || {
            log_error "Workstation not found"
            exit 1
        }
    
    # Get configuration details
    echo ""
    echo "=== Configuration Details ==="
    gcloud workstations configs describe "$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format="yaml(displayName,host,container,idleTimeout,runningTimeout)" 2>/dev/null
    
    # Get cluster details
    echo ""
    echo "=== Cluster Details ==="
    gcloud workstations clusters describe "$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format="yaml(displayName,network,subnetwork,privateClusterConfig)" 2>/dev/null
}

# Get workstation URL
get_workstation_url() {
    local workstation_id="${1:-$WORKSTATION_ID}"
    get_resource_names
    
    local url=$(gcloud workstations describe "$workstation_id" \
        --config="$CONFIG_NAME" \
        --cluster="$CLUSTER_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format="value(host)" 2>/dev/null)
    
    if [ -n "$url" ]; then
        echo ""
        log_success "Workstation URL: $url"
        echo ""
        log_info "Open this URL in your browser to access the IDE"
    else
        log_warn "URL not available. Workstation might not be running."
    fi
}

# Update workstation configuration
update_config() {
    get_resource_names
    
    log_info "Updating workstation configuration..."
    
    # Get registry URL from Terraform
    local registry_url=""
    if [ -f "${SCRIPT_DIR}/../terraform/terraform.tfstate" ]; then
        registry_url=$(cd "${SCRIPT_DIR}/../terraform" && terraform output -raw registry_url 2>/dev/null || echo "")
    fi
    
    if [ -z "$registry_url" ]; then
        log_warn "Registry URL not found. Using default image."
    else
        log_info "Using container image from: $registry_url"
        
        gcloud workstations configs update "$CONFIG_NAME" \
            --cluster="$CLUSTER_NAME" \
            --region="$REGION" \
            --project="$PROJECT_ID" \
            --container-custom-image="$registry_url/midnight-workstation:latest"
    fi
    
    log_success "Configuration updated"
    log_info "Restart workstations to apply changes"
}

# Main execution
main() {
    parse_args "$@"
    
    # Show help if no command
    if [ -z "$COMMAND" ]; then
        show_help
        exit 0
    fi
    
    # Validate prerequisites for all commands except help
    validate_prereqs
    
    # Execute command
    case "$COMMAND" in
        list|ls)
            list_workstations
            ;;
        status|stat)
            show_status "${ARGS[0]}"
            ;;
        create|new)
            create_workstation "${ARGS[0]}"
            ;;
        start|up)
            start_workstation "${ARGS[0]}"
            ;;
        stop|down)
            stop_workstation "${ARGS[0]}"
            ;;
        restart|reboot)
            restart_workstation "${ARGS[0]}"
            ;;
        delete|rm|remove)
            delete_workstation "${ARGS[0]}"
            ;;
        ssh|connect)
            ssh_workstation "${ARGS[0]}" "${ARGS[1]}"
            ;;
        port-forward|forward|pf)
            port_forward "${ARGS[0]}"
            ;;
        logs|log)
            view_logs "${ARGS[0]}"
            ;;
        info|describe)
            show_info "${ARGS[0]}"
            ;;
        url|link)
            get_workstation_url "${ARGS[0]}"
            ;;
        update-config|update)
            update_config
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"