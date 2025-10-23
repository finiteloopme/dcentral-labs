#!/usr/bin/env bash
# One-time setup script for the project
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

log_info "Setting up ABI Assistant MCP Server..."

# Check prerequisites
check_prerequisites() {
    local missing=()
    
    # Check for container runtime
    if command -v podman &> /dev/null; then
        log_success "Found podman"
        CONTAINER_RUNTIME="podman"
    elif command -v docker &> /dev/null; then
        log_success "Found docker"
        CONTAINER_RUNTIME="docker"
    else
        missing+=("podman or docker")
    fi
    
    # Check for Rust (optional for local development)
    if command -v cargo &> /dev/null; then
        log_success "Found Rust (optional)"
    else
        log_info "Rust not found (optional - only needed for local development)"
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing+=("git")
    else
        log_success "Found git"
    fi
    
    # Report missing prerequisites
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Please install the missing tools and run setup again"
        exit 1
    fi
}

# Main setup
main() {
    log_info "Checking prerequisites..."
    check_prerequisites
    
    log_info "Creating directories..."
    mkdir -p "$PROJECT_ROOT/data"
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/coverage"
    
    log_info "Setting up environment..."
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        if [ -f "$PROJECT_ROOT/.env.example" ]; then
            cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
            log_success "Created .env from .env.example"
            log_info "Please edit .env with your configuration"
        else
            log_warn "No .env.example found, creating minimal .env"
            cat > "$PROJECT_ROOT/.env" << EOF
# ABI Assistant Configuration
RUST_LOG=info
MCP_HOST=127.0.0.1
MCP_PORT=3000
DATABASE_URL=sqlite://./data/abi_assistant.db
EOF
            log_success "Created minimal .env file"
        fi
    else
        log_info ".env already exists"
    fi
    
    log_info "Initializing database..."
    "$SCRIPT_DIR/db-setup.sh"
    
    # Ask user preference
    echo ""
    log_info "How would you like to run the server?"
    echo "1) Using containers (recommended - no Rust required)"
    echo "2) Locally (requires Rust installed)"
    echo ""
    read -p "Choice [1/2]: " choice
    
    case "$choice" in
        1)
            log_info "Building container image..."
            "$SCRIPT_DIR/container.sh" build dev
            log_success "Setup complete!"
            echo ""
            log_info "To start the development server:"
            echo "  make dev-container"
            echo ""
            log_info "To run tests:"
            echo "  scripts/container.sh test"
            ;;
        2)
            if ! command -v cargo &> /dev/null; then
                log_error "Rust is not installed"
                log_info "Install Rust from: https://rustup.rs/"
                exit 1
            fi
            
            log_info "Building project..."
            cargo build
            
            log_success "Setup complete!"
            echo ""
            log_info "To start the development server:"
            echo "  make dev"
            echo ""
            log_info "To run tests:"
            echo "  make test"
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
    
    echo ""
    log_info "Additional commands:"
    echo "  make help           # Show all available commands"
    echo "  make test-mcp       # Test MCP endpoints"
    echo "  make anvil          # Start local test blockchain"
}

# Set project root
export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Run main
main "$@"