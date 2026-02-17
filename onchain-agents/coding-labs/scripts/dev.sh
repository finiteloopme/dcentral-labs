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
  run_pnpm --filter @coding-labs/midnight-agent build
  run_pnpm --filter @coding-labs/midnight-mcp build
  log_success "Build complete"
}

cmd_dev() {
  log_header "Starting somnia-agent in dev mode"
  log_info "Agent will be available at: $(get_agent_url)"
  log_info "Press Ctrl+C to stop"
  echo ""
  run_pnpm --filter @coding-labs/somnia-agent dev
}

cmd_run_all() {
  log_header "Starting all services (dev mode with hot reload)"
  log_info "Services:"
  log_info "  - Agent Registry:    http://localhost:4000"
  log_info "  - Somnia Agent:      http://localhost:4001"
  log_info "  - Midnight Agent:    http://localhost:4003"
  log_info "  - Midnight MCP:      http://localhost:4010"
  log_info "  - OpenCode Backend:  http://localhost:4097 (API)"
  log_info "  - OpenCode Frontend: http://localhost:3000 (Vite dev server)"
  log_info ""
  log_info "Access the app at: http://localhost:3000"
  log_info "Press Ctrl+C to stop all services"
  echo ""
  
  npx concurrently \
    --names "registry,somnia,midnight,mcp,backend,frontend" \
    --prefix-colors "blue,green,magenta,red,yellow,cyan" \
    --prefix "[{name}]" \
    --kill-others-on-fail \
    "cd packages/agent-registry && npx tsx src/index.ts" \
    "cd packages/somnia-agent && npx tsx src/index.ts" \
    "cd packages/midnight-agent && npx tsx src/index.ts" \
    "cd packages/midnight-mcp && npx tsx src/index.ts" \
    "cd opencode && bun run dev -- web --hostname 0.0.0.0 --port 4097" \
    "cd opencode/packages/app && bun run dev"
}

cmd_run_all_built() {
  log_header "Building and starting all services (production-like)"
  
  # Build frontend first
  log_info "Building frontend..."
  (cd opencode/packages/app && bun run build)
  
  log_info ""
  log_info "Services:"
  log_info "  - Agent Registry:  http://localhost:4000"
  log_info "  - Somnia Agent:    http://localhost:4001"
  log_info "  - Midnight Agent:  http://localhost:4003"
  log_info "  - OpenCode Web:    http://localhost:4097 (backend + static frontend)"
  log_info ""
  log_info "Access the app at: http://localhost:4097"
  log_info "Press Ctrl+C to stop all services"
  echo ""
  
  export OPENCODE_STATIC_DIR="$(pwd)/opencode/packages/app/dist"
  
  npx concurrently \
    --names "registry,somnia,midnight,opencode" \
    --prefix-colors "blue,green,magenta,yellow" \
    --prefix "[{name}]" \
    --kill-others-on-fail \
    "cd packages/agent-registry && npx tsx src/index.ts" \
    "cd packages/somnia-agent && npx tsx src/index.ts" \
    "cd packages/midnight-agent && npx tsx src/index.ts" \
    "cd opencode && bun run dev -- web --hostname 0.0.0.0 --port 4097"
}

cmd_run_all_with_login() {
  log_header "Starting all services with login page (dev mode)"
  log_info "Services:"
  log_info "  - Agent Registry:    http://localhost:4000"
  log_info "  - Somnia Agent:      http://localhost:4001"
  log_info "  - Midnight Agent:    http://localhost:4003"
  log_info "  - Login Page:        http://localhost:4098"
  log_info "  - OpenCode Backend:  http://localhost:4097 (API)"
  log_info "  - OpenCode Frontend: http://localhost:3000 (Vite dev server)"
  log_info ""
  log_info "Access via login page: http://localhost:4098"
  log_info "Or directly at: http://localhost:3000"
  log_info "Press Ctrl+C to stop all services"
  echo ""
  
  npx concurrently \
    --names "registry,somnia,midnight,login,backend,frontend" \
    --prefix-colors "blue,green,magenta,cyan,yellow,white" \
    --prefix "[{name}]" \
    --kill-others-on-fail \
    "cd packages/agent-registry && npx tsx src/index.ts" \
    "cd packages/somnia-agent && npx tsx src/index.ts" \
    "cd packages/midnight-agent && npx tsx src/index.ts" \
    "cd packages/opencode-login && APP_URL=http://localhost:3000 node server.js" \
    "cd opencode && bun run dev -- web --hostname 0.0.0.0 --port 4097" \
    "cd opencode/packages/app && bun run dev"
}

