#!/bin/bash
# Common functions for all scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check required tools
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        return 1
    fi
    
    return 0
}

# Get project ID
get_project_id() {
    if [ -n "$PROJECT_ID" ]; then
        echo "$PROJECT_ID"
    elif command_exists gcloud; then
        gcloud config get-value project 2>/dev/null
    else
        echo ""
    fi
}

# Container runtime detection
detect_container_runtime() {
    if command_exists podman; then
        echo "podman"
    elif command_exists docker; then
        echo "docker"
    else
        echo ""
    fi
}

# Run container command
container_cmd() {
    local runtime=$(detect_container_runtime)
    if [ -z "$runtime" ]; then
        log_error "No container runtime found (podman or docker)"
        return 1
    fi
    $runtime "$@"
}

# Export functions
export -f log_info log_warn log_error log_success
export -f command_exists check_dependencies
export -f get_project_id detect_container_runtime container_cmd