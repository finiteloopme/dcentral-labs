#!/usr/bin/env bash
# Common utilities for all scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_warning() {
    log_warn "$1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Check if command exists
require_cmd() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is required but not installed"
        exit 1
    fi
}

# Check environment variables
require_env() {
    if [ -z "${!1}" ]; then
        log_error "Environment variable $1 is required"
        exit 1
    fi
}

# Load .env file if exists
load_env() {
    if [ -f .env ]; then
        log_debug "Loading .env file"
        set -a
        source .env
        set +a
    elif [ -f .env.example ]; then
        log_warn "No .env file found, using .env.example as template"
        cp .env.example .env
        log_info "Created .env file from template. Please update with your values."
    fi
}

# Check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_error "Port $port is already in use"
        return 1
    fi
    return 0
}

# Wait for service to be ready
wait_for_service() {
    local url=$1
    local max_attempts=${2:-30}
    local attempt=0
    
    log_info "Waiting for service at $url..."
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f "$url/health" > /dev/null 2>&1; then
            log_info "Service is ready!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 1
    done
    
    log_error "Service failed to start after $max_attempts seconds"
    return 1
}

# Create directory if it doesn't exist
ensure_dir() {
    if [ ! -d "$1" ]; then
        log_debug "Creating directory: $1"
        mkdir -p "$1"
    fi
}

# Get project root directory
get_project_root() {
    # Get the directory containing the scripts folder
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
}

# Export common variables if not already set
if [ -z "${PROJECT_ROOT:-}" ]; then
    export PROJECT_ROOT=$(get_project_root)
fi
export SCRIPTS_DIR="$PROJECT_ROOT/scripts"
export DATA_DIR="$PROJECT_ROOT/data"
export LOGS_DIR="$PROJECT_ROOT/logs"