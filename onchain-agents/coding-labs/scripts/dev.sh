#!/usr/bin/env bash
# Development tasks: install, build, dev, typecheck, lint, clean

source "$(dirname "$0")/common.sh"
cd_project_root

cmd_install() {
  log_header "Installing dependencies"
  run_pnpm install
  log_success "Dependencies installed"
}

cmd_build() {
  log_header "Building all packages"
  run_pnpm --filter @coding-labs/shared build
  run_pnpm --filter @coding-labs/somnia-agent build
  log_success "Build complete"
}

cmd_dev() {
  log_header "Starting somnia-agent in dev mode"
  log_info "Agent will be available at: $(get_agent_url)"
  log_info "Press Ctrl+C to stop"
  echo ""
  run_pnpm --filter @coding-labs/somnia-agent dev
}

cmd_typecheck() {
  log_header "Running TypeScript type checking"
  run_pnpm --filter @coding-labs/shared typecheck
  run_pnpm --filter @coding-labs/somnia-agent typecheck
  log_success "Type checking passed"
}

cmd_lint() {
  log_header "Running ESLint"
  run_pnpm eslint packages --ext .ts,.tsx
  log_success "Linting passed"
}

cmd_lint_fix() {
  log_header "Running ESLint with auto-fix"
  run_pnpm eslint packages --ext .ts,.tsx --fix
  log_success "Linting complete"
}

cmd_format() {
  log_header "Formatting code with Prettier"
  run_pnpm prettier --write "packages/**/src/**/*.ts"
  log_success "Formatting complete"
}

cmd_clean() {
  log_header "Cleaning build artifacts"
  rm -rf packages/shared/dist
  rm -rf packages/somnia-agent/dist
  rm -rf node_modules/.cache
  log_success "Clean complete"
}

cmd_clean_all() {
  log_header "Cleaning all (including node_modules)"
  cmd_clean
  rm -rf node_modules
  rm -rf packages/shared/node_modules
  rm -rf packages/somnia-agent/node_modules
  log_success "Full clean complete"
}

# Main
case "${1:-}" in
  install)
    cmd_install
    ;;
  build)
    cmd_build
    ;;
  dev)
    cmd_dev
    ;;
  typecheck)
    cmd_typecheck
    ;;
  lint)
    cmd_lint
    ;;
  lint-fix)
    cmd_lint_fix
    ;;
  format)
    cmd_format
    ;;
  clean)
    cmd_clean
    ;;
  clean-all)
    cmd_clean_all
    ;;
  *)
    show_usage "dev.sh" "
  install     Install dependencies
  build       Build all packages
  dev         Run somnia-agent in dev mode
  typecheck   Run TypeScript type checking
  lint        Run ESLint
  lint-fix    Run ESLint with auto-fix
  format      Format code with Prettier
  clean       Clean build artifacts
  clean-all   Clean all including node_modules"
    exit 1
    ;;
esac
