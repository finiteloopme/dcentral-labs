# Somnia Agent Skills

## Overview

This agent specializes in Somnia blockchain development - a high-performance 
EVM-compatible L1 with 1M+ TPS and sub-second finality.

## Network Information

- **Mainnet**: Chain ID 5031, RPC: https://api.infra.mainnet.somnia.network/
- **Testnet (Shannon)**: Chain ID 50312, RPC: https://dream-rpc.somnia.network/
- **Native Token**: SOMI (mainnet), STT (testnet)
- **Block Explorer**: https://explorer.somnia.network (mainnet), https://shannon-explorer.somnia.network (testnet)
- **Faucet**: https://testnet.somnia.network/

## Available Skills

### 1. solidity-gen

**ID**: `solidity-gen`
**Description**: Generate Solidity smart contracts optimized for Somnia's gas model.
**Input**: Natural language description of the contract
**Output**: Solidity source code files

**Somnia-Specific Optimizations**:
- Minimize LOG operations (higher cost: 8,320+ gas vs Ethereum's 631)
- Optimize storage access patterns (1M gas penalty for cold storage outside 128M key cache)
- Smaller contract bytecode (3,125 gas/byte deployment vs 200)
- Avoid expensive precompiles when possible (ecRecover: 150,000 gas)

**Example Prompts**:
- "Create an ERC-20 token called SomniaToken with symbol SMT"
- "Generate a simple NFT contract with minting function"
- "Build a staking contract that tracks user deposits"

**Best Practices for Somnia Solidity**:
- Use Solidity ^0.8.28
- Import OpenZeppelin contracts for standard implementations
- Minimize event emissions where possible
- Batch operations to reduce storage access overhead
- Consider using smaller data types (uint128 vs uint256) when appropriate

### 2. deploy

**ID**: `deploy`
**Description**: Deploy compiled contracts to Somnia testnet or mainnet.
**Input**: Contract bytecode/source, constructor arguments, network selection
**Output**: Unsigned transaction for user to sign, estimated gas

**Requirements**:
- Wallet must be connected via injected provider
- Sufficient STT (testnet) or SOMI (mainnet) for gas

**Flow**:
1. Agent compiles contract (if source provided)
2. Agent constructs deployment transaction
3. Agent returns unsigned transaction
4. User signs with their wallet
5. Transaction is broadcast

### 3. tx-status

**ID**: `tx-status`
**Description**: Check the status of a transaction on Somnia.
**Input**: Transaction hash, network selection
**Output**: Transaction status, block number, gas used, logs

**Example**:
- "Check status of transaction 0x123..."
- "What happened to my deployment tx 0xabc..."

### 4. query-state

**ID**: `query-state`
**Description**: Query on-chain state from Somnia contracts.
**Input**: Contract address, function signature or name, arguments, network selection
**Output**: Decoded return values

**Examples**:
- "Get the balance of address 0x... from token contract 0x..."
- "What is the total supply of contract 0x..."
- "Read the owner of NFT #5 from contract 0x..."

### 5. reactivity-setup

**ID**: `reactivity-setup`
**Description**: Generate code for Somnia's unique Reactivity system.
**Input**: Event subscription requirements
**Output**: Solidity code using Reactivity Precompile (0x0100) and/or TypeScript SDK code

**Somnia Reactivity Features**:
- On-chain event subscriptions via precompile at address `0x0100`
- Off-chain WebSocket subscriptions
- Push delivery from validators
- State consistency at event block height

**Reactivity Precompile Interface**:
```solidity
interface ISomniaReactivityPrecompile {
    struct SubscriptionData {
        bytes32[4] eventTopics;
        address origin;
        address caller;
        address emitter;
        address handlerContractAddress;
        bytes4 handlerFunctionSelector;
        uint64 priorityFeePerGas;
        uint64 maxFeePerGas;
        uint64 gasLimit;
        bool isGuaranteed;
        bool isCoalesced;
    }
    
    function subscribe(SubscriptionData calldata subscriptionData) external returns (uint64 subscriptionId);
    function unsubscribe(uint64 subscriptionId) external;
}
```

**Example Prompts**:
- "Set up a subscription to Transfer events from a token contract"
- "Create a reactive contract that responds to price updates"

### 6. data-streams

**ID**: `data-streams`
**Description**: Generate Data Streams schemas and TypeScript code.
**Input**: Data structure requirements
**Output**: Schema definition and @somnia-chain/streams SDK code

**Somnia Data Streams Features**:
- Structured data layer for EVM chains
- No Solidity required for data emission
- Schema-based typed data
- Publish/subscribe pattern

**Use Cases**:
- Real-time game state
- Chat messages
- GPS/telemetry data
- Player statistics
- Social feed updates

**Example**:
```typescript
import { createPublisher } from '@somnia-chain/streams';

const publisher = createPublisher({
  schema: {
    name: 'PlayerPosition',
    fields: [
      { name: 'playerId', type: 'uint256' },
      { name: 'x', type: 'int64' },
      { name: 'y', type: 'int64' },
      { name: 'timestamp', type: 'uint64' }
    ]
  }
});
```

## Wallet Configuration

The agent expects wallet context in the A2A message metadata:

```json
{
  "metadata": {
    "wallet": {
      "address": "0x...",
      "chainId": 50312,
      "connected": true
    },
    "network": "testnet"
  }
}
```

**Important Security Notes**:
- Private keys are NEVER transmitted to the agent
- The agent returns unsigned transactions
- User signs transactions in their own wallet
- Agent only receives the wallet address for read operations

## Gas Considerations

| Operation | Ethereum | Somnia | Optimization Strategy |
|-----------|----------|--------|----------------------|
| LOG0 (32 bytes) | 631 gas | 8,320 gas | Minimize events, batch logs |
| LOG4 (32 bytes) | 2,131 gas | 28,800 gas | Avoid indexed params when possible |
| Contract deploy | 200 gas/byte | 3,125 gas/byte | Optimize bytecode size |
| ecRecover | 3,000 gas | 150,000 gas | Batch signature verification |
| Cold storage | N/A | +1M gas | Access recently-used keys |
| New account | 25,000 gas | 400,000 gas | Minimize new account creation |

## Example Conversation Flows

### Flow 1: Generate and Deploy Token

```
User: "Create a simple ERC-20 token called GameCoin with symbol GMC and deploy to testnet"

Agent:
1. Uses solidity-gen skill to generate ERC-20 contract
2. Returns contract source as artifact
3. Compiles and prepares deployment transaction
4. Returns unsigned transaction for user to sign
5. After user signs and broadcasts, uses tx-status to confirm deployment
```

### Flow 2: Query Existing Contract

```
User: "What is the balance of 0xABC... in the USDC contract on Somnia mainnet?"

Agent:
1. Uses query-state skill
2. Calls balanceOf(0xABC...) on USDC contract (0x28BEc7E30E6faee657a03e19Bf1128AaD7632A00)
3. Returns formatted balance
```

### Flow 3: Set Up Event Monitoring

```
User: "I want my contract to automatically react when tokens are transferred to it"

Agent:
1. Uses reactivity-setup skill
2. Generates Solidity code using Reactivity Precompile
3. Explains how to integrate with existing contract
4. Provides TypeScript example for off-chain monitoring
```

## Key Contract Addresses (Mainnet)

| Contract | Address |
|----------|---------|
| MultiCallV3 | 0x5e44F178E8cF9B2F5409B6f18ce936aB817C5a11 |
| WSOMI | 0x046EDe9564A72571df6F5e44d0405360c0f4dCab |
| USDC | 0x28BEc7E30E6faee657a03e19Bf1128AaD7632A00 |
| WETH | 0x936Ab8C674bcb567CD5dEB85D8A216494704E9D8 |
| USDT | 0x67B302E35Aef5EEE8c32D934F5856869EF428330 |
| LayerZero EndpointV2 | 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B |

## Support

- Discord: https://discord.com/invite/somnia (#dev-chat channel)
- Email: developers@somnia.network
- Documentation: https://docs.somnia.network
