# Smart Contracts

This directory contains all smart contracts for the privacy-preserving DeFi system, organized by blockchain ecosystem.

## 📁 **Directory Structure**

```
smart-contracts/
├── README.md                 # This file
├── addresses.json            # Contract addresses for all networks
├── evm/                     # Ethereum Virtual Machine contracts
│   ├── README.md            # EVM contract documentation
│   ├── foundry.toml        # Foundry configuration
│   ├── src/                # Solidity contract sources
│   ├── script/              # Deployment scripts
│   └── test/               # Contract tests
└── midnight/                 # Midnight Compact contracts
    ├── README.md            # Midnight contract documentation
    ├── package.json         # NPM configuration for Compact
    ├── tsconfig.json        # TypeScript configuration
    ├── tsconfig.build.json  # Build TypeScript configuration
    ├── *.compact            # Compact contract sources
    └── witnesses.ts         # Witness definitions
```

## 🌐 **Supported Blockchains**

### **EVM (Ethereum Virtual Machine)**
- **Networks**: Ethereum, Polygon, Arbitrum, etc.
- **Language**: Solidity
- **Framework**: Foundry
- **Contracts**:
  - `MockUSDC.sol` - Mock USDC token for testing
  - `DeFiVault.sol` - Main vault contract for deposits
  - `ComplianceRegistry.sol` - User compliance management

### **Midnight**
- **Networks**: Midnight mainnet, testnet
- **Language**: Compact
- **Framework**: Midnight Compact Compiler
- **Contracts**:
  - `defi-vault.compact` - Privacy-preserving vault with ZK circuits
  - `defi-vault-simple.compact` - Simplified version for testing
  - `defi-vault-minimal.compact` - Minimal working contract

## 🔧 **Development Setup**

### **EVM Contracts**
```bash
cd smart-contracts/evm
forge build                    # Build contracts
forge test                     # Run tests
forge script script/Deploy.s.sol  # Deploy contracts
```

### **Midnight Contracts**
```bash
cd smart-contracts/midnight
npm install                    # Install dependencies
compact compile src/*.compact ./managed  # Compile contracts
npm run build                   # Build TypeScript outputs
```

## 🚀 **Deployment**

### **EVM Deployment**
```bash
# Local (Anvil)
forge script script/Deploy.s.sol --rpc-url http://localhost:8545

# Testnet
forge script script/Deploy.s.sol --rpc-url https://testnet.rpc.url

# Mainnet
forge script script/Deploy.s.sol --rpc-url https://mainnet.rpc.url
```

### **Midnight Deployment**
```bash
# Compile first
compact compile src/defi-vault.compact ./managed/defi-vault

# Deploy using Midnight CLI (when available)
midnight deploy ./managed/defi-vault
```

## 📋 **Contract Interactions**

### **EVM Contract Addresses**
See `addresses.json` for deployed contract addresses on each network.

### **Midnight Contract Circuits**
The Midnight contracts include these ZK circuits:
- `check_concentration_limit` - Verify user doesn't exceed concentration limits
- `update_balance` - Update user balance with ZK proof
- `update_tvl_mirror` - Mirror TVL from EVM chain

## 🔍 **Testing**

### **EVM Tests**
```bash
cd smart-contracts/evm
forge test -vv                 # Verbose test output
forge test --match-test testDeposit  # Run specific test
```

### **Midnight Tests**
```bash
cd smart-contracts/midnight
npm test                      # Run Compact contract tests
```

## 📚 **Documentation**

- **EVM Contracts**: See `smart-contracts/evm/README.md`
- **Midnight Contracts**: See `smart-contracts/midnight/README.md`
- **Integration**: See `midnight-integration/README.md`

## 🔗 **Related Services**

- **TEE Service**: `tee-service/` - ZK proof orchestration
- **Midnight Integration**: `midnight-integration/` - Proof generation service
- **Frontend**: `frontend/` - User interface
- **Development Scripts**: `scripts/` - Development and deployment tools