# BitVM3: Trustless Multi-Party Bitcoin Vault

A **trustless vault system for Bitcoin** that enables complex multi-party financial operations using BitVM's SNARK verification - no custodians or intermediaries required.

## 🎯 Core Innovation: Trustless Bitcoin Vaults

**The Problem**: Bitcoin's limited scripting prevents complex multi-party financial operations (lending, collateralized loans, liquidity provision) from running trustlessly on-chain.

**BitVM3 Solution**: Create trustless vaults where multiple parties can deposit BTC/stablecoins and execute complex operations verified by BitVM's 530KB Groth16 scripts - all without custodians.

**Key Trade-off**: ALL participants (operators, liquidators, borrowers) must be determined at vault creation time due to the pre-signed nature of Bitcoin transactions. This is less flexible than EVM smart contracts but still maintains trustless execution.

## 📊 Primary Use Case: Leveraged Yield Farming with BTC Collateral

The vault enables users to leverage BTC for DeFi yield:
1. **Deposit BTC** as collateral (up to 50% LTV)
2. **Borrow USDT** against BTC collateral at 5% APR
3. **Auto-deploy** borrowed funds to yield protocols (8-15% APY)
4. **Earn spread** between yield earned and borrow cost
5. **Liquidation** if BTC price drops below 150% collateralization

**Example Strategy**:
- Deposit 2 BTC ($100k) → Borrow $50k USDT
- Deploy to Aave/Compound at 8-9% APY
- Net profit: 3-4% APY on $50k = $1,500-2,000/year
- Keep BTC exposure while earning yield

**All verified trustlessly via BitVM's 530KB Groth16 scripts on Bitcoin.**

### Liquidation Mechanism & Limitations

**⚠️ Important BitVM Constraint**: Liquidators must be **pre-designated** during vault creation.

Unlike fully permissionless systems (Aave, Compound), BitVM requires:
1. **Fixed Liquidator Set**: Choose liquidators during initial setup
2. **Pre-signed Transactions**: Each liquidator gets a pre-signed Taproot path
3. **Cannot Add Later**: New liquidators cannot be added after vault creation

**How It Works**:
```
Vault Setup (Day 0):
├── Borrower deposits 2 BTC collateral
├── Select 3-5 trusted liquidators (e.g., protocol operators)
├── Pre-sign Taproot branches for each liquidator
└── Each branch: IF (health < 1.5 AND liquidator pays debt) THEN release BTC

During Operation:
├── Any pre-designated liquidator monitors positions
├── When health ratio < 1.5, they can execute their branch
├── Provide USDT, receive BTC + 5% bonus
└── Competition between designated liquidators keeps system healthy
```

**Practical Approach**:
- **Protocol Operators**: Run liquidation bots as a service
- **Professional Liquidators**: Well-known entities included at setup
- **DAO Members**: Governance token holders act as liquidators
- **Federated Model**: 5-10 reliable liquidators per vault

### Vault Operation Model

**Who Operates the Vault?**

Each BitVM vault has **fixed operators** determined at creation:

```
Typical Vault Structure:
├── Operators: 2-of-3 multisig
│   ├── Vault Creator (initiator)
│   ├── Protocol DAO (governance)
│   └── Oracle Service (price feeds)
├── Borrowers: Fixed list (1-10 users)
├── Lenders: Pool managed by operators
└── Liquidators: 3-5 pre-designated services
```

**Critical Constraints**:
- ❌ **Cannot add operators** after vault creation
- ❌ **Cannot modify multisig** threshold
- ❌ **Cannot add borrowers** to existing vault
- ❌ **Cannot change any participants**
- ❌ **Cannot add collateral** to existing positions
- ❌ **Cannot modify loan amounts** after creation

**Practical Implications**:

1. **Vault-per-Position Model**: 
   - Each loan might need its own vault
   - Or create vaults with 5-10 pre-approved borrowers
   - New users = new vault creation

2. **Operator Responsibilities**:
   - Execute pre-signed transactions
   - Manage oracle price updates
   - Cannot steal funds (BitVM enforces rules)
   - Cannot prevent valid liquidations

3. **Trust Assumptions**:
   - Trust that K-of-N operators stay online
   - Trust at least one liquidator will act
   - Don't trust them with funds (BitVM prevents theft)

**Comparison to DeFi**:
| Feature | Ethereum DeFi | BitVM Vaults |
|---------|--------------|--------------|
| Add new users | ✅ Anytime | ❌ Need new vault |
| Change operators | ✅ Via governance | ❌ Fixed forever |
| Permissionless entry | ✅ Anyone | ❌ Pre-approved only |
| Trustless execution | ✅ Smart contracts | ✅ BitVM verification |
| Capital efficiency | ✅ One pool for all | ❌ Fragmented vaults |

### Managing Collateral in BitVM Vaults

**Can borrowers add more BTC collateral?**
No, not to the same vault. Pre-signed transactions are immutable.

**Solutions for Additional Collateral**:

1. **Vault Composition** (Recommended):
   ```
   Original Vault (2 BTC) + Supplementary Vault (1 BTC) = 3 BTC total
   - Create new vault for additional collateral
   - Link vaults at protocol layer
   - Manage as unified position in UI
   ```

2. **Pre-signed Flexibility** (Complex):
   ```
   At creation, pre-sign multiple paths:
   - Path A: 2 BTC collateral, borrow up to 50k
   - Path B: 3 BTC collateral, borrow up to 75k  
   - Path C: 4 BTC collateral, borrow up to 100k
   User chooses path based on needs
   ```

3. **Close and Recreate** (Expensive):
   ```
   - Repay existing loan
   - Close current vault
   - Create new vault with total desired collateral
   - Costs: fees, time, potential loss of yield position
   ```

