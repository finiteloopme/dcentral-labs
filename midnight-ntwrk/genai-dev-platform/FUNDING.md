# Wallet Creation and Funding Guide

This guide explains how to create and fund wallets on a local Midnight development chain.

## Midnight Token Model

| Token | Description | Transferable | Use Case |
|-------|-------------|--------------|----------|
| **NIGHT** | Native token on Midnight | Yes | Value transfer, DUST generation |
| **Shielded NIGHT** | Private NIGHT using ZK proofs | Yes | Private transactions, confidential balances |
| **Unshielded NIGHT** | Public NIGHT visible on-chain | Yes | General transfers, public balances |
| **DUST** | Fee resource (regenerates over time) | **No** | Transaction fees only |

> **Key Distinction:** NIGHT is the native token that can exist in shielded (private) or unshielded (public) form. DUST is a non-transferable resource used exclusively for transaction fees that regenerates based on NIGHT holdings.

---

## Using `midnightctl` CLI (Recommended)

The `midnightctl` CLI provides integrated wallet management with automatic address type detection.

### Create a Wallet

```bash
midnightctl wallet create my-wallet
```

This generates a BIP39 mnemonic and derives the wallet. **Store the mnemonic securely!**

### Check Balance

```bash
# Show shielded + unshielded NIGHT balances
midnightctl wallet balance my-wallet

# Include DUST resource status
midnightctl wallet balance my-wallet --include-dust
```

### Get Wallet Addresses

```bash
# Show basic addresses
midnightctl wallet address my-wallet

# Show all addresses including DUST
midnightctl wallet address my-wallet --all
```

### Fund from Genesis (Local Dev Only)

```bash
midnightctl wallet fund my-wallet 10000
```

### Send NIGHT Tokens

The CLI auto-detects address type and routes accordingly:

```bash
# Send to shielded address (private transfer via SDK)
midnightctl wallet send my-wallet mn_shield-addr_standalone1... 100

# Send to unshielded address (public transfer via toolkit)
midnightctl wallet send my-wallet mn_addr_standalone1... 100
```

### Register for DUST Generation

```bash
midnightctl wallet register-dust my-wallet
```

---

## Using `midnight-node-toolkit` Directly

For advanced operations or when the CLI is not available, use the toolkit binary directly.

### Prerequisites

```bash
# The toolkit is pre-installed at /usr/local/bin/midnight-node-toolkit
midnight-node-toolkit version

# Or pull the Docker image
docker pull midnightntwrk/midnight-node-toolkit:0.18.0
```

### Pre-Funded Genesis Wallets

When running with `CFG_PRESET=dev` (standalone mode), these wallets are pre-funded:

| Wallet | Seed (64-character hex) |
|--------|-------------------------|
| Genesis 1 | `0000000000000000000000000000000000000000000000000000000000000001` |
| Genesis 2 | `0000000000000000000000000000000000000000000000000000000000000002` |
| Genesis 3 | `0000000000000000000000000000000000000000000000000000000000000003` |
| Genesis 4 | `0000000000000000000000000000000000000000000000000000000000000004` |

### Check Wallet Balance

```bash
midnight-node-toolkit show-wallet \
    --seed 0000000000000000000000000000000000000000000000000000000000000001 \
    --src-url ws://localhost:9944
```

### Get Wallet Addresses

```bash
SEED="your-64-character-hex-seed"

# Unshielded address (for public NIGHT)
midnight-node-toolkit show-address --network undeployed --seed $SEED

# Shielded address (for private NIGHT)
midnight-node-toolkit show-address --network undeployed --seed $SEED --shielded

# DUST address (for DUST registration)
midnight-node-toolkit show-address --network undeployed --seed $SEED --dust
```

### Send Unshielded NIGHT

```bash
DEST_ADDR=$(midnight-node-toolkit show-address --network undeployed --seed $SEED)

midnight-node-toolkit generate-txs single-tx \
    --source-seed "0000000000000000000000000000000000000000000000000000000000000001" \
    --unshielded-amount 10000 \
    --destination-address "$DEST_ADDR" \
    -s ws://localhost:9944 \
    -d ws://localhost:9944
```

### Send Shielded NIGHT

```bash
DEST_SHIELDED=$(midnight-node-toolkit show-address --network undeployed --seed $SEED --shielded)

midnight-node-toolkit generate-txs single-tx \
    --source-seed "0000000000000000000000000000000000000000000000000000000000000001" \
    --shielded-amount 1000 \
    --destination-address "$DEST_SHIELDED" \
    -s ws://localhost:9944 \
    -d ws://localhost:9944
```

### Register for DUST Generation

```bash
DUST_ADDR=$(midnight-node-toolkit show-address --network undeployed --seed $SEED --dust)

midnight-node-toolkit generate-txs register-dust-address \
    --wallet-seed "$SEED" \
    --funding-seed "0000000000000000000000000000000000000000000000000000000000000001" \
    --destination-dust "$DUST_ADDR" \
    -s ws://localhost:9944 \
    -d ws://localhost:9944
```

### Check DUST Balance

```bash
midnight-node-toolkit dust-balance \
    --seed $SEED \
    --src-url ws://localhost:9944
```

---

## Quick Start Script

Create and fund a new wallet in one go:

```bash
#!/bin/bash
set -e

NODE_URL="${NODE_URL:-ws://localhost:9944}"
GENESIS_SEED="0000000000000000000000000000000000000000000000000000000000000001"

# Generate new wallet
echo "Generating new wallet seed..."
NEW_SEED=$(openssl rand -hex 32)
echo "Seed: $NEW_SEED"

# Get addresses
echo -e "\nGetting wallet addresses..."
UNSHIELDED_ADDR=$(midnight-node-toolkit show-address --network undeployed --seed $NEW_SEED)
echo "Unshielded: $UNSHIELDED_ADDR"

SHIELDED_ADDR=$(midnight-node-toolkit show-address --network undeployed --seed $NEW_SEED --shielded)
echo "Shielded: $SHIELDED_ADDR"

# Fund wallet
echo -e "\nFunding wallet with 10000 unshielded NIGHT..."
midnight-node-toolkit generate-txs single-tx \
    --source-seed "$GENESIS_SEED" \
    --unshielded-amount 10000 \
    --destination-address "$UNSHIELDED_ADDR" \
    -s $NODE_URL \
    -d $NODE_URL

echo -e "\nWaiting for transaction..."
sleep 6

# Verify
echo -e "\nVerifying wallet balance..."
midnight-node-toolkit show-wallet --seed $NEW_SEED --src-url $NODE_URL

echo -e "\nWallet created and funded!"
echo "Save your seed securely: $NEW_SEED"
```

---

## Troubleshooting

### "Connection refused" Error

Ensure the node is running:
```bash
curl -s http://localhost:9944/health
```

### "Empty UTXOs" Error

The wallet may not be funded. Use a genesis wallet or wait for pending transactions.

### Toolkit Not Found

If the toolkit binary is not available:
```bash
# Check installation path
ls -la /usr/local/bin/midnight-node-toolkit

# Or use Docker
docker run --network host midnightntwrk/midnight-node-toolkit:0.18.0 version
```

### Version Mismatch

Ensure toolkit matches node version:
```bash
midnight-node-toolkit version
# Should show: midnight-node-toolkit 0.18.x
```

---

## Additional Resources

- [Midnight Network Documentation](https://docs.midnight.network/)
- [NIGHT Token Info](https://midnight.network/night)
- [Midnight Node Repository](https://github.com/midnightntwrk/midnight-node)
