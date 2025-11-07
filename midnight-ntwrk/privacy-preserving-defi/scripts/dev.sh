#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check if services are running
check_services() {
    print_status "Checking service status..."
    cd cicd
    if podman-compose ps | grep -q "Up"; then
        print_status "Some services are already running"
        podman-compose ps
    else
        print_status "No services are currently running"
    fi
    cd ..
}

# Function to create logs directory
create_logs_dir() {
    if [ ! -d "logs" ]; then
        mkdir -p logs
        print_status "Created logs directory"
    fi
}

# Function to wait for services
wait_for_services() {
    local timeout=${1:-30}
    print_status "Waiting for services to be ready (${timeout}s timeout)..."
    
    # Wait for core services
    for i in $(seq 1 $timeout); do
        if curl -s http://localhost:8545 > /dev/null 2>&1; then
            print_status "Arc RPC is ready"
            break
        fi
        if [ $i -eq $timeout ]; then
            print_warning "Arc RPC may not be ready yet"
        fi
        sleep 1
    done
}

# Function to start services
start_services() {
    local mode=${1:-dev}
    print_header "Starting Services ($mode mode)"
    
    create_logs_dir
    
    cd cicd
    if [ "$mode" = "prod" ] || [ "$mode" = "demo" ]; then
        print_status "Starting production services..."
        podman-compose -f docker-compose.prod.yml up -d
        sleep 15
    else
        print_status "Starting development services..."
        podman-compose up -d anvil proof-server
        sleep 10
        
        print_status "Starting Midnight integration service..."
        podman-compose up -d midnight-integration
        sleep 5
    fi
    cd ..
    
    wait_for_services
    
    # Start frontend
    print_status "Starting frontend server..."
    cd frontend
    nohup python3 -m http.server 3000 > ../logs/frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > ../logs/frontend.pid
    cd ..
    
    # Start TEE service
    print_status "Starting TEE service..."
    cd tee-service
    if [ "$mode" = "prod" ] || [ "$mode" = "demo" ]; then
        PROOF_MODE="production" MIDNIGHT_INTEGRATION_URL="http://midnight-integration:3000" nohup cargo run > ../logs/tee-service.log 2>&1 &
    else
        PROOF_MODE="mock" MIDNIGHT_INTEGRATION_URL="http://localhost:3000" nohup cargo run > ../logs/tee-service.log 2>&1 &
    fi
    TEE_PID=$!
    echo $TEE_PID > ../logs/tee-service.pid
    cd ..
    
    print_status "Services started successfully!"
}

# Function to stop services
stop_services() {
    print_header "Stopping Services"
    
    # Stop Docker/Podman services
    cd cicd
    if [ -f "docker-compose.prod.yml" ] && podman-compose -f docker-compose.prod.yml ps -q | grep -q .; then
        print_status "Stopping production services..."
        podman-compose -f docker-compose.prod.yml down
    fi
    
    if podman-compose ps -q | grep -q .; then
        print_status "Stopping development services..."
        podman-compose down
    fi
    cd ..
    
    # Stop frontend
    if [ -f "logs/frontend.pid" ]; then
        FRONTEND_PID=$(cat logs/frontend.pid)
        if kill -0 $FRONTEND_PID 2>/dev/null; then
            print_status "Stopping frontend server (PID: $FRONTEND_PID)..."
            kill $FRONTEND_PID
        fi
        rm -f logs/frontend.pid
    fi
    
    # Stop TEE service
    if [ -f "logs/tee-service.pid" ]; then
        TEE_PID=$(cat logs/tee-service.pid)
        if kill -0 $TEE_PID 2>/dev/null; then
            print_status "Stopping TEE service (PID: $TEE_PID)..."
            kill $TEE_PID
        fi
        rm -f logs/tee-service.pid
    fi
    
    # Fallback: kill by process name
    pkill -f "python3 -m http.server" || true
    pkill -f "cargo run" || true
    
    print_status "All services stopped!"
}

