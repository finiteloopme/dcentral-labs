# Midnight SDK 3.x - Vendor Packages

This directory documents the Midnight SDK 3.x vendor packages built from source.

## Overview

The Midnight SDK 3.x packages are currently only available via a private GitHub npm registry. Until they are published to public npm, we build them from source as a separate container image.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Dockerfile.sdk (SDK build)                             │
│  ├── ledger-builder (Nix): midnight-ledger → WASM      │
│  ├── ts-builder (Node): midnight-wallet, midnight-js   │
│  └── Output: midnight-sdk:latest with /opt/vendor      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  Dockerfile (Main container)                            │
│  └── COPY --from=midnight-sdk /opt/vendor /opt/vendor  │
│  └── CLI uses file:/opt/vendor/... dependencies        │
└─────────────────────────────────────────────────────────┘
```

## Local Development Workflow

```bash
# 1. Build SDK image (one-time, ~30 min)
make build-sdk

# 2. Build main container (uses SDK image)
make build

# 3. Run container
make run
```

## Browsing SDK Source Locally

The source repos are git-ignored (builds clone fresh copies from GitHub). To browse locally:

```bash
# Clone wallet SDK at pinned version
git clone https://github.com/midnightntwrk/midnight-wallet.git vendor/midnight-wallet
cd vendor/midnight-wallet && git checkout 6bf9fe8

# Clone JS SDK at pinned version  
git clone --branch v3.0.0-alpha.11 https://github.com/midnightntwrk/midnight-js.git vendor/midnight-js
```

These directories are **not used by builds** - see `Dockerfile.sdk` for actual version pins.

## Pinned Versions

Versions are set in `Dockerfile.sdk`:

| Repository | ARG | Current Version |
|------------|-----|-----------------|
| [midnight-ledger](https://github.com/midnightntwrk/midnight-ledger) | `LEDGER_TAG` | `ledger-6.1.0-alpha.6` |
| [midnight-wallet](https://github.com/midnightntwrk/midnight-wallet) | `WALLET_COMMIT` | `6bf9fe8` |
| [midnight-js](https://github.com/midnightntwrk/midnight-js) | `JS_TAG` | `v3.0.0-alpha.11` |

## Version Compatibility Matrix

This table shows tested compatible versions between SDK, node, and services:

| SDK Stack | Node | Indexer | Proof Server | Network | Notes |
|-----------|------|---------|--------------|---------|-------|
| ledger-6.1.0-alpha.6 + wallet-6bf9fe8 | 0.18.0 | 3.0.0-alpha.20 | 6.1.0-alpha.6 | standalone | **Current** |
| ledger-6.1.0-alpha.6 + wallet-6bf9fe8 | 0.18.0 | 3.0.0-alpha.20 | 6.2.0-rc.2 | standalone | GKE deploy |

### Key Compatibility Notes

1. **SDK and Proof Server versions must match**: The ledger WASM version in SDK must match the proof server version (both use ledger-6.x)

2. **Indexer version affects GraphQL schema**: Ensure indexer version matches what SDK expects

3. **Node version determines chain protocol**: Genesis wallets are pre-funded in dev mode (CFG_PRESET=dev)

### HD Derivation Compatibility

Both SDK 3.x and midnight-node-toolkit use **identical BIP44 HD derivation paths**:

| Role | Derivation Path | SDK Role Constant |
|------|-----------------|-------------------|
| Unshielded External | `m/44'/2400'/0'/0/0` | `Roles.NightExternal` (0) |
| Unshielded Internal | `m/44'/2400'/0'/1/0` | `Roles.NightInternal` (1) |
| Dust | `m/44'/2400'/0'/2/0` | `Roles.Dust` (2) |
| Zswap (Shielded) | `m/44'/2400'/0'/3/0` | `Roles.Zswap` (3) |
| Metadata | `m/44'/2400'/0'/4/0` | `Roles.Metadata` (4) |

This means:
- **Genesis wallets work with SDK**: The pre-funded genesis wallets (seeds 0x...0001 to 0x...0004) are accessible via SDK
- **Addresses match**: SDK-derived addresses are identical to toolkit-derived addresses
- **No legacy mode needed**: There is no need for a "legacy derivation" option

## SDK Image Contents

The `midnight-sdk:latest` image contains:

```
/opt/vendor/
├── ledger/           # From midnight-ledger (Nix build)
│   ├── ledger-v6/    # @midnight-ntwrk/ledger
│   ├── onchain-runtime-v1/
│   ├── zkir-v2/
│   └── zkir-v3/
├── wallet/           # From midnight-wallet
│   ├── facade/       # @midnight-ntwrk/wallet-sdk-facade
│   ├── shielded-wallet/
│   ├── unshielded-wallet/
│   ├── indexer-client/
│   └── ...
├── js/               # From midnight-js
│   ├── contracts/    # @midnight-ntwrk/midnight-js-contracts
│   ├── types/
│   ├── network-id/
│   └── ...
├── compact-js/       # Compact runtime
│   └── compact-js/   # @midnight-ntwrk/compact-runtime
└── manifest.txt      # List of built packages
```

