# Token Contract Circuits

This contract exports several zero-knowledge proof circuits that can be compiled and used for privacy-preserving operations.

## Exported Circuits

### 1. proveBalance
Proves that an account has at least a minimum balance without revealing the exact amount.

**Inputs:**
- `account`: Address to check
- `minAmount`: Minimum required balance
- `nonce`: Random value for commitment

**Output:** BalanceProof

**Usage:**
```bash
# Compile the circuit
compactc contracts/Token.compact --circuit proveBalance

# Generate proof
prove build/proveBalance.json
```

### 2. proveTransfer
Generates a zero-knowledge proof for a private transfer between accounts.

**Inputs:**
- `from`: Sender address
- `to`: Recipient address  
- `amount`: Transfer amount
- `fromNonce`: Sender's nonce
- `toNonce`: Recipient's nonce

**Output:** TransferProof with commitments and nullifier

**Usage:**
```bash
# Compile the circuit
compactc contracts/Token.compact --circuit proveTransfer

# Generate proof
prove build/proveTransfer.json
```

### 3. batchVerifyBalances
Verifies multiple account balances in a single proof using Merkle trees.

**Inputs:**
- `accounts`: Array of addresses
- `minAmounts`: Minimum balance for each account
- `merkleRoot`: Root of the balance tree
- `merkleProofs`: Proofs for each account

**Output:** BatchBalanceProof

### 4. proveSolvency
Proves that total assets exceed liabilities without revealing individual balances.

**Inputs:**
- `totalLiabilities`: Total amount owed
- `reserveProof`: Proof of reserves
- `nonce`: Random value

**Output:** SolvencyProof with solvency ratio

## Compiling Circuits

To compile all circuits:
```bash
make compile-circuits
```

Or compile individual circuits:
```bash
compactc contracts/Token.compact --circuit proveBalance --output build/
compactc contracts/Token.compact --circuit proveTransfer --output build/
compactc contracts/Token.compact --circuit batchVerifyBalances --output build/
compactc contracts/Token.compact --circuit proveSolvency --output build/
```

## Generating Proofs

After compilation, generate proofs using the proof service:

```bash
# Generate a balance proof
prove -o balance.proof build/proveBalance.json

# Generate a transfer proof  
prove -o transfer.proof build/proveTransfer.json

# Verify the generated proof
verify balance.proof
```

## Integration with DApp

The generated proofs can be submitted on-chain to execute private operations:

```javascript
// JavaScript example
const proof = await generateBalanceProof(account, minAmount);
await tokenContract.withdraw(amount, proof);
```

## Circuit Optimization

For production use, optimize circuits:
```bash
compactc contracts/Token.compact --optimize --circuit proveBalance
```

This reduces constraint count and proof generation time.
