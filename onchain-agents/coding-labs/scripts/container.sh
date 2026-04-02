#!/usr/bin/env bash
# Container operations: build, up, down, logs, shell

source "$(dirname "$0")/common.sh"
cd_project_root

require_podman

# Container names
readonly SOMNIA_AGENT_CONTAINER="somnia-agent"
readonly OPENCODE_WEB_CONTAINER="opencode-web"

cmd_build() {
  log_header "Building container images"
  
  log_info "Building somnia-agent..."
  podman build \
    -t somnia-agent:latest \
    -f packages/somnia-agent/Containerfile \
    .
  
  log_info "Building opencode-web..."
  podman build \
    -t opencode-web:latest \
    -f opencode/Containerfile.web \
    opencode/
  
  log_info "Building store-agent..."
  podman build \
    -t store-agent:latest \
    -f packages/store-agent/Containerfile \
    .

  log_info "Building payment-agent..."
  podman build \
    -t payment-agent:latest \
    -f packages/payment-agent/Containerfile \
    .

  log_success "Container images built"
  podman images | grep -E "^(REPOSITORY|somnia-agent|store-agent|payment-agent|opencode-web)"
}

cmd_build_opencode() {
  log_header "Building OpenCode web container"
  
  if [ ! -d "opencode" ]; then
    log_error "OpenCode directory not found. Clone it first."
    exit 1
  fi
  
  podman build \
    -t opencode-web:latest \
    -f opencode/Containerfile.web \
    opencode/
  
  log_success "OpenCode web container built"
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
  podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|somnia|store|payment|opencode)" || echo "  (none)"
  
  echo ""
  echo "Images:"
  podman images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(REPOSITORY|somnia|store|payment|opencode)" || echo "  (none)"
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

  # Remove store-agent image
  if podman images --format "{{.Repository}}" | grep -q "^store-agent$"; then
    log_info "Removing store-agent image..."
    podman rmi store-agent:latest
  fi

  # Remove payment-agent image
  if podman images --format "{{.Repository}}" | grep -q "^payment-agent$"; then
    log_info "Removing payment-agent image..."
    podman rmi payment-agent:latest
  fi
  
  log_success "Container cleanup complete"
}

cmd_compose_build() {
  log_header "Building all container images with compose"
  podman-compose --env-file .env.generated build
  log_success "All container images built"
}

cmd_compose_up() {
  log_header "Starting all containers with compose"
  podman-compose --env-file .env.generated up -d
  log_success "All containers started"
}

cmd_compose_down() {
  log_header "Stopping all containers with compose"
  podman-compose --env-file .env.generated down
  log_success "All containers stopped"
}

# Main
case "${1:-}" in
  build)
    cmd_build
    ;;
  build-opencode)
    cmd_build_opencode
    ;;
  up)
    cmd_up
    ;;
  down)
    cmd_down
    ;;
  compose-build)
    cmd_compose_build
    ;;
  compose-up)
    cmd_compose_up
    ;;
  compose-down)
    cmd_compose_down
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
  build           Build all container images
  build-opencode  Build OpenCode web container only
  up              Start somnia-agent container
  down            Stop containers
  compose-build   Build all container images with compose
  compose-up      Start all containers with compose
  compose-down    Stop all containers with compose
  logs            View container logs (follow)
  shell           Shell into somnia-agent container
  status          Show container and image status
  clean           Stop containers and remove images"
    exit 1
    ;;
esac