## Package Mappings

| Package Name | Container Path |
|--------------|----------------|
| `@midnight-ntwrk/ledger` | `/opt/vendor/ledger/ledger-v6` |
| `@midnight-ntwrk/onchain-runtime-v1` | `/opt/vendor/ledger/onchain-runtime-v1` |
| `@midnight-ntwrk/wallet-sdk-facade` | `/opt/vendor/wallet/facade` |
| `@midnight-ntwrk/wallet-sdk-shielded` | `/opt/vendor/wallet/shielded-wallet` |
| `@midnight-ntwrk/wallet-sdk-unshielded-wallet` | `/opt/vendor/wallet/unshielded-wallet` |
| `@midnight-ntwrk/midnight-js-contracts` | `/opt/vendor/js/contracts` |
| `@midnight-ntwrk/midnight-js-types` | `/opt/vendor/js/types` |
| `@midnight-ntwrk/midnight-js-network-id` | `/opt/vendor/js/network-id` |
| `@midnight-ntwrk/compact-runtime` | `/opt/vendor/compact-js/compact-js` |

## Upgrading SDK Versions

### Local

1. Edit version ARGs in `Dockerfile.sdk`
2. Rebuild: `make build-sdk`
3. Rebuild container: `make build`

### Cloud

1. Edit versions in `cicd-pipelines/cloudbuild-sdk.yaml`
2. Run SDK pipeline: `gcloud builds submit --config=cicd-pipelines/cloudbuild-sdk.yaml`
3. Run main deploy: `make deploy`

## When SDK 3.x is Published

Once the SDK is available on public npm:

1. Update `cli/package.json`:
   ```diff
   - "@midnight-ntwrk/ledger": "file:/opt/vendor/ledger/ledger-v6",
   + "@midnight-ntwrk/ledger": "^3.0.0",
   ```

2. Update `Dockerfile`:
   ```diff
   - ARG SDK_IMAGE=midnight-sdk:latest
   - FROM ${SDK_IMAGE} AS sdk
   - COPY --from=sdk /opt/vendor /opt/vendor
   ```

3. Delete SDK build files:
   - `Dockerfile.sdk`
   - `cicd-pipelines/cloudbuild-sdk.yaml`
   - `scripts/build-sdk.sh`

## Troubleshooting

### `make build` fails with "SDK image not found"
```bash
make build-sdk  # Build SDK image first
make build      # Then build main container
```

### SDK build fails during Nix step
- Ensure sufficient disk space (~10GB for Nix store)
- Check network access to GitHub and Nix cache
- First build takes ~30 minutes; subsequent builds use cache

### SDK build fails during yarn install
- The wallet/js packages require resolutions for local ledger packages
- Check the debug output for specific missing dependencies
- Some packages may fail if they have unlisted private dependencies

### Container can't find vendor packages
- Verify SDK image exists: `podman images | grep midnight-sdk`
- Check manifest: `podman run midnight-sdk:latest cat /opt/vendor/manifest.txt`

## SDK 3.x vs midnight-node-toolkit

The container includes both SDK 3.x packages and the `midnight-node-toolkit` binary. **SDK 3.x is now the primary method for all operations.** The toolkit is deprecated and available only via `--use-legacy-toolkit` flag.

### Feature Comparison

| Feature | SDK 3.x | Toolkit | Notes |
|---------|---------|---------|-------|
| **Wallet Creation** | ✅ `HDWallet.fromSeed()` | ✅ `show-address` | SDK uses HD derivation |
| **Shielded Address** | ✅ `shieldedWallet.address` | ✅ `show-address --shielded` | Both work |
| **Unshielded Address** | ✅ `unshieldedKeystore.getAddress()` | ✅ `show-address --unshielded` | Both work |
| **Dust Address** | ✅ `dustWallet.address` | ✅ `show-address --dust` | Both work |
| **Shielded Balance** | ✅ `facade.state()` | ✅ `show-wallet` | Both work |
| **Unshielded Balance** | ✅ `facade.state()` | ✅ `show-wallet` | Both work |
| **Dust Balance** | ✅ `facade.state()` | ✅ `show-wallet` | Both work |
| **Shielded Transfer** | ✅ `facade.transferTransaction()` | ❌ Not supported | **SDK only** |
| **Unshielded Transfer** | ✅ `wallet.sendUnshielded()` | ✅ `generate-txs single-tx` | Both work |
| **Dust Registration** | ✅ `wallet.registerForDustGeneration()` | ✅ `generate-txs register-dust-address` | Both work |
| **Contract Deployment** | ✅ Full provider support | ❌ Not supported | **SDK only** |
| **Private State** | ✅ `levelPrivateStateProvider` | ❌ Not supported | **SDK only** |
| **ZK Proofs** | ✅ `httpClientProofProvider` | ❌ Not supported | **SDK only** |
| **Swap Transactions** | ✅ `facade.initSwap()` | ❌ Not supported | **SDK only** |
| **No Sync Required** | ❌ Must sync first | ✅ Direct queries | Toolkit faster for quick checks |
| **Standalone Binary** | ❌ Requires Node.js | ✅ Single binary | Toolkit simpler to deploy |

