# Security Agent — Knowledge Base

Comprehensive security reference for smart contract auditing, vulnerability
scanning, and protocol risk assessment. This document serves as the LLM
system prompt context for all security analysis skills.

---

## 1. Solidity Vulnerability Taxonomy

### 1.1 Reentrancy

Reentrancy occurs when an external call allows the called contract to re-enter
the calling function before the first invocation completes.

#### 1.1.1 Single-Function Reentrancy

The classic reentrancy — the same function is re-entered.

**Vulnerable:**
```solidity
// VULNERABLE: state updated after external call
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
    balances[msg.sender] -= amount; // State update AFTER external call
}
```

**Fixed:**
```solidity
// FIXED: Checks-Effects-Interactions pattern
function withdraw(uint256 amount) external nonReentrant {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    balances[msg.sender] -= amount; // State update BEFORE external call
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

**Severity:** Critical
**CWE:** CWE-841 (Improper Enforcement of Behavioral Workflow)
**SWC:** SWC-107

#### 1.1.2 Cross-Function Reentrancy

Attacker re-enters a different function that shares state with the vulnerable one.

**Vulnerable:**
```solidity
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount);
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success);
    balances[msg.sender] -= amount;
}

// Attacker re-enters here during withdraw
function transfer(address to, uint256 amount) external {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    balances[to] += amount;
}
```

**Fixed:** Use `ReentrancyGuard` on ALL functions that modify shared state.

#### 1.1.3 Cross-Contract Reentrancy

Reentrancy across multiple contracts that share state or have trust relationships.

**Severity:** Critical
**Mitigation:** Use reentrancy guards at the protocol level, not just per-contract.

#### 1.1.4 Read-Only Reentrancy

Exploits view functions that return stale state during a reentrant call.
Common in protocols that use price oracles based on pool reserves.

**Vulnerable:**
```solidity
// Price oracle reads pool reserves
function getPrice() external view returns (uint256) {
    return reserve0 / reserve1; // Returns stale value during reentrancy
}
```

**Severity:** High
**Mitigation:** Use reentrancy locks on view functions or use TWAP oracles.

---

### 1.2 Integer Overflow / Underflow

Prior to Solidity 0.8.0, arithmetic operations could silently overflow or underflow.

**Vulnerable (Solidity < 0.8.0):**
```solidity
// VULNERABLE: uint256 wraps around on overflow
function transfer(address to, uint256 amount) external {
    balances[msg.sender] -= amount; // Underflows if amount > balance
    balances[to] += amount;         // Could overflow
}
```

**Fixed:**
```solidity
// Solidity >= 0.8.0 has built-in overflow checks
// For < 0.8.0, use SafeMath:
using SafeMath for uint256;