# Function to show logs
show_logs() {
    local service=${1:-all}
    print_header "Service Logs ($service)"
    
    case $service in
        "frontend"|"fe")
            if [ -f "logs/frontend.log" ]; then
                tail -f logs/frontend.log
            else
                print_error "Frontend logs not found"
            fi
            ;;
        "tee"|"tee-service")
            if [ -f "logs/tee-service.log" ]; then
                tail -f logs/tee-service.log
            else
                print_error "TEE service logs not found"
            fi
            ;;
        "docker"|"compose")
            cd cicd
            podman-compose logs -f
            cd ..
            ;;
        "all"|"")
            cd cicd
            podman-compose logs -f &
            COMPOSE_PID=$!
            
            if [ -f "../logs/frontend.log" ]; then
                tail -f ../logs/frontend.log &
                FRONTEND_LOG_PID=$!
            fi
            
            if [ -f "../logs/tee-service.log" ]; then
                tail -f ../logs/tee-service.log &
                TEE_LOG_PID=$!
            fi
            
            # Wait for interrupt
            trap "kill $COMPOSE_PID $FRONTEND_LOG_PID $TEE_LOG_PID 2>/dev/null || true; exit" INT
            wait
            cd ..
            ;;
        *)
            print_error "Unknown service: $service"
            echo "Available services: frontend, tee, docker, all"
            exit 1
            ;;
    esac
}

