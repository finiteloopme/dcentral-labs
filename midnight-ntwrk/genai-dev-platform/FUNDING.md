# Wallet Creation and Funding Guide

This guide explains how to create and fund wallets on a local Midnight development chain.

> **Note:** This guide uses the `midnight-node-toolkit` Docker image directly. In the future, these operations will be available via `midnightctl wallet` commands. See **[WALLET-INTEGRATION-REQ.md](./WALLET-INTEGRATION-REQ.md)** for the planned CLI integration.

## Overview

When running a local Midnight chain with `CFG_PRESET=dev` (standalone mode), several wallets are **pre-funded at genesis**. You can use these immediately for development, or create new wallets and fund them from the genesis accounts.

## Prerequisites

- Access to a running Midnight node (e.g., via your Cloud Workstation)
- The `midnight-node-toolkit` Docker image

```bash
docker pull midnightntwrk/midnight-node-toolkit:latest-main
```

For version compatibility, match the toolkit version to your node version:
```bash
docker pull midnightntwrk/midnight-node-toolkit:0.18.0-rc.9
```

---

## Part 1: Pre-Funded Genesis Wallets

### Available Genesis Wallets

The following wallet seeds are pre-funded when running with `CFG_PRESET=dev`:

| Wallet | Seed (64-character hex) |
|--------|-------------------------|
| Genesis 1 | `0000000000000000000000000000000000000000000000000000000000000001` |
| Genesis 2 | `0000000000000000000000000000000000000000000000000000000000000002` |
| Genesis 3 | `0000000000000000000000000000000000000000000000000000000000000003` |
| Genesis 4 | `0000000000000000000000000000000000000000000000000000000000000004` |

These wallets contain significant token balances for development and testing.

### Check Wallet Balance

```bash
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-wallet \
    --seed 0000000000000000000000000000000000000000000000000000000000000001 \
    --src-url ws://localhost:9944
```

Example output:
```json
{
  "coins": { ... },
  "utxos": [
    {
      "id": "c230c54a...",
      "value": 500000000000000,
      "token_type": "0000000000000000000000000000000000000000000000000000000000000000"
    }
  ],
  "dust_utxos": [ ... ]
}
```

### Get Wallet Addresses

```bash
# Unshielded address
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-address \
    --network undeployed \
    --seed 0000000000000000000000000000000000000000000000000000000000000001

# Shielded address (for private transactions)
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-address \
    --network undeployed \
    --seed 0000000000000000000000000000000000000000000000000000000000000001 \
    --shielded

# Coin public key (for contract interactions)
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-address \
    --network undeployed \
    --seed 0000000000000000000000000000000000000000000000000000000000000001 \
    --coin-public
```

---

## Part 2: Creating a New Wallet

### Step 1: Generate a Wallet Seed

A Midnight wallet seed is a **32-byte hex string** (64 characters). Generate one with:

```bash
openssl rand -hex 32
```

Example output:
```
a1b2c3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890
```

**Important:** Store this seed securely. Anyone with the seed has full control of the wallet.

### Step 2: Get Your Wallet Addresses

```bash
SEED="your-64-character-hex-seed"

# Get unshielded address
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-address --network undeployed --seed $SEED

# Get shielded address
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-address --network undeployed --seed $SEED --shielded
```

---

## Part 3: Funding a Wallet

### Send Unshielded Tokens

Transfer tokens from a genesis wallet to your new wallet:

```bash
# Get destination address
DEST_ADDR=$(docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-address --network undeployed --seed $SEED)

# Send tokens from genesis wallet
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    generate-txs single-tx \
    --source-seed "0000000000000000000000000000000000000000000000000000000000000001" \
    --unshielded-amount 10000 \
    --destination-address "$DEST_ADDR" \
    -s ws://localhost:9944 \
    -d ws://localhost:9944
```

### Send Shielded Tokens

For private transactions, send to a shielded address:

```bash
# Get shielded destination address
DEST_SHIELDED=$(docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-address --network undeployed --seed $SEED --shielded)

# Send shielded tokens
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    generate-txs single-tx \
    --source-seed "0000000000000000000000000000000000000000000000000000000000000001" \
    --shielded-amount 1000 \
    --destination-address "$DEST_SHIELDED" \
    -s ws://localhost:9944 \
    -d ws://localhost:9944
```

