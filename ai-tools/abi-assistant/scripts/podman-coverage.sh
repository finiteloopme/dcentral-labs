#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

OUTPUT_FORMAT=${1:-"terminal"}

log_info "Generating test coverage report in container..."

# Build dev container if it doesn't exist
if ! podman image exists abi-assistant-dev:latest; then
    log_info "Building development container..."
    podman build -f Dockerfile.dev -t abi-assistant-dev:latest .
fi

# Run tests with coverage
if [ "$OUTPUT_FORMAT" = "html" ]; then
    log_info "Generating HTML coverage report..."
    
    podman run --rm \
        -v ./:/workspace:Z \
        -w /workspace \
        -p 8080:8080 \
        abi-assistant-dev:latest \
        sh -c "cargo tarpaulin --out Html --output-dir target/coverage && \
               echo 'Coverage report generated. Starting web server...' && \
               python3 -m http.server 8080 --directory target/coverage"
    
    log_info "Coverage report available at http://localhost:8080"
else
    podman run --rm \
        -v ./:/workspace:Z \
        -w /workspace \
        abi-assistant-dev:latest \
        cargo tarpaulin --print-summary --print-uncovered-lines
fi