function transfer(address to, uint256 amount) external {
    balances[msg.sender] = balances[msg.sender].sub(amount);
    balances[to] = balances[to].add(amount);
}
```

**Severity:** High
**CWE:** CWE-190 (Integer Overflow), CWE-191 (Integer Underflow)
**SWC:** SWC-101

**Note:** Solidity 0.8+ has built-in overflow/underflow checks. However,
`unchecked {}` blocks bypass these checks and should be audited carefully.

---

### 1.3 Access Control Issues

#### 1.3.1 Missing Access Modifiers

Functions that should be restricted but are publicly callable.

**Vulnerable:**
```solidity
// VULNERABLE: anyone can call this
function setPrice(uint256 newPrice) external {
    price = newPrice;
}
```

**Fixed:**
```solidity
// FIXED: restricted to owner
function setPrice(uint256 newPrice) external onlyOwner {
    price = newPrice;
}
```

**Severity:** Critical
**SWC:** SWC-105

#### 1.3.2 tx.origin vs msg.sender

Using `tx.origin` for authorization is vulnerable to phishing attacks.

**Vulnerable:**
```solidity
// VULNERABLE: tx.origin can be manipulated via phishing
function transferOwnership(address newOwner) external {
    require(tx.origin == owner, "Not owner");
    owner = newOwner;
}
```

**Fixed:**
```solidity
// FIXED: use msg.sender
function transferOwnership(address newOwner) external {
    require(msg.sender == owner, "Not owner");
    owner = newOwner;
}
```

**Severity:** High
**SWC:** SWC-115

---

### 1.4 Delegatecall Risks

`delegatecall` executes code in the context of the calling contract, which can
lead to storage corruption or unauthorized state changes.

**Vulnerable:**
```solidity
// VULNERABLE: arbitrary delegatecall
function execute(address target, bytes calldata data) external {
    (bool success, ) = target.delegatecall(data);
    require(success);
}
```

**Fixed:**
```solidity
// FIXED: restrict target to known implementations
function execute(bytes calldata data) external onlyOwner {
    (bool success, ) = implementation.delegatecall(data);
    require(success);
}
```

**Severity:** Critical
**SWC:** SWC-112

---

### 1.5 Front-Running / MEV

Transactions in the mempool are visible to miners/validators who can reorder,
insert, or censor transactions for profit.

**Common patterns:**
- **Sandwich attacks**: Attacker places buy before and sell after a large swap
- **Liquidation front-running**: Bots race to liquidate undercollateralized positions
- **NFT sniping**: Bots front-run mint transactions

**Mitigations:**
- Commit-reveal schemes
- Flashbots / private mempools
- Slippage protection with reasonable bounds
- Batch auctions

**Severity:** Medium to High
**CWE:** CWE-362 (Race Condition)

---

### 1.6 Flash Loan Attacks

Flash loans allow borrowing large amounts without collateral within a single
transaction. Attackers use them to manipulate prices, governance, or exploit
vulnerable protocols.

**Attack pattern:**
1. Borrow large amount via flash loan
2. Manipulate price oracle (e.g., swap in a DEX pool)
3. Exploit protocol using manipulated price
4. Repay flash loan with profit

**Mitigations:**
- Use TWAP (Time-Weighted Average Price) oracles
- Use Chainlink or other decentralized oracles
- Add minimum time delays between price-sensitive operations
- Implement circuit breakers for large price movements

**Severity:** Critical
**CWE:** CWE-829 (Inclusion of Functionality from Untrusted Control Sphere)

---

### 1.7 Oracle Manipulation

Protocols that rely on on-chain price oracles (e.g., Uniswap spot price) are
vulnerable to manipulation via large trades or flash loans.

**Vulnerable:**
```solidity
// VULNERABLE: spot price from a single DEX
function getPrice() public view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    return uint256(reserve0) * 1e18 / uint256(reserve1);
}
```

**Fixed:**
```solidity
// FIXED: use Chainlink oracle with staleness check
function getPrice() public view returns (uint256) {
    (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
    require(price > 0, "Invalid price");
    require(block.timestamp - updatedAt < 3600, "Stale price");
    return uint256(price);
}
```

**Severity:** Critical

---

### 1.8 Gas Griefing

Attacker causes a function to consume excessive gas, potentially causing
denial of service or making transactions uneconomical.

**Vulnerable:**
```solidity
// VULNERABLE: unbounded loop over user-controlled array
function distributeRewards(address[] calldata recipients) external {
    for (uint256 i = 0; i < recipients.length; i++) {
        payable(recipients[i]).transfer(reward);
    }
}
```

**Fixed:**
```solidity
// FIXED: pull pattern instead of push
mapping(address => uint256) public pendingRewards;

function claimReward() external {
    uint256 reward = pendingRewards[msg.sender];
    require(reward > 0, "No reward");
    pendingRewards[msg.sender] = 0;
    payable(msg.sender).transfer(reward);
}
```

**Severity:** Medium
**SWC:** SWC-128

---

### 1.9 Denial of Service (DoS)

#### 1.9.1 DoS with Failed Call

**Vulnerable:**
```solidity
// VULNERABLE: single failed transfer blocks all withdrawals
function withdrawAll() external onlyOwner {
    for (uint256 i = 0; i < payees.length; i++) {
        payable(payees[i]).transfer(shares[payees[i]]);
    }
}
```

**Severity:** High
**SWC:** SWC-113

#### 1.9.2 DoS with Block Gas Limit

Unbounded operations that can exceed the block gas limit.

**Severity:** Medium
**SWC:** SWC-128

---

### 1.10 Timestamp Dependence

Using `block.timestamp` for critical logic can be manipulated by miners
(within ~15 second tolerance on Ethereum).

**Vulnerable:**
```solidity
// VULNERABLE: miner can manipulate timestamp
function isWinner() public view returns (bool) {
    return block.timestamp % 2 == 0;
}
```

**Severity:** Low to Medium
**SWC:** SWC-116

---

### 1.11 Unchecked External Calls

Failing to check the return value of low-level calls.

**Vulnerable:**
```solidity
// VULNERABLE: return value not checked
function sendEther(address to, uint256 amount) external {
    payable(to).send(amount); // Returns false on failure, doesn't revert
}
```

**Fixed:**
```solidity
// FIXED: check return value
function sendEther(address to, uint256 amount) external {
    (bool success, ) = payable(to).call{value: amount}("");
    require(success, "Transfer failed");
}
```

**Severity:** High
**SWC:** SWC-104

---

### 1.12 Storage Collision (Proxy Patterns)

In proxy patterns, storage layout mismatches between proxy and implementation
can corrupt state.

**Vulnerable:**
```solidity
// Proxy contract
contract Proxy {
    address public implementation; // Slot 0
    address public admin;         // Slot 1
}

// Implementation contract
contract Implementation {
    uint256 public value;  // Slot 0 — COLLIDES with implementation address!
    address public owner;  // Slot 1 — COLLIDES with admin!
}
```

**Fixed:** Use EIP-1967 storage slots or unstructured storage patterns.

**Severity:** Critical
**SWC:** SWC-124

---

### 1.13 Signature Replay

Reusing signed messages across transactions, chains, or contracts.

**Vulnerable:**
```solidity
// VULNERABLE: no nonce or chain ID check
function executeWithSig(address to, uint256 amount, bytes memory sig) external {
    bytes32 hash = keccak256(abi.encodePacked(to, amount));
    address signer = ECDSA.recover(hash, sig);
    require(signer == owner, "Invalid signature");
    _transfer(to, amount);
}
```

**Fixed:**
```solidity
// FIXED: include nonce, chain ID, and contract address
mapping(uint256 => bool) public usedNonces;

function executeWithSig(
    address to, uint256 amount, uint256 nonce, bytes memory sig
) external {
    require(!usedNonces[nonce], "Nonce already used");
    bytes32 hash = keccak256(abi.encodePacked(
        address(this), block.chainid, to, amount, nonce
    ));
    bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
    address signer = ECDSA.recover(ethHash, sig);
    require(signer == owner, "Invalid signature");
    usedNonces[nonce] = true;
    _transfer(to, amount);
}
```

**Severity:** High
**SWC:** SWC-121

---

### 1.14 Self-Destruct Abuse

`selfdestruct` can force-send ETH to a contract, bypassing its receive/fallback
functions. This can break invariants that depend on `address(this).balance`.

**Vulnerable:**
```solidity
// VULNERABLE: relies on contract balance for logic
function isGameOver() public view returns (bool) {
    return address(this).balance >= targetAmount;
}
```

**Severity:** Medium
**Note:** `selfdestruct` is deprecated in Solidity 0.8.24+ (EIP-6780).

---

## 2. Compact / Midnight Vulnerability Taxonomy

Compact is Midnight's smart contract language for ZK-proof-enabled contracts.
It has a fundamentally different security model from Solidity.

### 2.1 Witness Validation Failures

Witnesses are off-chain computations whose results are used in circuits.
Failing to validate witness outputs can compromise contract integrity.

**Vulnerable:**
```compact
pragma language_version >= 0.20;

// VULNERABLE: witness result used without validation
witness get_price(): Field {
    // Off-chain computation — could return anything
    return external_api_call();
}

export circuit set_price(): [] {
    const price = get_price();
    // No validation! Attacker controls the witness
    ledger.price = price;
}
```

**Fixed:**
```compact
pragma language_version >= 0.20;

// FIXED: validate witness output with assertions
witness get_price(): Field {
    return external_api_call();
}

export circuit set_price(): [] {
    const price = get_price();
    assert(price > 0n, "Price must be positive");
    assert(price < 1000000n, "Price exceeds maximum");
    ledger.price = price;
}
```

**Severity:** Critical

---

### 2.2 Disclosure Leaks

In Compact 0.20+, private data must be explicitly disclosed using `disclose()`.
Forgetting to disclose required data breaks the privacy model.

**Vulnerable:**
```compact
pragma language_version >= 0.20;

// VULNERABLE: private result not disclosed — verifier cannot check
export circuit get_balance(): Field {
    const balance = ledger.balances.lookup(msg.sender);
    return balance; // Not disclosed! Proof may be unsound
}
```

**Fixed:**
```compact
pragma language_version >= 0.20;

// FIXED: explicitly disclose the return value
export circuit get_balance(): Field {
    const balance = ledger.balances.lookup(msg.sender);
    return disclose(balance);
}
```

**Severity:** High

---

### 2.3 Proof Soundness Issues

ZK proofs must be sound — a valid proof should only exist for true statements.
Improper circuit design can create proofs for false statements.

**Key concerns:**
- Under-constrained circuits (missing assertions)
- Incorrect use of public vs private inputs
- Missing range checks on field elements

**Severity:** Critical

---

### 2.4 Private State Exposure Risks

Private state in Midnight is stored locally and encrypted. However, improper
handling can leak information through:
- Transaction patterns (timing, frequency)
- Public state correlations
- Witness computation side channels

**Severity:** Medium

---

### 2.5 Replay Attacks

Missing round counters or nonces in Compact contracts can allow transaction replay.

**Vulnerable:**
```compact
pragma language_version >= 0.20;

// VULNERABLE: no nonce — same transaction can be replayed
export circuit transfer(to: Address, amount: Field): [] {
    const balance = ledger.balances.lookup(msg.sender);
    assert(balance >= amount, "Insufficient balance");
    ledger.balances.insert(msg.sender, balance - amount);
    ledger.balances.insert(to, ledger.balances.lookup(to) + amount);
}
```

**Fixed:**
```compact
pragma language_version >= 0.20;

// FIXED: use a counter to prevent replay
export circuit transfer(to: Address, amount: Field, nonce: Field): [] {
    const currentNonce = ledger.nonces.lookup(msg.sender);
    assert(nonce == currentNonce + 1n, "Invalid nonce");
    ledger.nonces.insert(msg.sender, nonce);

    const balance = ledger.balances.lookup(msg.sender);
    assert(balance >= amount, "Insufficient balance");
    ledger.balances.insert(msg.sender, balance - amount);
    ledger.balances.insert(to, ledger.balances.lookup(to) + amount);
}
```

**Severity:** High

---

### 2.6 Improper Use of Sealed Fields

Sealed fields in Compact provide confidentiality but must be used correctly.
Mixing sealed and public operations can leak information.

**Severity:** Medium

---

### 2.7 Witness Naming Convention Violations

Midnight conventions require witnesses to follow specific naming patterns.
Violations can cause compilation issues or runtime errors.

**Convention:** Witness names should be descriptive and prefixed with the
operation they perform (e.g., `get_`, `compute_`, `validate_`).

**Severity:** Informational

---

### 2.8 Missing Assertions on Witness Outputs

Every witness output used in a circuit should have corresponding assertions
to constrain the possible values.

**Severity:** High

---

### 2.9 Improper Commitment Schemes

Commitment schemes in ZK contracts must be binding and hiding. Using weak
hash functions or missing randomness can break these properties.

**Severity:** Critical

---

## 3. Common DeFi Exploit Patterns

### 3.1 Price Manipulation (Oracle Attacks)

Manipulating price feeds to exploit lending, borrowing, or trading protocols.

**Attack vectors:**
- Flash loan + DEX swap to move spot price
- Multi-block manipulation of TWAP oracles
- Stale oracle data exploitation

**Notable incidents:**
- Mango Markets ($114M, Oct 2022)
- Cream Finance ($130M, Oct 2021)
- Harvest Finance ($34M, Oct 2020)

---

### 3.2 Governance Attacks

Exploiting governance mechanisms to pass malicious proposals.

**Attack vectors:**
- Flash loan governance tokens to pass proposals
- Bribe attacks on token holders
- Timelock bypass through emergency functions

---

### 3.3 Bridge Vulnerabilities

Cross-chain bridges are high-value targets due to large TVL and complex
multi-chain logic.

**Attack vectors:**
- Validator key compromise
- Message verification bypass
- Replay attacks across chains
- Deposit/withdrawal accounting errors

**Notable incidents:**
- Ronin Bridge ($625M, Mar 2022)
- Wormhole ($320M, Feb 2022)
- Nomad Bridge ($190M, Aug 2022)

---

### 3.4 Rug Pull Indicators

Signs that a project may be a rug pull:

**Code-level indicators:**
- Hidden mint functions (owner can mint unlimited tokens)
- Ownership concentration (single address holds >50% supply)
- Missing or removable liquidity locks
- Blacklist functions that can freeze user funds
- Modifiable tax/fee functions with no upper bound
- Proxy contracts with unrestricted upgrade capability

**Vulnerable:**
```solidity
// RUG PULL INDICATOR: hidden mint function
function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal override
{
    if (from == address(0) && to == owner()) {
        // Owner can mint unlimited tokens during transfers
        _mint(owner(), amount * 100);
    }
    super._beforeTokenTransfer(from, to, amount);
}
```

---

### 3.5 Infinite Mint Bugs

Vulnerabilities that allow minting tokens beyond the intended supply.

**Attack vectors:**
- Unchecked mint functions
- Integer overflow in supply tracking
- Reentrancy in mint functions

---

### 3.6 Flash Loan Attack Vectors

Detailed flash loan attack patterns:

1. **Price oracle manipulation**: Borrow → swap to move price → exploit → repay
2. **Governance manipulation**: Borrow governance tokens → vote → repay
3. **Liquidation manipulation**: Borrow → manipulate collateral price → liquidate → repay
4. **Arbitrage exploitation**: Borrow → exploit price discrepancy → repay

---

### 3.7 Sandwich Attacks

MEV bots detect pending swaps and place transactions before and after them.

**Attack flow:**
1. Detect large pending swap (buy token X)
2. Front-run: buy token X (price increases)
3. Victim's swap executes at higher price
4. Back-run: sell token X at inflated price

**Mitigation:** Use private mempools, set tight slippage, use DEX aggregators.

---

### 3.8 Liquidation Manipulation

Manipulating collateral prices to trigger or prevent liquidations.

**Attack vectors:**
- Flash loan to temporarily crash collateral price
- Front-running liquidation transactions
- Self-liquidation for profit

---

## 4. Severity Classification

Aligned with industry standards (OpenZeppelin, Trail of Bits, Consensys).

### Critical

**Definition:** Direct loss of funds or complete contract compromise.

**Examples:**
- Reentrancy allowing fund drainage
- Unrestricted mint/burn functions
- Proxy storage collision corrupting admin address
- Missing access control on privileged functions

**Action:** Must be fixed before deployment. Deployment should be blocked.

### High

**Definition:** Significant impact on contract functionality or user funds
at indirect risk.

**Examples:**
- Flash loan attack vectors
- Oracle manipulation possibilities
- Signature replay vulnerabilities
- Cross-function reentrancy

**Action:** Must be fixed before deployment. May require architecture changes.

### Medium

**Definition:** Moderate impact, requires specific conditions to exploit.

**Examples:**
- Timestamp dependence in time-sensitive logic
- Gas griefing possibilities
- Front-running opportunities
- Centralization risks (single admin key)

**Action:** Should be fixed. Acceptable with documented risk acceptance.

### Low

**Definition:** Minor issues, best practice violations.

**Examples:**
- Missing event emissions
- Inconsistent naming conventions
- Redundant code
- Missing NatSpec documentation

**Action:** Recommended to fix. Can be deferred.

### Informational

**Definition:** Code quality, gas optimization, style suggestions.

**Examples:**
- Gas optimization opportunities
- Code readability improvements
- Unused variables or imports
- Style guide violations

**Action:** Optional. Nice to have.

---

## 5. Protocol Risk Factors

### 5.1 TVL History and Trends

- Current TVL and historical trends
- TVL concentration (few large depositors vs many small ones)
- TVL relative to market cap
- Sudden TVL changes (potential manipulation or bank run)

### 5.2 Audit History

- Number of audits and auditor reputation
- Scope of audits (full protocol vs individual contracts)
- Severity of findings and remediation status
- Time since last audit vs code changes since
- Bug bounty program existence and size

**Reputable auditors:** Trail of Bits, OpenZeppelin, Consensys Diligence,
Certora, Spearbit, Code4rena, Sherlock, Cyfrin

### 5.3 Team Reputation

- Team doxxing status (fully doxxed, pseudonymous, anonymous)
- Track record of previous projects
- Investor backing and advisory board
- Community engagement and transparency

### 5.4 Upgrade Mechanisms

| Pattern | Risk Level | Description |
|---------|-----------|-------------|
| Immutable | Lowest | No upgrades possible |
| Transparent Proxy | Medium | Admin can upgrade implementation |
| UUPS | Medium | Implementation controls upgrades |
| Beacon | Medium-High | Single beacon controls multiple proxies |
| Diamond (EIP-2535) | High | Complex multi-facet upgradability |

**Key questions:**
- Who controls upgrades? (multisig, timelock, single EOA)
- Is there a timelock delay? (24h, 48h, 7d)
- Can upgrades be paused or vetoed?

### 5.5 Dependency Chains

- External contract calls (oracles, DEXes, lending protocols)
- Bridge dependencies for cross-chain operations
- Oracle provider reliability and decentralization
- Third-party library versions and known vulnerabilities

### 5.6 Chain Maturity Indicators

- Time since mainnet launch
- Number of validators/nodes
- Incident history (outages, reorgs, exploits)
- EVM compatibility level (if applicable)
- Consensus mechanism maturity

### 5.7 Governance Model

| Model | Centralization | Speed | Risk |
|-------|---------------|-------|------|
| Single EOA | Very High | Instant | Critical |
| Multisig (2/3) | High | Fast | High |
| Multisig (4/7) | Medium | Medium | Medium |
| Timelock + Multisig | Medium-Low | Slow | Medium-Low |
| DAO (token voting) | Low | Very Slow | Low-Medium |
| Immutable | None | N/A | Lowest |

---

## 6. Audit Report Output Format

### Finding Structure

Each finding in an audit report should include:

```
### [SEVERITY] F-XXX: Finding Title

**Description:**
Clear explanation of the vulnerability.

**Location:**
- File: `contracts/Token.sol`
- Function: `transfer()`
- Lines: 45-52

**Impact:**
What could happen if this vulnerability is exploited.

**Proof of Concept:**
Step-by-step attack scenario or code demonstrating the issue.

**Recommendation:**
Specific code changes to fix the vulnerability.

**References:**
- CWE-XXX: <title>
- SWC-XXX: <title>
- Related: <links to similar findings or documentation>
```

### Summary Table

```
| # | ID | Severity | Title | Status |
|---|-----|----------|-------|--------|
| 1 | F-001 | Critical | Reentrancy in withdraw() | Open |
| 2 | F-002 | High | Missing access control on setPrice() | Open |
| 3 | F-003 | Medium | Timestamp dependence in lottery | Open |
| 4 | F-004 | Low | Missing event emission | Open |
| 5 | F-005 | Info | Gas optimization in loop | Open |
```

### Risk Rating

| Severity | Count |
|----------|-------|
| Critical | X |
| High | X |
| Medium | X |
| Low | X |
| Informational | X |
| **Total** | **X** |

---

## 7. Supported Chains Reference

### 7.1 Somnia

- **Type:** EVM-compatible L1
- **Language:** Solidity
- **Consensus:** Multistream consensus
- **Performance:** 1M+ TPS claimed
- **Maturity:** Testnet (Shannon)
- **Chain ID:** 50312 (testnet)
- **Key risks:** New chain, limited battle-testing, small validator set

### 7.2 Sonic (formerly Fantom)

- **Type:** EVM-compatible L1
- **Language:** Solidity
- **Consensus:** Lachesis (aBFT)
- **Feature:** FeeM (Fee Monetization) — developers earn 90% of gas fees
- **Maturity:** Mainnet
- **Chain ID:** 146
- **Key risks:** Rebranding transition, bridge security, DeFi protocol risks

### 7.3 Midnight

- **Type:** Privacy-preserving blockchain with ZK proofs
- **Language:** Compact
- **Consensus:** Substrate-based
- **Feature:** Dual ledger (public + private), selective disclosure
- **Maturity:** Preview/Preprod testnets
- **Key risks:** New ZK paradigm, Compact language maturity, proof system complexity

---

## 8. Common SWC Registry Reference

| SWC ID | Title | Severity |
|--------|-------|----------|
| SWC-100 | Function Default Visibility | Medium |
| SWC-101 | Integer Overflow and Underflow | High |
| SWC-104 | Unchecked Call Return Value | High |
| SWC-105 | Unprotected Ether Withdrawal | Critical |
| SWC-106 | Unprotected SELFDESTRUCT | Critical |
| SWC-107 | Reentrancy | Critical |
| SWC-110 | Assert Violation | Medium |
| SWC-112 | Delegatecall to Untrusted Callee | Critical |
| SWC-113 | DoS with Failed Call | High |
| SWC-114 | Transaction Order Dependence | Medium |
| SWC-115 | Authorization through tx.origin | High |
| SWC-116 | Block values as a proxy for time | Low |
| SWC-120 | Weak Sources of Randomness | Medium |
| SWC-121 | Missing Protection against Signature Replay | High |
| SWC-124 | Write to Arbitrary Storage Location | Critical |
| SWC-128 | DoS With Block Gas Limit | Medium |
| SWC-131 | Presence of Unused Variables | Informational |
| SWC-136 | Unencrypted Private Data On-Chain | Medium |

---

## 9. Security Best Practices Checklist

### Solidity

- [ ] Use latest stable Solidity version (0.8.x+)
- [ ] Apply Checks-Effects-Interactions pattern
- [ ] Use ReentrancyGuard on state-changing functions
- [ ] Validate all external inputs
- [ ] Use SafeERC20 for token transfers
- [ ] Implement proper access control (OpenZeppelin AccessControl)
- [ ] Add emergency pause functionality
- [ ] Emit events for all state changes
- [ ] Use pull over push for payments
- [ ] Avoid unbounded loops
- [ ] Use timelocks for privileged operations
- [ ] Include comprehensive NatSpec documentation
- [ ] Test with 100% branch coverage
- [ ] Run static analysis (Slither, Mythril)
- [ ] Get independent security audit

### Compact (Midnight)

- [ ] Use latest `pragma language_version`
- [ ] Validate all witness outputs with assertions
- [ ] Use `disclose()` for all public return values
- [ ] Implement nonces/counters for replay protection
- [ ] Follow witness naming conventions
- [ ] Minimize public state exposure
- [ ] Use proper commitment schemes
- [ ] Test circuit constraints thoroughly
- [ ] Verify proof soundness
- [ ] Document privacy guarantees and limitations
