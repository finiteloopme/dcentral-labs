#!/usr/bin/env bash
# Common utilities for scripts
# Source this file in other scripts: source "$(dirname "$0")/common.sh"

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Project root (parent of scripts directory)
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Default ports
readonly SOMNIA_AGENT_PORT="${SOMNIA_AGENT_PORT:-4001}"
readonly SOMNIA_AGENT_HOST="${SOMNIA_AGENT_HOST:-localhost}"

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[OK]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_header() {
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  $*${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if command exists
require_cmd() {
  if ! command -v "$1" &> /dev/null; then
    log_error "Required command not found: $1"
    exit 1
  fi
}

# Check if command exists (returns boolean, no exit)
has_cmd() {
  command -v "$1" &> /dev/null
}

# Get pnpm command (npx fallback if pnpm not globally installed)
get_pnpm() {
  if has_cmd pnpm; then
    echo "pnpm"
  else
    echo "npx pnpm@9"
  fi
}

# Run pnpm command
run_pnpm() {
  local pnpm_cmd
  pnpm_cmd=$(get_pnpm)
  $pnpm_cmd "$@"
}

# Check if podman is available
require_podman() {
  if ! has_cmd podman; then
    log_error "Podman is required but not installed."
    log_error "Install: https://podman.io/getting-started/installation"
    exit 1
  fi
}

# Check if agent is running
is_agent_running() {
  curl -s "http://${SOMNIA_AGENT_HOST}:${SOMNIA_AGENT_PORT}/health" > /dev/null 2>&1
}

# Wait for agent to be ready
wait_for_agent() {
  local max_attempts="${1:-30}"
  local attempt=0
  
  log_info "Waiting for agent to be ready..."
  
  while [ $attempt -lt $max_attempts ]; do
    if is_agent_running; then
      log_success "Agent is ready!"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 1
  done
  
  log_error "Agent did not become ready within ${max_attempts} seconds"
  return 1
}

# Get agent base URL
get_agent_url() {
  echo "http://${SOMNIA_AGENT_HOST}:${SOMNIA_AGENT_PORT}"
}

# Change to project root
cd_project_root() {
  cd "$PROJECT_ROOT"
}

# Show usage for a script
show_usage() {
  local script_name="$1"
  local commands="$2"
  
  echo "Usage: $script_name <command>"
  echo ""
  echo "Commands:"
  echo "$commands"
}