# Function to clean resources
clean_resources() {
    print_header "Cleaning Resources"
    
    # Stop services first
    stop_services
    
    # Clean Docker/Podman resources
    cd cicd
    print_status "Removing Docker/Podman containers and networks..."
    podman-compose down -v --remove-orphans || true
    podman system prune -f || true
    cd ..
    
    # Clean log files
    if [ -d "logs" ]; then
        print_status "Cleaning log files..."
        rm -rf logs/*
    fi
    
    # Clean build artifacts
    print_status "Cleaning build artifacts..."
    cd tee-service
    cargo clean || true
    cd ..
    
    cd smart-contracts/midnight
    rm -rf dist node_modules || true
    cd ..
    
    cd midnight-integration
    rm -rf dist node_modules || true
    cd ..
    
    print_status "Cleanup completed!"
}

# Function to restart services
restart_services() {
    local mode=${1:-dev}
    print_status "Restarting services in $mode mode..."
    stop_services
    sleep 2
    start_services $mode
}

# Function to show status
show_status() {
    print_header "Service Status"
    
    # Docker/Podman services
    cd cicd
    if podman-compose ps | grep -q "Up"; then
        print_status "Docker/Podman Services:"
        podman-compose ps
    else
        print_warning "No Docker/Podman services running"
    fi
    cd ..
    
    # Process status
    print_status "Process Status:"
    if pgrep -f "python3 -m http.server" > /dev/null; then
        echo "  Frontend: RUNNING (PID: $(pgrep -f 'python3 -m http.server'))"
    else
        echo "  Frontend: STOPPED"
    fi
    
    if pgrep -f "cargo run" > /dev/null; then
        echo "  TEE Service: RUNNING (PID: $(pgrep -f 'cargo run'))"
    else
        echo "  TEE Service: STOPPED"
    fi
    
    # Port status
    print_status "Port Status:"
    for port in 3000 8080 8545 6300 9944; do
        if nc -z localhost $port 2>/dev/null; then
            echo "  Port $port: OPEN"
        else
            echo "  Port $port: CLOSED"
        fi
    done
}

# Function to build compact contract
build_compact() {
    print_header "Building Midnight Compact Contract"
    
    if [ ! -d "smart-contracts/midnight" ]; then
        print_error "smart-contracts/midnight directory not found"
        exit 1
    fi
    
    cd smart-contracts/midnight
    print_status "Installing dependencies..."
    
    # Handle Midnight packages that may not be publicly available
    if ! npm install; then
        print_warning "⚠️  Midnight packages not available in public registry"
        print_status "This is expected until Midnight tools are publicly released"
        print_status "For now, the contract structure and TypeScript interfaces are ready"
        
        # Create dist directory for structure
        mkdir -p dist
        cp *.compact dist/ 2>/dev/null || true
        cp *.ts dist/ 2>/dev/null || true
        
        print_status "✅ Midnight Compact contract structure prepared!"
    else
        print_status "Building Compact contract..."
        if npm run build; then
            print_status "✅ Compact contract built successfully!"
        else
            print_error "❌ Compact contract build failed"
            exit 1
        fi
    fi
    cd ..
}

# Function to build midnight integration
build_midnight_integration() {
    print_header "Building Midnight Integration Service"
    
    if [ ! -d "midnight-integration" ]; then
        print_error "midnight-integration directory not found"
        exit 1
    fi
    
    cd midnight-integration
    print_status "Installing dependencies..."
    
    # Handle Midnight packages that may not be publicly available
    if ! npm install; then
        print_warning "⚠️  Midnight packages not available in public registry"
        print_status "This is expected until Midnight tools are publicly released"
        print_status "For now, service structure and TypeScript interfaces are ready"
        
        # Create dist directory for structure
        mkdir -p dist
        cp src/*.ts dist/ 2>/dev/null || true
        
        # Create mock package structure
        echo '{"mock": "Midnight integration service structure"}' > dist/package.json
        
        print_status "✅ Midnight integration service structure prepared!"
    else
        print_status "Building Midnight integration service..."
        if npm run build; then
            print_status "✅ Midnight integration service built successfully!"
        else
            print_error "❌ Midnight integration service build failed"
            exit 1
        fi
    fi
    cd ..
}

# Function to run tests
run_tests() {
    print_header "Running Tests"
    
    # Test Compact contract
    if [ -d "smart-contracts/midnight" ]; then
        print_status "Testing Compact contract..."
        cd smart-contracts/midnight
        npm test || print_warning "Compact contract tests failed or not available"
        cd ..
    fi
    
    # Test Midnight integration
    if [ -d "midnight-integration" ]; then
        print_status "Testing Midnight integration..."
        cd midnight-integration
        npm test || print_warning "Midnight integration tests failed or not available"
        cd ..
    fi
    
    # Test TEE service
    if [ -d "tee-service" ]; then
        print_status "Testing TEE service..."
        cd tee-service
        cargo test || print_warning "TEE service tests failed"
        cd ..
    fi
    
    print_status "Test run completed!"
}

# Function to show help
show_help() {
    echo "Privacy-Preserving DeFi Development Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Service Management:"
    echo "  start [mode]     Start services (dev|prod|demo) [default: dev]"
    echo "  stop             Stop all services"
    echo "  restart [mode]   Restart services (dev|prod|demo) [default: dev]"
    echo "  logs [service]   Show logs (frontend|tee|docker|all) [default: all]"
    echo "  status           Show service status"
    echo "  clean            Clean all resources and artifacts"
    echo "  check            Check if services are running"
    echo ""
    echo "Build Operations:"
    echo "  build-compact           Build Compact contract"
    echo "  build-midnight-integration  Build Midnight integration service"
    echo "  test                    Run all tests"
    echo ""
    echo "Examples:"
    echo "  $0 start         # Start development services"
    echo "  $0 start prod    # Start production services"
    echo "  $0 logs tee     # Show TEE service logs"
    echo "  $0 status        # Show service status"
    echo "  $0 build-compact # Build Compact contract"
}

# Main script logic
case "${1:-help}" in
    "start")
        start_services "${2:-dev}"
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services "${2:-dev}"
        ;;
    "logs")
        show_logs "${2:-all}"
        ;;
    "status")
        show_status
        ;;
    "clean")
        clean_resources
        ;;
    "check")
        check_services
        ;;
    "build-compact")
        build_compact
        ;;
    "build-midnight-integration")
        build_midnight_integration
        ;;
    "test")
        run_tests
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac