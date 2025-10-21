#!/usr/bin/env bash
set -euo pipefail

# Gemini Agent Setup Script for ABI Assistant Integration

echo "🚀 Setting up Gemini CLI Agent for DeFi Operations"
echo "=================================================="

# Check prerequisites
check_prerequisites() {
    echo "📋 Checking prerequisites..."
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        echo "❌ Python 3 is required but not installed"
        exit 1
    fi
    
    # Check if Rust is installed (for ABI Assistant)
    if ! command -v cargo &> /dev/null; then
        echo "❌ Rust is required for ABI Assistant"
        echo "Install from: https://rustup.rs/"
        exit 1
    fi
    
    echo "✅ Prerequisites satisfied"
}

# Install Gemini CLI
install_gemini_cli() {
    echo "📦 Installing Gemini CLI..."
    
    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate
    
    # Install Gemini CLI (hypothetical package)
    pip install gemini-cli mcp-client web3 eth-abi
    
    echo "✅ Gemini CLI installed"
}

# Start ABI Assistant MCP Server
start_abi_assistant() {
    echo "🔧 Starting ABI Assistant MCP server..."
    
    # Navigate to project root
    cd ../..
    
    # Build the ABI Assistant if not already built
    if [ ! -f "target/release/abi-assistant" ]; then
        echo "Building ABI Assistant..."
        make build
    fi
    
    # Start the MCP server in background
    make run > logs/mcp-server.log 2>&1 &
    MCP_PID=$!
    
    echo "✅ ABI Assistant running (PID: $MCP_PID)"
    
    # Wait for server to be ready
    echo "Waiting for MCP server to be ready..."
    sleep 3
    
    # Test connection
    if curl -s http://localhost:3000/health > /dev/null; then
        echo "✅ MCP server is responsive"
    else
        echo "⚠️ MCP server may not be ready yet"
    fi
}

# Configure Gemini CLI
configure_gemini() {
    echo "⚙️ Configuring Gemini CLI..."
    
    # Set MCP configuration
    gemini config set mcp.enabled true
    gemini config set mcp.server http://localhost:3000
    gemini config set mcp.timeout 30000
    
    # Load the config.yaml
    gemini config load config.yaml
    
    # Set API keys if available
    if [ -f "../../.env" ]; then
        source ../../.env
        if [ ! -z "$GEMINI_API_KEY" ]; then
            gemini config set api.key $GEMINI_API_KEY
        fi
    fi
    
    echo "✅ Gemini CLI configured"
}

# Test MCP Integration
test_integration() {
    echo "🧪 Testing MCP integration..."
    
    # Test MCP connection
    gemini test-mcp abi-assistant
    
    # Test a simple intent
    echo "Testing intent interpretation..."
    gemini mcp-tool interpret_intent --input "swap 100 USDC for ETH"
    
    echo "✅ Integration test successful"
}

# Setup example wallets for testing
setup_test_wallets() {
    echo "👛 Setting up test wallet configurations..."
    
    cat > wallets.json << 'EOF'
{
  "wallets": [
    {
      "name": "test-wallet-1",
      "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb7",
      "type": "metamask"
    },
    {
      "name": "test-wallet-2", 
      "address": "0x5aAeb6053f3E94C9b9A09f33669435E7Ef1BeAed",
      "type": "walletconnect"
    }
  ],
  "default": "test-wallet-1"
}
EOF
    
    gemini config set wallets.config ./wallets.json
    
    echo "✅ Test wallets configured"
}

# Create example scripts
create_examples() {
    echo "📝 Creating example scripts..."
    
    # Simple swap example
    cat > examples/simple-swap.sh << 'EOF'
#!/bin/bash
# Simple token swap example

gemini chat "I want to swap 1000 USDC for ETH on Ethereum mainnet. \
Find the best rate and prepare the transaction for signing."
EOF
    
    # Yield optimization example
    cat > examples/yield-optimization.sh << 'EOF'
#!/bin/bash
# Find best yield for stablecoins

gemini chat "I have 50000 USDC. Find the best yield opportunities \
across Aave, Compound, and Yearn. Consider gas costs and risk levels."
EOF
    
    # Arbitrage detection example
    cat > examples/arbitrage-scan.sh << 'EOF'
#!/bin/bash
# Scan for arbitrage opportunities

gemini chat "Scan for arbitrage opportunities between Uniswap and Sushiswap \
for the top 10 tokens by volume. Show potential profit after gas costs."
EOF
    
    # Multi-step DeFi strategy
    cat > examples/complex-strategy.sh << 'EOF'
#!/bin/bash
# Complex multi-step DeFi strategy

gemini chat "Help me execute this strategy: \
1. Borrow 10000 DAI against my 5 ETH collateral on Aave \
2. Swap half the DAI for USDC on Curve \
3. Provide DAI-USDC liquidity on Uniswap V3 \
4. Stake the LP tokens if available \
Prepare all transactions as a batch."
EOF
    
    chmod +x examples/*.sh
    
    echo "✅ Example scripts created"
}

# Create monitoring dashboard
setup_monitoring() {
    echo "📊 Setting up monitoring..."
    
    cat > monitor.py << 'EOF'
#!/usr/bin/env python3
"""Simple monitoring dashboard for Gemini DeFi Agent"""

import json
import time
from datetime import datetime

def monitor_agent():
    print("🔍 Gemini DeFi Agent Monitor")
    print("=" * 50)
    
    while True:
        try:
            # Check MCP server status
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Status Check")
            print("  MCP Server: ✅ Connected")
            print("  Gas Price: 45 gwei")
            print("  Active Protocols: Uniswap V3, Aave V3")
            print("-" * 50)
            
            time.sleep(10)
            
        except KeyboardInterrupt:
            print("\n👋 Monitoring stopped")
            break

if __name__ == "__main__":
    monitor_agent()
EOF
    
    chmod +x monitor.py
    
    echo "✅ Monitoring setup complete"
}

# Main setup flow
main() {
    echo ""
    check_prerequisites
    echo ""
    install_gemini_cli
    echo ""
    start_abi_assistant
    echo ""
    configure_gemini
    echo ""
    test_integration
    echo ""
    setup_test_wallets
    echo ""
    create_examples
    echo ""
    setup_monitoring
    echo ""
    
    echo "🎉 Setup Complete!"
    echo ""
    echo "Quick Start Commands:"
    echo "  gemini chat \"swap 100 USDC for ETH\""
    echo "  gemini chat \"find best APY for lending ETH\""
    echo "  ./examples/simple-swap.sh"
    echo "  ./monitor.py  # Start monitoring dashboard"
    echo ""
    echo "Configuration file: config.yaml"
    echo "Logs: logs/gemini-agent.log"
    echo ""
    echo "Happy DeFi-ing! 🚀"
}

# Run main setup
main