#!/bin/bash

# Local development script for Web3 Workstation
# Build and run the container locally for testing

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions for colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_header() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Default values
CONTAINER_NAME="${CONTAINER_NAME:-web3-workstation-local}"
IMAGE_NAME="${IMAGE_NAME:-web3-workstation:local}"
BUILD_ONLY="${BUILD_ONLY:-false}"
RUN_ONLY="${RUN_ONLY:-false}"
INTERACTIVE="${INTERACTIVE:-true}"
PORTS="${PORTS:-8090:8080,8000:8000}"
VOLUME_HOME="${VOLUME_HOME:-$HOME/web3-workspace}"
MEMORY="${MEMORY:-4g}"
CPUS="${CPUS:-2}"
DEFAULT_ACTION="${DEFAULT_ACTION:-run}"  # Default action: run (build if needed)

# Detect container runtime and OS
detect_runtime() {
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
    else
        OS_TYPE="other"
    fi
    
    if command -v podman &> /dev/null; then
        RUNTIME="podman"
        print_info "Using Podman (rootless container runtime)"
        
        # Check if on macOS and podman machine is running
        if [ "$OS_TYPE" = "macos" ]; then
            if ! podman machine list | grep -q "Currently running"; then
                print_warning "Podman machine is not running on macOS"
                print_info "Starting Podman machine..."
                podman machine start
                sleep 2
            fi
            
            # Check podman machine for port forwarding
            print_info "Checking Podman machine configuration..."
            MACHINE_INFO=$(podman machine inspect 2>/dev/null || echo "{}")
            
            # Set rootful for better networking on macOS
            print_info "Note: On macOS, you may need to use rootful containers for port access"
            print_info "Or configure port forwarding in your Podman machine"
        fi
    elif command -v docker &> /dev/null; then
        RUNTIME="docker"
        print_info "Using Docker"
    else
        print_error "Neither Podman nor Docker is installed"
        echo "Install Podman (recommended): https://podman.io/getting-started/installation"
        echo "Or install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
}

# Show usage
usage() {
    cat << EOF
${CYAN}Web3 Workstation - Local Development${NC}

Usage: $0 [build|run|status|stop|clean] [OPTIONS]

Commands:
    build             Build the container image only
    run               Run the container (default, builds if needed)
    status            Show container status
    stop              Stop the running container
    clean, cleanup    Remove container and optionally image
    debug             Run with debug output and networking info

Options:
    -b, --build-only      Only build the image, don't run
    -r, --run-only        Only run existing image, don't build
    -n, --name NAME       Container name (default: web3-workstation-local)
    -i, --image IMAGE     Image name (default: web3-workstation:local)
    -p, --ports PORTS     Port mappings (default: 8090:8080,8000:8000)
    -v, --volume PATH     Home directory mount (default: ~/web3-workspace)
    -m, --memory MEM      Memory limit (default: 4g)
    -c, --cpus CPUS       CPU limit (default: 2)
    --no-interactive      Run in background (detached mode)
    --rootful            Use rootful mode (Podman on macOS)
    -h, --help           Show this help message

Examples:
    # Default: build if needed and run
    $0

    # Just build
    $0 build

    # Run with custom settings
    $0 run --memory 8g --cpus 4

    # Check status
    $0 status

    # Run in background
    $0 --no-interactive
    
    # Debug networking (Podman on macOS)
    $0 debug

EOF
}

# Parse command if provided
COMMAND=""
ROOTFUL_MODE="false"
if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; then
    COMMAND="$1"
    shift
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -r|--run-only)
            RUN_ONLY=true
            shift
            ;;
        -n|--name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -p|--ports)
            PORTS="$2"
            shift 2
            ;;
        -v|--volume)
            VOLUME_HOME="$2"
            shift 2
            ;;
        -m|--memory)
            MEMORY="$2"
            shift 2
            ;;
        -c|--cpus)
            CPUS="$2"
            shift 2
            ;;
        --no-interactive)
            INTERACTIVE=false
            shift
            ;;
        --rootful)
            ROOTFUL_MODE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Build the image