**Practical Impact**:
- Users must plan collateral needs upfront
- Adding collateral requires new vault creation
- Protocol UX must abstract vault composition complexity
- More on-chain transactions = higher costs

While more constrained than EVM DeFi, BitVM still enables sophisticated financial operations on Bitcoin without custodians.

## 🔑 How BitVM Enables Trustless Vaults

### Core Vault Capabilities
- **Multi-party deposits**: N participants can pool funds trustlessly
- **Complex operations**: Lending, borrowing, liquidity provision, derivatives
- **Non-custodial**: No intermediaries or trusted third parties
- **Bitcoin-native**: All verification happens on Bitcoin L1

### BitVM Technology Stack
```rust
// BitVM components powering the vault
use bitvm::groth16::{g16, hinted};  // SNARK verification
use bitvm::bn254::{fp254impl, fq};  // Elliptic curve operations
use bitvm::treepp::*;               // Script generation
```

### Proof Compression Magic
BitVM compresses any vault operation into Bitcoin-verifiable proofs:

| Vault Operation | Computation Size | BitVM Proof |
|-----------------|------------------|-------------|
| Multi-party withdrawal | ~50KB logic | 256 bytes |
| Collateral verification | ~100KB checks | 256 bytes |
| Interest calculation | ~20KB math | 256 bytes |
| Liquidity rebalancing | ~80KB state | 256 bytes |

**Result**: Bitcoin can verify ANY complex vault operation through BitVM's 530KB Groth16 scripts.

### Alternative: DV-SNARK Instead of Groth16

We could potentially use **Designated Verifier SNARKs** as an alternative proof system:

| Aspect | Groth16 (Current) | DV-SNARK (Alternative) |
|--------|-------------------|------------------------|
| **Script Size** | ~530KB | ~350KB (33% smaller) |
| **Proof Size** | 256 bytes | ~350 bytes |
| **Setup** | Requires trusted ceremony | No trusted setup |
| **Verifier** | Anyone (public) | Designated parties only |
| **Bitcoin Limits** | Near limit | More headroom |

**Benefits of DV-SNARK**:
- ✅ Smaller verification scripts (350KB vs 530KB)
- ✅ No trusted setup ceremony required
- ✅ Aligns with BitVM's designated operator model

**Limitations**:
- ❌ Still requires pre-signed transactions (core constraint remains)
- ❌ Cannot add participants or collateral (Bitcoin limitation)
- ❌ Adds designated verifier as potential failure point
- ❌ Slightly larger proofs to transmit

**Verdict**: DV-SNARK would provide modest improvements (smaller scripts) but wouldn't solve the fundamental limitations of BitVM vaults. The inability to modify vaults after creation is due to Bitcoin's pre-signed transaction model, not the proof system.





## 🚀 Quick Start

### Prerequisites
```bash
# Required: Node.js 18+, Rust 1.70+, Bitcoin Core 25+
make install  # Install all dependencies
make build    # Build TypeScript and Rust components
```

### Run Demos

```bash
# Primary demo - Leveraged Yield Farming
make demo-lending

# Other demos
make demo-real     # BitVM SNARK verification  
make demo-regtest  # Full Bitcoin integration
make demo-all      # Run all demos
```

### Demo Scenarios

The demos showcase different vault capabilities:

1. **Leveraged Yield** (`make demo-lending`) - Use BTC to farm DeFi yields
2. **BitVM Verification** (`make demo-real`) - 530KB script generation  
3. **Private Computation** (`make demo-garbled`) - Garbled circuits for privacy
4. **AMM Liquidity** (`make demo-amm`) - Cross-chain liquidity provision
5. **Bitcoin Integration** (`make demo-regtest`) - Real Bitcoin transactions



## 💻 Vault Architecture

```
    Multi-Party Deposits → BitVM3 Vault → Complex Operations
            ↓                    ↓                ↓
     Taproot Scripts      Garbled Circuits   Groth16 Proofs
            ↓                    ↓                ↓
         Bitcoin          Private Compute    BitVM Verification
```

### Core Components
- **Trustless Vault**: Multi-party Taproot addresses with pre-signed tx graphs
- **BitVM Groth16**: 530KB scripts verify any vault operation on Bitcoin
- **Garbled Circuits**: Private multi-party computation for sensitive data
- **Flexible Operations**: Supports lending, AMMs, derivatives, or custom logic





## 🚧 Realistic Vault Applications

Given BitVM's constraints (fixed participants), the most practical applications are:

### Works Well ✅
- **Private Lending Clubs**: 5-10 known members create shared vault
- **Institutional Vaults**: Fixed set of institutions as operators/users
- **DAO Treasury**: Pre-defined signers with spending rules
- **Bilateral Contracts**: Two-party agreements (options, swaps)

### Challenging ❌
- **Open Lending Pools**: Would need new vault per borrower
- **Permissionless AMMs**: Cannot add new LPs after creation
- **Dynamic Governance**: Cannot change operator set

### Practical Architecture
```
Instead of: One vault for all users (Aave model)
Use: Vault factory creating isolated vaults per user/group

Example Flow:
1. User requests loan via UI
2. Protocol creates new vault with:
   - User as borrower
   - Protocol operators (fixed set)
   - Professional liquidators (fixed set)
3. User deposits collateral to their vault
4. Operates independently with BitVM verification
```

This "vault-per-user" model is less capital efficient but maintains Bitcoin's security guarantees.

## 📦 Project Structure

```
vault-protocol/           # TypeScript client demos
verification-engine/      # Rust BitVM integration  
contracts/               # EVM smart contracts
```

## 🔗 Resources

- [BitVM GitHub](https://github.com/BitVM/BitVM)
- [BitVM Whitepaper](https://bitvm.org/bitvm.pdf)
- [Example Demos](./vault-protocol/src/)



