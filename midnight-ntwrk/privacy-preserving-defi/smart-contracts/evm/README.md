# EVM Smart Contracts

Ethereum Virtual Machine compatible smart contracts for the privacy-preserving DeFi system.

## 📋 **Contracts Overview**

### **MockUSDC.sol**
Mock USDC token for testing and development.
- **Purpose**: Provide USDC-compatible token for testing
- **Features**: ERC20 implementation with minting for testing
- **Usage**: Testing deposit flows without real USDC

### **DeFiVault.sol**
Main vault contract for handling user deposits and ZK proof verification.
- **Purpose**: Securely manage user deposits with compliance checks
- **Features**:
  - Deposit with ZK proof verification
  - Concentration limit enforcement
  - TVL (Total Value Locked) tracking
  - Integration with compliance registry
- **Key Functions**:
  - `deposit(amount, proof)` - Deposit with ZK proof
  - `withdraw(amount, proof)` - Withdraw with ZK proof
  - `getBalance(user)` - Get user balance
  - `getTVL()` - Get total value locked

### **ComplianceRegistry.sol**
Registry for managing user compliance status.
- **Purpose**: Track which users are compliant for deposits
- **Features**:
  - Add/remove compliant users
  - Check user compliance status
  - Admin-only management functions
- **Key Functions**:
  - `isCompliant(user)` - Check if user is compliant
  - `addCompliantUser(user)` - Add compliant user (admin)
  - `removeCompliantUser(user)` - Remove compliant user (admin)

## 🔧 **Development Setup**

### **Prerequisites**
- Foundry installed (`curl -L https://foundry.paradigm.xyz | bash`)
- Node.js and npm for additional tooling

### **Installation**
```bash
cd smart-contracts/evm
forge install                      # Install dependencies
npm install                       # Install additional tooling
```

### **Build**
```bash
forge build                        # Build all contracts
forge build --contracts src/DeFiVault.sol  # Build specific contract
```

## 🧪 **Testing**

### **Run All Tests**
```bash
forge test -vv                     # Verbose output
forge test --gas-report            # Include gas usage
```

### **Run Specific Tests**
```bash
forge test --match-test testDeposit      # Deposit tests
forge test --match-test testCompliance  # Compliance tests
forge test --match-test testTVL         # TVL tests
```

### **Test Coverage**
```bash
forge coverage                      # Generate coverage report
forge coverage --report lcov          # LCOV format for CI
```

## 🚀 **Deployment**

### **Local Development (Anvil)**
```bash
# Start local node
anvil --port 8545

# Deploy contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# Verify deployment
cast call <DEFI_VAULT_ADDRESS> "getTVL()" --rpc-url http://localhost:8545
```

### **Testnet Deployment**
```bash
# Configure testnet RPC
export RPC_URL=https://testnet.rpc.url
export PRIVATE_KEY=your_private_key

# Deploy
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Save addresses
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --json > deployment.json
```

### **Mainnet Deployment**
```bash
# Configure mainnet RPC
export RPC_URL=https://mainnet.rpc.url
export PRIVATE_KEY=your_mainnet_private_key
export ETHERSCAN_API_KEY=your_api_key

# Deploy with verification
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

## 📁 **File Structure**

```
evm/
├── README.md              # This documentation
├── foundry.toml          # Foundry configuration
├── src/                  # Contract sources
│   ├── MockUSDC.sol      # Mock USDC token
│   ├── DeFiVault.sol     # Main vault contract
│   └── ComplianceRegistry.sol  # Compliance management
├── script/               # Deployment scripts
│   └── Deploy.s.sol      # Main deployment script
└── test/                # Contract tests
    ├── DeFiVault.t.sol   # Vault tests
    └── Counter.t.sol     # Example tests
```

## 🔍 **Contract Interaction Examples**

### **Deposit with ZK Proof**
```solidity
// In DeFiVault.sol
function deposit(
    uint256 amount,
    bytes calldata proof,
    bytes32[] calldata publicInputs
) external whenNotPaused nonReentrant {
    require(isCompliant(msg.sender), "User not compliant");
    require(verifyZKProof(proof, publicInputs), "Invalid ZK proof");
    
    userBalances[msg.sender] += amount;
    totalValueLocked += amount;
    
    emit Deposit(msg.sender, amount, proof);
}
```

### **Compliance Check**
```solidity
// In DeFiVault.sol
function isCompliant(address user) internal view returns (bool) {
    return complianceRegistry.isCompliant(user);
}
```

## 📊 **Gas Optimization**

### **Deployment Gas Costs**
- MockUSDC: ~2.5M gas
- DeFiVault: ~4.2M gas
- ComplianceRegistry: ~3.1M gas

### **Function Gas Costs**
- deposit(): ~85,000 gas
- withdraw(): ~92,000 gas
- getBalance(): ~5,000 gas (view)
- getTVL(): ~3,000 gas (view)

## 🔐 **Security Considerations**

### **Access Control**
- `onlyOwner` modifier for admin functions
- `whenNotPaused` modifier for operational controls
- Reentrancy protection with `nonReentrant`

### **Input Validation**
- ZK proof verification before state changes
- Amount limits and overflow checks
- Compliance status verification

### **Emergency Controls**
- Pause functionality for emergency stops
- Owner can withdraw funds in emergency
- Circuit breaker patterns for large operations

## 📈 **Monitoring**

### **Event Logging**
```solidity
event Deposit(
    address indexed user,
    uint256 amount,
    bytes proof
);
event Withdrawal(
    address indexed user,
    uint256 amount,
    bytes proof
);
event TVLUpdated(
    uint256 oldTVL,
    uint256 newTVL
);
```

### **Recommended Monitoring**
- Track deposit/withdrawal volumes
- Monitor TVL changes over time
- Alert on large transactions
- Watch for paused state changes

## 🔗 **Integration Points**

### **With Midnight Contracts**
- ZK proofs generated by Midnight Compact contracts
- Cross-chain references via transaction hashes
- TVL mirroring between chains

### **With TEE Service**
- Proof verification off-chain
- Confidential transaction processing
- Compliance checking integration

### **With Frontend**
- Web3 integration for contract interaction
- Event listening for real-time updates
- User wallet connection and signing