#!/usr/bin/env bash
# Run tests for chain CLIs and framework
#
# Usage:
#   ./scripts/test.sh              # Run all tests
#   ./scripts/test.sh <chain>      # Run tests for specific chain
#   ./scripts/test.sh core         # Run core framework tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Configuration
# =============================================================================

TARGET=""
WATCH=false
COVERAGE=false
VERBOSE=false

# =============================================================================
# Parse Arguments
# =============================================================================

show_help() {
    cat << EOF
Run tests for chain CLIs and framework

Usage:
  $(basename "$0") [target] [options]

Arguments:
  target                    What to test: 'core', 'evm', or chain name
                           If omitted, runs all tests

Options:
  -w, --watch              Run in watch mode
  -c, --coverage           Generate coverage report
  -v, --verbose            Verbose output
  -h, --help               Show this help message

Available test targets:
  core                     Core CLI framework
  evm                      EVM chain type CLI
$(list_chains | sed 's/^/  /')

Examples:
  $(basename "$0")                    # Run all tests
  $(basename "$0") core               # Test core framework
  $(basename "$0") evm --coverage     # Test EVM CLI with coverage
  $(basename "$0") somnia --watch     # Test in watch mode
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -w|--watch)
            WATCH=true
            shift
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$TARGET" ]]; then
                TARGET="$1"
            else
                log_error "Unexpected argument: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# =============================================================================
# Test Functions
# =============================================================================

run_npm_test() {
    local dir="$1"
    local name="$2"
    
    if [[ ! -d "$dir" ]]; then
        log_warn "Directory not found: $dir"
        return 0
    fi
    
    if [[ ! -f "${dir}/package.json" ]]; then
        log_warn "No package.json in: $dir"
        return 0
    fi
    
    log_info "Testing ${name}..."
    
    cd "$dir"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        log_info "  Installing dependencies..."
        npm install
    fi
    
    # Build test command
    local test_cmd="npm test"
    
    if [[ "$WATCH" == "true" ]]; then
        test_cmd="npm run test:watch 2>/dev/null || npm test -- --watch"
    fi
    
    if [[ "$COVERAGE" == "true" ]]; then
        test_cmd="npm run test:coverage 2>/dev/null || npm test -- --coverage"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        test_cmd="${test_cmd} -- --reporter=verbose 2>/dev/null || ${test_cmd}"
    fi
    
    # Run tests
    eval "$test_cmd"
    
    log_success "  ${name} tests passed"
}

test_core() {
    run_npm_test "${CORE_DIR}/cli" "Core CLI"
}

test_chain_type() {
    local chain_type="$1"
    local cli_dir="${CHAINS_DIR}/${chain_type}/cli"
    
    run_npm_test "$cli_dir" "${chain_type} CLI"
}

test_chain() {
    local chain="$1"
    local chain_type
    
    chain_type=$(get_chain_type "$chain")
    
    if [[ "$chain_type" == "unknown" ]]; then
        log_warn "Unknown chain type for ${chain}, skipping chain-type tests"
    else
        test_chain_type "$chain_type"
    fi
}

# =============================================================================
# Run Tests
# =============================================================================

log_info "Running tests..."

FAILED=0

if [[ -z "$TARGET" ]]; then
    # Run all tests
    log_info "Running all tests..."
    
    # Core
    test_core || FAILED=1
    
    # EVM chain type
    test_chain_type "evm" || FAILED=1
    
elif [[ "$TARGET" == "core" ]]; then
    test_core || FAILED=1
    
elif [[ "$TARGET" == "evm" ]]; then
    test_chain_type "evm" || FAILED=1
    
else
    # Assume it's a chain name
    require_chain "$TARGET"
    test_chain "$TARGET" || FAILED=1
fi

# =============================================================================
# Summary
# =============================================================================

if [[ "$FAILED" -eq 0 ]]; then
    log_success "All tests passed!"
else
    log_error "Some tests failed"
    exit 1
fi