### Verify the Transfer

```bash
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-wallet --seed $SEED --src-url ws://localhost:9944
```

---

## Part 4: DUST Tokens

DUST is the fee token on Midnight, generated based on NIGHT token holdings.

### Check DUST Balance

```bash
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    dust-balance \
    --seed $SEED \
    --src-url ws://localhost:9944
```

### Register for DUST Generation

To start generating DUST based on your NIGHT holdings:

```bash
# Get your DUST address
DUST_ADDR=$(docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-address --network undeployed --seed $SEED --dust)

# Register for DUST
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    generate-txs register-dust-address \
    --wallet-seed "$SEED" \
    --funding-seed "0000000000000000000000000000000000000000000000000000000000000001" \
    --destination-dust "$DUST_ADDR" \
    -s ws://localhost:9944 \
    -d ws://localhost:9944
```

---

## Quick Start Script

Here's a complete workflow to create and fund a new wallet:

```bash
#!/bin/bash
set -e

NODE_URL="${NODE_URL:-ws://localhost:9944}"
TOOLKIT_IMAGE="${TOOLKIT_IMAGE:-midnightntwrk/midnight-node-toolkit:latest-main}"

# Genesis wallet seed (pre-funded)
GENESIS_SEED="0000000000000000000000000000000000000000000000000000000000000001"

# Generate new wallet
echo "Generating new wallet seed..."
NEW_SEED=$(openssl rand -hex 32)
echo "Seed: $NEW_SEED"

# Get addresses
echo -e "\nGetting wallet addresses..."
UNSHIELDED_ADDR=$(docker run --network host $TOOLKIT_IMAGE \
    show-address --network undeployed --seed $NEW_SEED)
echo "Unshielded: $UNSHIELDED_ADDR"

SHIELDED_ADDR=$(docker run --network host $TOOLKIT_IMAGE \
    show-address --network undeployed --seed $NEW_SEED --shielded)
echo "Shielded: $SHIELDED_ADDR"

# Fund wallet
echo -e "\nFunding wallet with 10000 unshielded tokens..."
docker run --network host $TOOLKIT_IMAGE \
    generate-txs single-tx \
    --source-seed "$GENESIS_SEED" \
    --unshielded-amount 10000 \
    --destination-address "$UNSHIELDED_ADDR" \
    -s $NODE_URL \
    -d $NODE_URL

echo -e "\nWaiting for transaction to be included..."
sleep 6

# Verify
echo -e "\nVerifying wallet balance..."
docker run --network host $TOOLKIT_IMAGE \
    show-wallet --seed $NEW_SEED --src-url $NODE_URL

echo -e "\nWallet created and funded successfully!"
echo "Save your seed securely: $NEW_SEED"
```

---

## Connecting to GKE Services

If running from a Cloud Workstation with GKE services:

```bash
# The node URL is injected as an environment variable
echo $MIDNIGHT_NODE_URL

# Use it with toolkit commands
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main \
    show-wallet \
    --seed 0000000000000000000000000000000000000000000000000000000000000001 \
    --src-url $MIDNIGHT_NODE_URL
```

---

## Token Types

| Token | Description | Use Case |
|-------|-------------|----------|
| **Unshielded** | Public tokens visible on-chain | General transfers, public balances |
| **Shielded** | Private tokens using ZK proofs | Private transactions, confidential balances |
| **DUST** | Fee token generated from NIGHT | Transaction fees |
| **NIGHT** | Native token (on Cardano) | Governance, DUST generation |

---

## Troubleshooting

### "Connection refused" Error

Ensure the node is running and accessible:
```bash
curl -s http://localhost:9944/health
```

### "Empty UTXOs" Error

The wallet may not be funded yet. Use a genesis wallet or wait for a pending transaction.

### Toolkit Version Mismatch

Check version compatibility:
```bash
docker run --network host midnightntwrk/midnight-node-toolkit:latest-main version
```

Output should show compatible Node and Ledger versions.

---

## Additional Resources

- [Midnight Node Repository](https://github.com/midnightntwrk/midnight-node)
- [Midnight Toolkit Documentation](https://github.com/midnightntwrk/midnight-node/tree/main/util/toolkit)
- [Midnight Network Documentation](https://docs.midnight.network/)
