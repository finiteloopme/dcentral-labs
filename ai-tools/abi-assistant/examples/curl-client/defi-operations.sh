#!/usr/bin/env bash

# Common DeFi Operations using curl and the MCP Server
# This script demonstrates real-world DeFi use cases

SERVER="${MCP_SERVER:-http://127.0.0.1:3000}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     DeFi Operations via MCP Server - Examples        ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Helper function
run_intent() {
    local description="$1"
    local intent="$2"
    
    echo -e "${YELLOW}➤ $description${NC}"
    echo -e "  Intent: \"$intent\""
    
    result=$(curl -s -X POST "$SERVER" \
        -H "Content-Type: application/json" \
        -d "{
            \"jsonrpc\":\"2.0\",
            \"method\":\"tools/call\",
            \"params\":{
                \"name\":\"interpret_intent\",
                \"arguments\":{\"intent\":\"$intent\"}
            },
            \"id\":1
        }" | jq '.')
    
    echo -e "${GREEN}  Result:${NC}"
    echo "$result" | jq '.result' | sed 's/^/    /'
    echo ""
}

# 1. TOKEN SWAPS
echo -e "${BLUE}1. TOKEN SWAPS${NC}"
echo "────────────────────────────────────"

run_intent "Simple swap" \
    "swap 100 USDC for ETH"

run_intent "Swap with specific DEX" \
    "swap 1 ETH for USDC on Uniswap V3"

run_intent "Swap with slippage tolerance" \
    "swap 500 DAI for ETH with 0.5% slippage"

# 2. TOKEN TRANSFERS
echo -e "${BLUE}2. TOKEN TRANSFERS${NC}"
echo "────────────────────────────────────"

run_intent "Simple transfer" \
    "send 100 USDC to 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"

run_intent "Transfer all balance" \
    "transfer all my DAI to alice.eth"

# 3. APPROVALS
echo -e "${BLUE}3. TOKEN APPROVALS${NC}"
echo "────────────────────────────────────"

run_intent "Approve DEX" \
    "approve Uniswap to spend my USDC"

run_intent "Approve with amount" \
    "approve SushiSwap to spend 1000 DAI"

# 4. LIQUIDITY OPERATIONS
echo -e "${BLUE}4. LIQUIDITY OPERATIONS${NC}"
echo "────────────────────────────────────"

run_intent "Add liquidity" \
    "add liquidity to ETH/USDC pool with 1 ETH and 3000 USDC"

run_intent "Remove liquidity" \
    "remove 50% liquidity from ETH/DAI pool"

# 5. STAKING
echo -e "${BLUE}5. STAKING OPERATIONS${NC}"
echo "────────────────────────────────────"

run_intent "Stake tokens" \
    "stake 1000 SUSHI tokens"

run_intent "Unstake tokens" \
    "unstake all my staked ETH"

# 6. LENDING/BORROWING
echo -e "${BLUE}6. LENDING & BORROWING${NC}"
echo "────────────────────────────────────"

run_intent "Supply to lending protocol" \
    "supply 5000 USDC to Aave"

run_intent "Borrow against collateral" \
    "borrow 1000 DAI against my ETH collateral"

# 7. COMPLEX OPERATIONS
echo -e "${BLUE}7. COMPLEX DEFI STRATEGIES${NC}"
echo "────────────────────────────────────"

run_intent "Yield farming strategy" \
    "deposit USDC into highest yielding stable pool"

run_intent "Arbitrage opportunity" \
    "find arbitrage opportunity between Uniswap and SushiSwap for ETH/USDC"

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Examples complete!${NC}"
echo ""
echo "These examples demonstrate how natural language intents"
echo "are interpreted into specific DeFi protocol calls."
echo ""
echo "Server: $SERVER"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"