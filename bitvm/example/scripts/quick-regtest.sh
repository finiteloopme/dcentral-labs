#!/bin/bash

# Quick Bitcoin Regtest Demo for BitVM3
# Simplified version that handles common issues

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}BitVM3 Quick Regtest Demo${NC}"
echo "========================="

# Detect container runtime
if command -v podman &> /dev/null; then
    DOCKER="podman"
    CLI="podman exec -i $(podman ps -qf 'name=bitcoin' 2>/dev/null || echo 'none')"
else
    DOCKER="docker"
    CLI="docker exec -i $(docker ps -qf 'name=bitcoin' 2>/dev/null || echo 'none')"
fi

# Ensure Bitcoin is running
echo -e "${YELLOW}Starting Bitcoin regtest...${NC}"
$DOCKER run -d --rm --name bitvm3-bitcoin \
    -p 18443:18443 \
    docker.io/ruimarinho/bitcoin-core:latest \
    -regtest -server -rpcuser=bitvm3 -rpcpassword=password \
    -rpcallowip=0.0.0.0/0 -rpcbind=0.0.0.0 2>/dev/null || true

sleep 3

# Setup CLI  
CLI="$DOCKER exec -i bitvm3-bitcoin bitcoin-cli -regtest -rpcuser=bitvm3 -rpcpassword=password"

# Create wallet
echo -e "${YELLOW}Setting up wallet...${NC}"
$CLI createwallet "demo" 2>/dev/null || true

# Generate blocks
echo -e "${YELLOW}Mining blocks...${NC}"
ADDR=$($CLI getnewaddress)
$CLI generatetoaddress 101 $ADDR > /dev/null

# Create regtest vault address (simplified)
echo -e "${YELLOW}Creating vault...${NC}"
VAULT_ADDR="bcrt1qqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesrxh6hy"

# Fund vault
echo -e "${YELLOW}Funding vault...${NC}"
TXID=$($CLI sendtoaddress $VAULT_ADDR 0.1)
$CLI generatetoaddress 1 $ADDR > /dev/null

# Check balance
echo -e "${GREEN}✅ Demo Complete!${NC}"
echo ""
echo "Vault funded with 0.1 BTC"
echo "Transaction ID: $TXID"
echo "Block height: $($CLI getblockcount)"
echo ""
echo "To stop: $DOCKER stop bitvm3-bitcoin"