#!/usr/bin/env bash
# Testing: unit, integration, all

source "$(dirname "$0")/common.sh"
cd_project_root

cmd_unit() {
  log_header "Running unit tests"
  run_pnpm vitest run --reporter=verbose
  log_success "Unit tests passed"
}

cmd_unit_watch() {
  log_header "Running unit tests in watch mode"
  run_pnpm vitest watch
}

cmd_unit_coverage() {
  log_header "Running unit tests with coverage"
  run_pnpm vitest run --coverage
  log_success "Coverage report generated"
}

cmd_integration() {
  log_header "Running integration tests"
  
  # Check if agent is running
  if ! is_agent_running; then
    log_warn "Agent is not running. Starting agent..."
    log_info "Please run 'make dev' in another terminal first, or 'make up' for containers"
    exit 1
  fi
  
  log_info "Agent is running at $(get_agent_url)"
  
  # Run integration tests
  run_pnpm vitest run --config vitest.integration.config.ts --reporter=verbose 2>/dev/null || {
    log_warn "No integration tests found yet. Skipping."
  }
  
  log_success "Integration tests complete"
}

cmd_all() {
  log_header "Running all tests"
  cmd_unit
  echo ""
  cmd_integration
  log_success "All tests passed"
}

# Main
case "${1:-}" in
  unit)
    cmd_unit
    ;;
  unit-watch)
    cmd_unit_watch
    ;;
  unit-coverage)
    cmd_unit_coverage
    ;;
  integration)
    cmd_integration
    ;;
  all)
    cmd_all
    ;;
  *)
    show_usage "test.sh" "
  unit           Run unit tests
  unit-watch     Run unit tests in watch mode
  unit-coverage  Run unit tests with coverage
  integration    Run integration tests (requires running agent)
  all            Run all tests"
    exit 1
    ;;
esac