### Key Differences

**SDK 3.x Advantages:**
- Full shielded transaction support (toolkit cannot do shielded transfers)
- Contract deployment and interaction
- HD wallet derivation (BIP-44 style)
- Programmatic control with TypeScript API and RxJS observables
- Atomic swap support between shielded/unshielded
- Unified API for both shielded and unshielded operations

**Toolkit Advantages:**
- No wallet sync required - queries are immediate
- Single binary, no Node.js runtime needed
- Faster for one-off balance checks and debugging

### Current Usage

The CLI now uses **SDK 3.x as primary** with deprecated toolkit fallback:

| CLI Command | Default (SDK 3.x) | `--use-legacy-toolkit` |
|-------------|-------------------|------------------------|
| `wallet balance` | ✅ Primary | ⚠️ Deprecated fallback |
| `wallet send` (shielded) | ✅ SDK only | N/A (not supported) |
| `wallet send` (unshielded) | ✅ Primary | ⚠️ Deprecated fallback |
| `wallet fund` | ✅ Primary | ⚠️ Deprecated fallback |
| `wallet register-dust` | ✅ Primary | ⚠️ Deprecated fallback |
| `wallet address --all` | ✅ Primary | ⚠️ Deprecated fallback |
| `contract deploy` | ✅ SDK only | N/A |

### Migration Status

**Phase 1:** ✅ COMPLETE - Keep both
- SDK 3.x used for: Shielded transfers, contract operations

**Phase 2:** ✅ COMPLETE - SDK primary
- [x] Update `balance.ts` to use SDK `wallet.getBalances()` with toolkit fallback
- [x] Update `fund.ts` to use SDK unshielded transfers
- [x] Update `register-dust.ts` to use SDK `registerForDustGeneration()`
- [x] Update `send.ts` to use SDK for both shielded and unshielded
- [x] Update `address.ts` to use SDK for address retrieval
- [x] Add `--use-legacy-toolkit` flag with deprecation warning
- [x] Add `--timeout` flag for SDK sync operations

**Phase 3:** PENDING - SDK only (when SDK 3.x is stable in production)
- [ ] Remove toolkit stage from `Dockerfile`
- [ ] Remove `cli/src/lib/midnight/toolkit.ts`
- [ ] Remove `--use-legacy-toolkit` flag from CLI commands
- [ ] Simplify error messages

### Toolkit Binary

The toolkit is included from:
```
docker.io/midnightntwrk/midnight-node-toolkit:0.18.0
```

**Container location:** `/usr/local/bin/midnight-node-toolkit`

**Environment variable:** `MIDNIGHT_TOOLKIT_PATH`

**Dockerfile reference:**
```dockerfile
FROM docker.io/midnightntwrk/midnight-node-toolkit:${MIDNIGHT_TOOLKIT_VERSION} AS toolkit
COPY --from=toolkit /midnight-node-toolkit ${MIDNIGHT_TOOLKIT_PATH}
```

Can be removed from `Dockerfile` once Phase 3 is complete.

### SDK 3.x Wallet Architecture

SDK 3.x uses a three-wallet architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                      WalletFacade                            │
│  Combines all three wallet types for coordinated operations │
├─────────────────┬─────────────────┬─────────────────────────┤
│ ShieldedWallet  │ UnshieldedWallet│ DustWallet              │
│ (Private txs)   │ (Public txs)    │ (Fee payments)          │
├─────────────────┼─────────────────┼─────────────────────────┤
│ ZswapSecretKeys │ Keystore        │ DustSecretKey           │
└─────────────────┴─────────────────┴─────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   HDWallet.fromSeed() │
              │   Derives all seeds   │
              │   from master seed    │
              └───────────────────────┘
```

**Key classes:**
- `HDWallet` - Derives seeds for each wallet type from a master seed
- `ShieldedWallet(config)` - Factory function returning wallet class
- `UnshieldedWallet(config)` - Factory function returning wallet class
- `DustWallet(config)` - Factory function returning wallet class
- `WalletFacade` - Combines all three for coordinated operations

**Seed input formats supported:**
- 24-word BIP-39 mnemonic
- 128-character hex string (64 bytes)
- 64-character hex string (32 bytes, expanded to 64)