cmd_run_all_with_login_built() {
  log_header "Building and starting all services with login page (production-like)"
  
  # Build frontend first
  log_info "Building frontend..."
  (cd opencode/packages/app && bun run build)
  
  log_info ""
  log_info "Services:"
  log_info "  - Agent Registry:  http://localhost:4000"
  log_info "  - Somnia Agent:    http://localhost:4001"
  log_info "  - Midnight Agent:  http://localhost:4003"
  log_info "  - Login Page:      http://localhost:4098"
  log_info "  - OpenCode Web:    http://localhost:4097 (backend + static frontend)"
  log_info ""
  log_info "Access via login page: http://localhost:4098"
  log_info "Or directly at: http://localhost:4097"
  log_info "Press Ctrl+C to stop all services"
  echo ""
  
  export OPENCODE_STATIC_DIR="$(pwd)/opencode/packages/app/dist"
  
  npx concurrently \
    --names "registry,somnia,midnight,login,opencode" \
    --prefix-colors "blue,green,magenta,cyan,yellow" \
    --prefix "[{name}]" \
    --kill-others-on-fail \
    "cd packages/agent-registry && npx tsx src/index.ts" \
    "cd packages/somnia-agent && npx tsx src/index.ts" \
    "cd packages/midnight-agent && npx tsx src/index.ts" \
    "cd packages/opencode-login && APP_URL=http://localhost:4097 node server.js" \
    "cd opencode && bun run dev -- web --hostname 0.0.0.0 --port 4097"
}

cmd_typecheck() {
  log_header "Running TypeScript type checking"
  run_pnpm --filter @coding-labs/shared typecheck
  run_pnpm --filter @coding-labs/somnia-agent typecheck
  run_pnpm --filter @coding-labs/midnight-agent typecheck
  run_pnpm --filter @coding-labs/midnight-mcp typecheck
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
  rm -rf packages/midnight-agent/dist
  rm -rf packages/midnight-mcp/dist
  rm -rf node_modules/.cache
  log_success "Clean complete"
}

cmd_clean_all() {
  log_header "Cleaning all (including node_modules)"
  cmd_clean
  rm -rf node_modules
  rm -rf packages/shared/node_modules
  rm -rf packages/somnia-agent/node_modules
  rm -rf packages/midnight-agent/node_modules
  rm -rf packages/midnight-mcp/node_modules
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
  run-all)
    cmd_run_all
    ;;
  run-all-built)
    cmd_run_all_built
    ;;
  run-all-with-login)
    cmd_run_all_with_login
    ;;
  run-all-with-login-built)
    cmd_run_all_with_login_built
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
  install                  Install dependencies
  build                    Build all packages
  dev                      Run somnia-agent in dev mode
  run-all                  Run all services (Vite dev server, hot reload)
  run-all-built            Run all services (pre-built frontend, production-like)
  run-all-with-login       Run all + login page (Vite dev server)
  run-all-with-login-built Run all + login page (pre-built, production-like)
  typecheck                Run TypeScript type checking
  lint                     Run ESLint
  lint-fix                 Run ESLint with auto-fix
  format                   Format code with Prettier
  clean                    Clean build artifacts
  clean-all                Clean all including node_modules"
    exit 1
    ;;
esac
