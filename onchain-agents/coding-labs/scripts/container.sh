#!/usr/bin/env bash
# Container operations: build, up, down, logs, shell

source "$(dirname "$0")/common.sh"
cd_project_root

require_podman

# Container names
readonly SOMNIA_AGENT_CONTAINER="somnia-agent"

cmd_build() {
  log_header "Building container images"
  
  log_info "Building somnia-agent..."
  podman build \
    -t somnia-agent:latest \
    -f packages/somnia-agent/Containerfile \
    .
  
  log_success "Container images built"
  podman images | grep -E "^(REPOSITORY|somnia-agent)"
}

cmd_up() {
  log_header "Starting containers"
  
  # Check if already running
  if podman ps --format "{{.Names}}" | grep -q "^${SOMNIA_AGENT_CONTAINER}$"; then
    log_warn "Container ${SOMNIA_AGENT_CONTAINER} is already running"
    return 0
  fi
  
  # Check if image exists
  if ! podman images --format "{{.Repository}}" | grep -q "^somnia-agent$"; then
    log_info "Image not found. Building first..."
    cmd_build
  fi
  
  log_info "Starting somnia-agent..."
  podman run -d \
    --name "${SOMNIA_AGENT_CONTAINER}" \
    --rm \
    -p "${SOMNIA_AGENT_PORT}:4001" \
    -e GOOGLE_APPLICATION_CREDENTIALS=/creds/application_default_credentials.json \
    -v "${HOME}/.config/gcloud:/creds:ro" \
    somnia-agent:latest
  
  # Wait for agent to be ready
  wait_for_agent 30
  
  log_success "Containers started"
  log_info "Agent available at: $(get_agent_url)"
}

cmd_down() {
  log_header "Stopping containers"
  
  if podman ps --format "{{.Names}}" | grep -q "^${SOMNIA_AGENT_CONTAINER}$"; then
    podman stop "${SOMNIA_AGENT_CONTAINER}"
    log_success "Container stopped"
  else
    log_info "Container ${SOMNIA_AGENT_CONTAINER} is not running"
  fi
}

cmd_logs() {
  log_header "Container logs"
  
  if ! podman ps --format "{{.Names}}" | grep -q "^${SOMNIA_AGENT_CONTAINER}$"; then
    log_error "Container ${SOMNIA_AGENT_CONTAINER} is not running"
    exit 1
  fi
  
  podman logs -f "${SOMNIA_AGENT_CONTAINER}"
}

cmd_shell() {
  log_header "Shell into container"
  
  if ! podman ps --format "{{.Names}}" | grep -q "^${SOMNIA_AGENT_CONTAINER}$"; then
    log_error "Container ${SOMNIA_AGENT_CONTAINER} is not running"
    exit 1
  fi
  
  podman exec -it "${SOMNIA_AGENT_CONTAINER}" /bin/sh
}

cmd_status() {
  log_header "Container status"
  
  echo ""
  echo "Running containers:"
  podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|somnia)" || echo "  (none)"
  
  echo ""
  echo "Images:"
  podman images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|somnia)" || echo "  (none)"
}

cmd_clean() {
  log_header "Cleaning containers and images"
  
  # Stop running containers
  if podman ps --format "{{.Names}}" | grep -q "^${SOMNIA_AGENT_CONTAINER}$"; then
    log_info "Stopping ${SOMNIA_AGENT_CONTAINER}..."
    podman stop "${SOMNIA_AGENT_CONTAINER}"
  fi
  
  # Remove images
  if podman images --format "{{.Repository}}" | grep -q "^somnia-agent$"; then
    log_info "Removing somnia-agent image..."
    podman rmi somnia-agent:latest
  fi
  
  log_success "Container cleanup complete"
}

# Main
case "${1:-}" in
  build)
    cmd_build
    ;;
  up)
    cmd_up
    ;;
  down)
    cmd_down
    ;;
  logs)
    cmd_logs
    ;;
  shell)
    cmd_shell
    ;;
  status)
    cmd_status
    ;;
  clean)
    cmd_clean
    ;;
  *)
    show_usage "container.sh" "
  build    Build container images
  up       Start containers
  down     Stop containers
  logs     View container logs (follow)
  shell    Shell into somnia-agent container
  status   Show container and image status
  clean    Stop containers and remove images"
    exit 1
    ;;
esac
