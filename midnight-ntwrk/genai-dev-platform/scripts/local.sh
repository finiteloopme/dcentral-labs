#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="midnight-vibe-platform"
IMAGE_NAME="midnight-vibe-platform"

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
    print_status "Building Midnight Vibe Platform..."
    podman build -t $IMAGE_NAME .
    print_status "Build completed successfully!"
}

# Run the container locally
run_container() {
    print_status "Running Midnight Vibe Platform locally..."
    
    # Stop existing container if running
    stop_container
    
    # Run the container
    podman run -d \
        --name $CONTAINER_NAME \
        --privileged \
        --entrypoint /usr/bin/supervisord \
        -p 9944:9944 \
        -p 9933:9933 \
        -p 5432:5432 \
        -p 8080:8080 \
        $IMAGE_NAME \
        -c /etc/supervisor/supervisord.conf
    
    print_status "Container started successfully!"
    echo ""
    echo "Services:"
    echo "  - Midnight Node RPC: http://localhost:9933"
    echo "  - Midnight Node WS: ws://localhost:9944"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Proof Server: http://localhost:8080"
    echo ""
    echo "To view logs:"
    echo "  $0 logs"
    echo ""
    echo "To stop:"
    echo "  $0 stop"
}

# Stop and remove container
stop_container() {
    print_status "Stopping Midnight Vibe Platform..."
    
    if podman ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        podman stop $CONTAINER_NAME
        podman rm $CONTAINER_NAME
        print_status "Container stopped and removed."
    else
        print_warning "No running container found."
    fi
}

# Clean up images and containers
clean_resources() {
    print_status "Cleaning up Midnight Vibe Platform resources..."
    podman stop $CONTAINER_NAME 2>/dev/null || true
    podman rm $CONTAINER_NAME 2>/dev/null || true
    podman rmi $IMAGE_NAME 2>/dev/null || true
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

# Create midnight database (helper function)
create_database() {
    print_status "Creating midnight database..."
    if podman ps -q -f name=$CONTAINER_NAME | grep -q .; then
        podman exec $CONTAINER_NAME bash -c "sudo -u postgres /usr/lib/postgresql/16/bin/createdb midnight 2>/dev/null || true"
        print_status "Database created (or already exists)."
    else
        print_error "Container is not running. Start it with: $0 run"
    fi
}

# Restart services
restart_services() {
    print_status "Restarting services..."
    if podman ps -q -f name=$CONTAINER_NAME | grep -q .; then
        podman exec $CONTAINER_NAME supervisorctl restart midnight-node
        podman exec $CONTAINER_NAME supervisorctl restart midnight-pubsub-indexer
        print_status "Services restarted."
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
    echo "  db          Create midnight database"
    echo "  restart     Restart services"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build    # Build the image"
    echo "  $0 run      # Run the container"
    echo "  $0 logs     # View logs"
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
        sleep 5
        create_database
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
    db)
        check_podman
        create_database
        ;;
    restart)
        check_podman
        restart_services
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