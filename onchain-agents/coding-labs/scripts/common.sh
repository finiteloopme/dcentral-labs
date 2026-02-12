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

# Agent Registry
readonly AGENT_REGISTRY_HOST="${AGENT_REGISTRY_HOST:-localhost}"
readonly AGENT_REGISTRY_PORT="${AGENT_REGISTRY_PORT:-4000}"
readonly AGENT_REGISTRY_URL="${AGENT_REGISTRY_URL:-http://${AGENT_REGISTRY_HOST}:${AGENT_REGISTRY_PORT}}"

# Default agent ports (used when registry is not available)
readonly SOMNIA_AGENT_PORT="${SOMNIA_AGENT_PORT:-4001}"
readonly SOMNIA_AGENT_HOST="${SOMNIA_AGENT_HOST:-localhost}"
readonly MIDNIGHT_AGENT_PORT="${MIDNIGHT_AGENT_PORT:-4003}"
readonly MIDNIGHT_AGENT_HOST="${MIDNIGHT_AGENT_HOST:-localhost}"

# Default agent (for scripts that target a single agent)
readonly DEFAULT_AGENT="${AGENT:-somnia}"

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

# Get agent URL by ID (tries registry first, falls back to static config)
get_agent_url() {
  local agent_id="${1:-$DEFAULT_AGENT}"
  
  # If AGENT_URL is explicitly set, use it
  if [ -n "${AGENT_URL:-}" ]; then
    echo "$AGENT_URL"
    return
  fi
  
  # Try to get from registry first
  local url
  url=$(curl -s "${AGENT_REGISTRY_URL}/agents" 2>/dev/null | jq -r ".agents[] | select(.id == \"${agent_id}\") | .url" 2>/dev/null || echo "")
  
  if [ -n "$url" ] && [ "$url" != "null" ]; then
    echo "$url"
    return
  fi
  
  # Fallback to static config based on agent_id
  case "$agent_id" in
    somnia)
      echo "http://${SOMNIA_AGENT_HOST}:${SOMNIA_AGENT_PORT}"
      ;;
    midnight)
      echo "http://${MIDNIGHT_AGENT_HOST}:${MIDNIGHT_AGENT_PORT}"
      ;;
    *)
      log_warn "Unknown agent: $agent_id, falling back to somnia"
      echo "http://${SOMNIA_AGENT_HOST}:${SOMNIA_AGENT_PORT}"
      ;;
  esac
}

# List all enabled agents from registry
list_agents() {
  curl -s "${AGENT_REGISTRY_URL}/agents" 2>/dev/null | jq -r '.agents[] | "\(.id): \(.url)"' 2>/dev/null || {
    log_warn "Could not reach registry, using static agent list"
    echo "somnia: http://${SOMNIA_AGENT_HOST}:${SOMNIA_AGENT_PORT}"
    echo "midnight: http://${MIDNIGHT_AGENT_HOST}:${MIDNIGHT_AGENT_PORT}"
  }
}

# Check if a specific agent is running
is_agent_running() {
  local agent_id="${1:-$DEFAULT_AGENT}"
  local url
  url=$(get_agent_url "$agent_id")
  curl -s "${url}/health" > /dev/null 2>&1
}

# Wait for agent to be ready
wait_for_agent() {
  local agent_id="${1:-$DEFAULT_AGENT}"
  local max_attempts="${2:-30}"
  local attempt=0
  local url
  url=$(get_agent_url "$agent_id")
  
  log_info "Waiting for ${agent_id} agent to be ready at ${url}..."
  
  while [ $attempt -lt $max_attempts ]; do
    if is_agent_running "$agent_id"; then
      log_success "${agent_id} agent is ready!"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 1
  done
  
  log_error "${agent_id} agent did not become ready within ${max_attempts} seconds"
  return 1
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
