# Sonic Agent Skills

## Overview

This agent specializes in Sonic blockchain development - a high-performance 
EVM-compatible L1 with 400,000 TPS and sub-second finality.

## Network Information

- **Mainnet**: Chain ID 146, RPC: https://rpc.soniclabs.com
- **Native Token**: S (Sonic)
- **Block Explorer**: https://sonicscan.org
- **Performance**: 400,000 TPS, sub-second finality
- **EVM Compatible**: Full Solidity/Vyper support

## Available Skills

### 1. solidity-gen

**ID**: `solidity-gen`
**Description**: Generate Solidity smart contracts for Sonic.
**Input**: Natural language description of the contract
**Output**: Solidity source code files

**Example Prompts**:
- "Create an ERC-20 token called SonicToken with symbol SNT"
- "Generate a simple NFT contract with minting function"
- "Build a staking contract that tracks user deposits"

**Best Practices for Solidity**:
- Use Solidity ^0.8.28
- Import OpenZeppelin contracts for standard implementations
- Use appropriate access control (Ownable, AccessControl)
- Include events for important state changes
- Add NatSpec documentation

### 2. compile

**ID**: `compile`
**Description**: Compile Solidity source code using Foundry Forge.
**Input**: Solidity source code
**Output**: ABI, bytecode, contract metadata

**Flow**:
1. Agent sends source code to evm-mcp
2. evm-mcp compiles with Forge
3. Returns ABI and bytecode

### 3. deploy

**ID**: `deploy`
**Description**: Deploy compiled contracts to Sonic.
**Input**: Contract bytecode, ABI, constructor arguments
**Output**: Contract address (dev mode) or unsigned transaction (mainnet)

**Modes**:
- **Dev mode** (default): Deploys to local Anvil fork with test accounts
- **Mainnet mode**: Returns unsigned transaction for user to sign

**Flow**:
1. Agent starts Anvil fork via chain_start (if not started)
2. Agent compiles contract (if needed)
3. Agent deploys via forge_deploy
4. Returns contract address or unsigned tx

### 4. call

**ID**: `call`
**Description**: Call a view/pure function on a deployed contract.
**Input**: Contract address, function signature, arguments
**Output**: Decoded return values

**Examples**:
- "Get the balance of 0x... from token contract 0x..."
- "What is the total supply of contract 0x..."
- "Call owner() on contract 0x..."

### 5. tx-status

**ID**: `tx-status`
**Description**: Check the status of a transaction.
**Input**: Transaction hash
**Output**: Transaction status, gas used, logs, contract address (if deployment)

**Examples**:
- "Check status of transaction 0x..."
- "What happened to tx 0x..."

### 6. feem-info

**ID**: `feem-info`
**Description**: Learn about Fee Monetization on Sonic.
**Input**: None
**Output**: FeeM documentation and guidance

> **Note**: FeeM integration is TODO. Currently returns informational content only.

## FeeM (Fee Monetization) - TODO

Sonic's unique developer incentive system:

| Feature | Description |
|---------|-------------|
| **Fee Share** | Developers earn **90%** of network fees their apps generate |
| **Validator Share** | 10% goes to validators |
| **Dashboard** | https://feem.soniclabs.com/ |

### FeeM Registration (TODO)
1. Deploy contract to Sonic mainnet
2. Register at https://feem.soniclabs.com/
3. Start earning fees automatically

## Wallet Configuration

The agent expects wallet context in the A2A message metadata:

```json
{
  "metadata": {
    "wallet": {
      "address": "0x...",
      "chainId": 146,
      "connected": true
    }
  }
}
```

**Important Security Notes**:
- Private keys are NEVER transmitted to the agent
- For mainnet deployments, the agent returns unsigned transactions
- User signs transactions in their own wallet
- Dev mode uses Anvil's pre-funded test accounts

## Example Conversation Flows

### Flow 1: Generate and Deploy Token

```
User: "Create an ERC-20 token called SonicCoin with symbol SNC and deploy it"

Agent:
1. Uses solidity-gen skill to generate ERC-20 contract
2. Returns contract source as artifact
3. Starts Anvil fork for Sonic (chain_start)
4. Compiles contract (forge_compile)
5. Deploys to local Anvil (forge_deploy)
6. Returns contract address
```

### Flow 2: Query Contract

```
User: "What is the total supply of contract 0x..."

Agent:
1. Uses call skill
2. Calls totalSupply() on the contract
3. Returns formatted result
```

## References

- [Sonic Docs](https://docs.soniclabs.com/)
- [FeeM Documentation](https://docs.soniclabs.com/funding/fee-monetization)
- [FeeM Dashboard](https://feem.soniclabs.com/)
- [SonicScan Explorer](https://sonicscan.org/)