build_image() {
    print_header "Building Container Image"
    
    print_info "Image: ${IMAGE_NAME}"
    print_info "Context: docker/"
    
    cd docker
    
    if [ "$RUNTIME" = "podman" ]; then
        print_status "Building with Podman..."
        podman build \
            --format docker \
            --layers \
            -t ${IMAGE_NAME} \
            .
    else
        print_status "Building with Docker..."
        docker build -t ${IMAGE_NAME} .
    fi
    
    if [ $? -eq 0 ]; then
        print_status "Build successful!"
        
        # Show image size
        ${RUNTIME} images ${IMAGE_NAME} --format "table {{.Repository}}:{{.Tag}} {{.Size}}"
    else
        print_error "Build failed!"
        exit 1
    fi
    
    cd ..
}

# Create workspace directory
setup_workspace() {
    print_info "Setting up workspace directory: ${VOLUME_HOME}"
    
    # Create workspace directory if it doesn't exist
    if [ ! -d "${VOLUME_HOME}" ]; then
        print_status "Creating workspace directory..."
        mkdir -p "${VOLUME_HOME}"
        mkdir -p "${VOLUME_HOME}/projects"
        mkdir -p "${VOLUME_HOME}/.config"
        
        # Create a welcome file
        cat > "${VOLUME_HOME}/README.md" << EOF
# Web3 Development Workspace

This is your persistent workspace for Web3 development.

## Available Tools

- **Foundry**: forge, cast, anvil
- **OpenCode TUI**: Run \`opencode\` in terminal
- **Node.js & npm**: For JavaScript development
- **Git**: Version control

## Quick Start

1. Open terminal in VS Code or access via web terminal
2. Create a new Foundry project: \`forge init my-project\`
3. Access OpenCode TUI at: http://localhost:8080

## Directories

- \`projects/\`: Your development projects
- \`.config/\`: Configuration files

EOF
        print_status "Workspace created with README"
    else
        print_info "Using existing workspace"
    fi
}

# Run the container
run_container() {
    print_header "Running Container"
    
    # Check if container already exists
    if ${RUNTIME} ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        print_warning "Container '${CONTAINER_NAME}' already exists"
        read -p "Remove existing container? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Removing existing container..."
            ${RUNTIME} rm -f ${CONTAINER_NAME}
        else
            print_info "Starting existing container..."
            ${RUNTIME} start ${CONTAINER_NAME}
            if [ "$INTERACTIVE" = "true" ]; then
                ${RUNTIME} exec -it ${CONTAINER_NAME} /bin/bash
            fi
            return
        fi
    fi
    
    # Parse port mappings
    PORT_ARGS=""
    IFS=',' read -ra PORT_ARRAY <<< "$PORTS"
    for port in "${PORT_ARRAY[@]}"; do
        PORT_ARGS="${PORT_ARGS} -p ${port}"
    done
    
    print_info "Container: ${CONTAINER_NAME}"
    print_info "Image: ${IMAGE_NAME}"
    print_info "Ports: ${PORTS}"
    print_info "Volume: ${VOLUME_HOME}:/home/user"
    print_info "Resources: ${MEMORY} memory, ${CPUS} CPUs"
    
    # Build run command
    RUN_CMD="${RUNTIME} run"
    RUN_CMD="${RUN_CMD} --name ${CONTAINER_NAME}"
    RUN_CMD="${RUN_CMD} ${PORT_ARGS}"
    RUN_CMD="${RUN_CMD} -v ${VOLUME_HOME}:/home/user"
    RUN_CMD="${RUN_CMD} --memory=${MEMORY}"
    RUN_CMD="${RUN_CMD} --cpus=${CPUS}"
    
    # Pass through Google Cloud environment variables for Vertex AI
    if [ -n "$GOOGLE_CLOUD_PROJECT" ]; then
        RUN_CMD="${RUN_CMD} -e GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}"
    elif [ -n "$CLOUDSDK_CORE_PROJECT" ]; then
        RUN_CMD="${RUN_CMD} -e GOOGLE_CLOUD_PROJECT=${CLOUDSDK_CORE_PROJECT}"
    fi
    
    # Mount Google Cloud credentials if they exist
    if [ -d "$HOME/.config/gcloud" ]; then
        RUN_CMD="${RUN_CMD} -v $HOME/.config/gcloud:/home/developer/.config/gcloud:ro"
        print_info "Mounting Google Cloud credentials for Vertex AI access"
    fi
    
    # Add platform-specific options
    if [ "$RUNTIME" = "podman" ]; then
        if [ "$OS_TYPE" = "macos" ]; then
            if [ "$ROOTFUL_MODE" = "true" ]; then
                print_warning "Using rootful mode for better networking on macOS"
                RUN_CMD="sudo ${RUN_CMD}"
            else
                print_info "Using rootless mode. If ports don't work, try: $0 run --rootful"
            fi
            # Add explicit network mode for macOS
            RUN_CMD="${RUN_CMD} --network=bridge"
        else
            # Linux Podman options
            RUN_CMD="${RUN_CMD} --security-opt label=disable"
            RUN_CMD="${RUN_CMD} --network=host"
            RUN_CMD="${RUN_CMD} --userns=keep-id"
        fi
    fi
    
    # Interactive or detached
    if [ "$INTERACTIVE" = "true" ]; then
        RUN_CMD="${RUN_CMD} -it --rm"
        print_status "Starting in interactive mode..."
    else
        RUN_CMD="${RUN_CMD} -d"
        print_status "Starting in detached mode..."
    fi
    
    RUN_CMD="${RUN_CMD} ${IMAGE_NAME}"
    
    # Add command for interactive mode
    if [ "$INTERACTIVE" = "true" ]; then
        RUN_CMD="${RUN_CMD} /bin/bash"
    fi
    
    # Show the command for debugging
    print_info "Running: ${RUN_CMD}"
    
    # Run the container
    eval ${RUN_CMD}
    
    if [ $? -eq 0 ]; then
        if [ "$INTERACTIVE" = "false" ]; then
            print_status "Container started successfully!"
            echo ""
            print_info "Access points:"
            echo "  • Code-OSS IDE: http://localhost:8000"
            echo "  • OpenCode Terminal: http://localhost:8080"
            echo ""
            print_info "Container commands:"
            echo "  • View logs: ${RUNTIME} logs ${CONTAINER_NAME}"
            echo "  • Enter shell: ${RUNTIME} exec -it ${CONTAINER_NAME} /bin/bash"
            echo "  • Stop: ${RUNTIME} stop ${CONTAINER_NAME}"
            echo "  • Remove: ${RUNTIME} rm ${CONTAINER_NAME}"
            
            # Check if ports are accessible
            sleep 2
            print_info "Testing port accessibility..."
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 | grep -q "200\|302"; then
                print_status "Code-OSS IDE is accessible at http://localhost:8000"
            else
                print_warning "Code-OSS IDE may not be accessible yet. Wait a moment or check: $0 debug"
            fi
            
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
                print_status "OpenCode Terminal is accessible at http://localhost:8080"
            else
                print_warning "OpenCode Terminal may not be accessible yet. Wait a moment or check: $0 debug"
            fi
        fi
    else
        print_error "Failed to start container!"
        exit 1
    fi
}

# Show container status
show_status() {
    print_header "Container Status"
    
    if ${RUNTIME} ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "${CONTAINER_NAME}"; then
        print_status "Container is running"
        echo ""
        ${RUNTIME} ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|${CONTAINER_NAME}"
        echo ""
        print_info "Access points:"
        echo "  • Code-OSS IDE: http://localhost:8000"
        echo "  • OpenCode Terminal: http://localhost:8080"
        
        # Test connectivity
        echo ""
        print_info "Testing connectivity..."
        curl -s -o /dev/null -w "  • Port 8000: %{http_code}\n" http://localhost:8000 || echo "  • Port 8000: Not accessible"
        curl -s -o /dev/null -w "  • Port 8080: %{http_code}\n" http://localhost:8080 || echo "  • Port 8080: Not accessible"
    else
        print_warning "Container is not running"
        
        if ${RUNTIME} ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            print_info "Container exists but is stopped"
            echo "  Run: ${RUNTIME} start ${CONTAINER_NAME}"
        else
            print_info "Container does not exist"
            echo "  Run: $0 to create and start"
        fi
    fi
}

# Debug networking
debug_networking() {
    print_header "Debug Networking"
    
    detect_runtime
    
    if [ "$RUNTIME" = "podman" ]; then
        print_info "Podman networking information:"
        echo ""
        
        if [ "$OS_TYPE" = "macos" ]; then
            print_warning "Podman on macOS networking notes:"
            echo "  • Podman runs in a VM on macOS"
            echo "  • Port forwarding must go through the VM"
            echo ""
            
            print_info "Checking Podman machine..."
            podman machine list
            echo ""
            
            print_info "Machine port forwarding:"
            podman machine inspect 2>/dev/null | grep -A5 "Port" || echo "Could not get machine info"
            echo ""
            
            print_info "Testing solutions:"
            echo "  1. Use rootful mode: $0 run --rootful"
            echo "  2. Check podman machine: podman machine ssh"
            echo "  3. Inside machine, check: ss -tlnp | grep -E '8000|8080'"
            echo "  4. Port forward manually:"
            echo "     podman machine ssh -- -L 8000:localhost:8000 -L 8080:localhost:8080"
        fi
        
        print_info "Container network info:"
        if ${RUNTIME} ps --format "{{.Names}}" | grep -q "${CONTAINER_NAME}"; then
            echo "Container IP:"
            ${RUNTIME} inspect ${CONTAINER_NAME} --format '{{.NetworkSettings.IPAddress}}' || echo "N/A"
            echo ""
            echo "Port mappings:"
            ${RUNTIME} port ${CONTAINER_NAME}
        else
            print_warning "Container not running"
        fi
    fi
    
    print_info "Host network tests:"
    echo "  • localhost:8000: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 2>/dev/null || echo "Failed")"
    echo "  • localhost:8080: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "Failed")"
    echo "  • 127.0.0.1:8000: $(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000 2>/dev/null || echo "Failed")"
    echo "  • 127.0.0.1:8080: $(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080 2>/dev/null || echo "Failed")"
}

# Stop the container
stop_container() {
    print_header "Stopping Container"
    
    if ${RUNTIME} ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        print_info "Stopping ${CONTAINER_NAME}..."
        ${RUNTIME} stop ${CONTAINER_NAME}
        print_status "Container stopped"
    else
        print_warning "Container is not running"
    fi
}

# Clean up
cleanup() {
    print_header "Cleanup"
    
    read -p "Remove container and image? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Stop and remove container
        if ${RUNTIME} ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            print_info "Removing container..."
            ${RUNTIME} rm -f ${CONTAINER_NAME}
        fi
        
        # Remove image
        if ${RUNTIME} images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}$"; then
            print_info "Removing image..."
            ${RUNTIME} rmi ${IMAGE_NAME}
        fi
        
        print_status "Cleanup complete"
        
        read -p "Remove workspace directory? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Removing ${VOLUME_HOME}..."
            rm -rf ${VOLUME_HOME}
            print_status "Workspace removed"
        fi
    else
        print_info "Cleanup cancelled"
    fi
}

# Main execution
main() {
    # Handle commands based on first argument or COMMAND variable
    case "${COMMAND:-$1}" in
        build)
            print_header "Web3 Workstation - Build"
            detect_runtime
            build_image
            print_status "Image built successfully"
            echo "Run with: $0 run"
            exit 0
            ;;
        status)
            show_status
            exit 0
            ;;
        stop)
            stop_container
            exit 0
            ;;
        debug)
            debug_networking
            exit 0
            ;;
        cleanup|clean)
            cleanup
            exit 0
            ;;
        run|"")
            # Default action is run (which includes build if needed)
            print_header "Web3 Workstation - Local Development"
            detect_runtime
            
            # Handle build/run flags for backward compatibility
            if [ "$BUILD_ONLY" = "true" ] && [ "$RUN_ONLY" = "true" ]; then
                print_error "Cannot use --build-only and --run-only together"
                exit 1
            fi
            
            if [ "$BUILD_ONLY" = "true" ]; then
                build_image
                print_status "Image built successfully"
                echo "Run with: $0 run"
                exit 0
            fi
            
            # Default behavior: build if image doesn't exist, then run
            if [ "$RUN_ONLY" != "true" ]; then
                # Check if image exists
                if ! ${RUNTIME} images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}$"; then
                    print_info "Image not found, building..."
                    build_image
                fi
            fi
            
            setup_workspace
            run_container
            
            print_header "Ready!"
            
            if [ "$INTERACTIVE" = "true" ]; then
                print_status "Exited from container"
            else
                print_status "Container is running in background"
            fi
            ;;
        *)
            print_error "Unknown command: ${COMMAND:-$1}"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"