#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="midnight-dev-platform"
IMAGE_NAME="midnight-dev-local"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if podman is available
check_podman() {
    if ! command -v podman &> /dev/null; then
        print_error "podman is not installed or not in PATH"
        exit 1
    fi
}

# Build the container image
build_image() {
    # update_perms
    print_status "Building Midnight Vibe Platform..."
    podman build -t $IMAGE_NAME .
    print_status "Build completed successfully!"
}

# change permissions to make podman work as sudo
update_perms() {
    print_status "Updating permissions..."
    sudo chown -R kunall:primarygroup /run/user/628449/containers/
    sudo chown -R kunall:primarygroup /home/kunall/.local/share/containers/storage/
}

# Run the container locally
run_container() {
    
    print_status "Running Midnight Vibe Platform locally..."
    
    # Stop existing container if running
    stop_container

    
    # Mount Google Cloud application default credentials if they exist
    GCREDS_FILE="$HOME/.config/gcloud/application_default_credentials.json"
    if [ -f "$GCREDS_FILE" ]; then
        print_status "Mounting Google Cloud credentials..."
        GCREDS_MOUNT="-v $GCREDS_FILE:/tmp/gcloud-creds.json:ro"
    else
        print_warning "Google Cloud credentials not found at $GCREDS_FILE"
        print_warning "You'll need to run 'gcloud auth application-default login' in the container"
        GCREDS_MOUNT=""
    fi
    
    # Run the container
    podman run -d \
        --name ${CONTAINER_NAME} \
        --rm \
        --privileged \
        -p 8080:8080 \
        -p 8081:8081 \
        -p 8088:8088 \
        -p 9933:9933 \
        -p 9944:9944 \
        -e MIDNIGHT_CFG_PRESET=dev \
        -e GOOGLE_VERTEX_PROJECT=${GOOGLE_VERTEX_PROJECT:-} \
        -e GOOGLE_VERTEX_REGION=${GOOGLE_VERTEX_REGION:-us-central1} \
        ${GCREDS_MOUNT} \
        ${IMAGE_NAME}

    print_status "Container started successfully!"
    echo ""
    echo "Services:"
    echo "  - Code OSS (VS Code): http://127.0.0.1:8080"
    echo "  - Midnight Node RPC: http://127.0.0.1:9933"
    echo "  - Midnight Node WS: ws://127.0.0.1:9944"
    echo "  - Proof Server: http://127.0.0.1:8081"
    echo "  - Indexer API: http://127.0.0.1:8088"
    echo ""
    echo "To view logs:"
    echo "  $0 logs"
    echo ""
    echo "To stop:"
    echo "  $0 stop"
    echo ""
    echo "Note: Container running with Cloud Workstations configuration"
}

# Stop and remove container
stop_container() {
    print_status "Stopping Midnight Vibe Platform..."

    if podman ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        podman stop $CONTAINER_NAME || true
        podman rm $CONTAINER_NAME
        print_status "Container stopped and removed."
    else
        print_warning "No running container found."
    fi
}

# Clean up images and containers
clean_resources() {
    print_status "Cleaning up Midnight Vibe Platform resources..."
    podman stop --time 15 $CONTAINER_NAME 2>/dev/null || true
    podman rm -f $CONTAINER_NAME 2>/dev/null || true
    podman rmi -f $IMAGE_NAME 2>/dev/null || true
    print_status "Cleanup completed."
}

# Show container status
show_status() {
    echo "Midnight Vibe Platform Status:"
    podman ps -a -f name=$CONTAINER_NAME
}

# View container logs
show_logs() {
    if podman ps -q -f name=$CONTAINER_NAME | grep -q .; then
        podman logs -f $CONTAINER_NAME
    else
        print_error "Container is not running. Start it with: $0 run"
    fi
}

# Database not needed for dev preset
# Midnight services run in standalone mode

# Restart services
restart_services() {
    print_status "Restarting container (Cloud Workstations manages services automatically)..."
    if podman ps -q -f name=$CONTAINER_NAME | grep -q .; then
        podman restart $CONTAINER_NAME
        print_status "Container restarted."
    else
        print_error "Container is not running. Start it with: $0 run"
    fi
}

# Execute command in container
exec_command() {
    if podman ps -q -f name=$CONTAINER_NAME | grep -q .; then
        podman exec $CONTAINER_NAME "$@"
    else
        print_error "Container is not running. Start it with: $0 run"
    fi
}

# Show help
show_help() {
    echo "Midnight Vibe Platform - Local Development Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build       Build the container image"
    echo "  run         Run the container locally"
    echo "  stop        Stop and remove the container"
    echo "  clean       Clean up images and containers"
    echo "  status      Show container status"
    echo "  logs        View container logs"

    echo "  restart     Restart services"
    echo "  exec        Execute command in container"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build    # Build the image"
    echo "  $0 run      # Run the container"
    echo "  $0 logs     # View logs"
    echo "  $0 exec \"supervisorctl status\"  # Execute command in container"
}

# Main script logic
case "${1:-help}" in
    build)
        check_podman
        build_image
        ;;
    run)
        check_podman
        run_container
        ;;
    stop)
        check_podman
        stop_container
        ;;
    clean)
        check_podman
        clean_resources
        ;;
    status)
        check_podman
        show_status
        ;;
    logs)
        check_podman
        show_logs
        ;;

    restart)
        check_podman
        restart_services
        ;;
    exec)
        check_podman
        shift
        exec_command "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac