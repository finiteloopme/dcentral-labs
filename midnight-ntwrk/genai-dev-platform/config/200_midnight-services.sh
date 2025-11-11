#!/bin/bash
# Midnight Vibe Platform - Workstation Services Script
# Simplified version using dev preset (no PostgreSQL required)

echo "🌙 Initializing Midnight Development Stack (Dev Mode)..."

# Create Midnight development directories
mkdir -p /opt/midnight-dev/{logs,data,config,bin}
chown -R user:user /opt/midnight-dev

# Create service management scripts
cat > /opt/midnight-dev/bin/manage-services.sh << 'EOF'
#!/bin/bash
# Midnight Services Management Script - Dev Preset

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
MIDNIGHT_DEV_DIR="/opt/midnight-dev"
LOG_DIR="$MIDNIGHT_DEV_DIR/logs"
DATA_DIR="$MIDNIGHT_DEV_DIR/data"

# Service status check
check_service() {
    local service=$1
    local port=$2
    
    if nc -z localhost $port 2>/dev/null; then
        echo -e "${GREEN}✅ $service${NC} (port $port)"
        return 0
    else
        echo -e "${RED}❌ $service${NC} (port $port)"
        return 1
    fi
}

# Start Midnight Node function
start_node() {
    echo "🔗 Starting Midnight Node (v0.8.0 dev mode)..."
    cd /usr/local/bin
    
    # Use simple dev preset like the example
    export CFG_PRESET=dev
    export RUST_BACKTRACE=full
    
    nohup midnight-node --rpc-port 9944 \
        > /opt/midnight-dev/logs/midnight-node.log 2>&1 &
    echo $! > /opt/midnight-dev/data/midnight-node.pid
    sleep 10  # Give node time to initialize
}

# Start Proof Server function
start_proof() {
    echo "🔐 Starting Proof Server..."
    cd /opt/midnight-dev
    
    # Use environment variable from the example
    export RUST_BACKTRACE=full
    
    nohup midnight-proof-server --port 8081 \
        > logs/proof-server.log 2>&1 &
    echo $! > data/proof-server.pid
    sleep 3
}

# Start Indexer function
start_indexer() {
    echo "📊 Starting Indexer..."
    cd /opt/midnight-dev
    
    # Use config file and environment variables
    export LOG_LEVEL=INFO
    export LEDGER_NETWORK_ID=TestNet
    export SUBSTRATE_NODE_WS_URL=ws://localhost:9944
    export OTEL_JAVAAGENT_ENABLED=false
    
    nohup midnight-pubsub-indexer --config config/indexer-simple.yaml \
        > logs/indexer.log 2>&1 &
    echo $! > data/indexer.pid
    sleep 5
}

# Start all services
start_all() {
    start_node
    start_proof
    start_indexer
    
    echo ""
    echo -e "${GREEN}✅ Midnight Development Stack started successfully!${NC}"
    echo ""
    echo -e "${BLUE}🌐 Available Services:${NC}"
    echo -e "  🔗 Midnight Node: http://localhost:9944"
    echo -e "  🔐 Proof Server: http://localhost:8081"
    echo -e "  📊 Indexer API: http://localhost:8088"
    echo ""
    echo -e "${BLUE}🔧 Management Commands:${NC}"
    echo -e "  midnight-dev status    # Show service status"
    echo -e "  midnight-dev logs     # Show logs (node/proof/indexer/all)"
    echo -e "  midnight-dev restart  # Restart all services"
}

# Stop all services
stop_all() {
    echo "🛑 Stopping Midnight services..."
    
    # Stop Midnight Node
    if [ -f /opt/midnight-dev/data/midnight-node.pid ]; then
        kill $(cat /opt/midnight-dev/data/midnight-node.pid) 2>/dev/null || true
        rm -f /opt/midnight-dev/data/midnight-node.pid
    fi
    
    # Stop Proof Server
    if [ -f /opt/midnight-dev/data/proof-server.pid ]; then
        kill $(cat /opt/midnight-dev/data/proof-server.pid) 2>/dev/null || true
        rm -f /opt/midnight-dev/data/proof-server.pid
    fi
    
    # Stop Indexer
    if [ -f /opt/midnight-dev/data/indexer.pid ]; then
        kill $(cat /opt/midnight-dev/data/indexer.pid) 2>/dev/null || true
        rm -f /opt/midnight-dev/data/indexer.pid
    fi
    
    echo -e "${GREEN}✅ Midnight services stopped${NC}"
}

# Restart all services
restart_all() {
    stop_all
    sleep 2
    start_all
}

# Show service status
show_status() {
    echo -e "${BLUE}🌙 Midnight Development Stack Status (Dev Mode)${NC}"
    echo ""
    check_service "Midnight Node" 9944
    check_service "Proof Server" 8081
    check_service "Indexer API" 8088
    echo ""
}

# Show logs
show_logs() {
    local service=${1:-all}
    
    case $service in
        node)
            echo -e "${BLUE}🔗 Midnight Node Logs:${NC}"
            tail -f /opt/midnight-dev/logs/midnight-node.log 2>/dev/null || echo "No logs found"
            ;;
        proof)
            echo -e "${BLUE}🔐 Proof Server Logs:${NC}"
            tail -f /opt/midnight-dev/logs/proof-server.log 2>/dev/null || echo "No logs found"
            ;;
        indexer)
            echo -e "${BLUE}📊 Indexer Logs:${NC}"
            tail -f /opt/midnight-dev/logs/indexer.log 2>/dev/null || echo "No logs found"
            ;;
        all)
            echo -e "${BLUE}🌙 All Midnight Services Logs:${NC}"
            tail -f /opt/midnight-dev/logs/*.log 2>/dev/null || echo "No logs found"
            ;;
        *)
            echo "Usage: midnight-dev logs [node|proof|indexer|all]"
            exit 1
            ;;
    esac
}

# Main logic
case "${1:-start}" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    *)
        echo "Usage: manage-services.sh [start|stop|restart|status|logs] [service]"
        echo "Services: node, proof, indexer, all"
        exit 1
        ;;
esac
EOF

chmod +x /opt/midnight-dev/bin/manage-services.sh

# Create midnight-dev symlink
ln -sf /opt/midnight-dev/bin/manage-services.sh /usr/local/bin/midnight-dev

# Start services automatically
echo "🚀 Starting Midnight services..."
sudo -u user /opt/midnight-dev/bin/manage-services.sh start &

# Set proper permissions
chown -R user:user /opt/midnight-dev

echo "✅ Midnight Development Stack initialization complete!"
echo ""
echo "🌐 Available services:"
echo "   - Midnight Node: http://localhost:9944"
echo "   - Proof Server: http://localhost:8081"
echo "   - Indexer API: http://localhost:8088"
echo ""
echo "🔧 Management commands:"
echo "   midnight-dev status    # Show service status"
echo "   midnight-dev logs     # Show logs (node/proof/indexer/all)"
echo "   midnight-dev restart  # Restart all services"
echo ""
echo "📝 Note: Running in dev mode (no PostgreSQL required)"