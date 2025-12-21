# Wallet Integration Requirements

**Document Version:** 2.2  
**Date:** 2025-12-21  
**Status:** SDK 3.x Primary Implementation Complete - HD Derivation Fixed  

## Overview

This document outlines the requirements for integrating wallet utilities from the [midnight-wallet](https://github.com/midnightntwrk/midnight-wallet) SDK into the `midnightctl` CLI tool. The goal is to provide developers with essential wallet and address management capabilities directly from the command line.

## Implementation Status

All core wallet commands are now implemented using **SDK 3.x as the primary method**. The legacy toolkit is available via `--use-toolkit` flag (deprecated).

**Key Fix (2025-12-21):** Removed broken `legacyDerivation` flag. SDK now uses same BIP44 HD derivation paths as toolkit (`m/44'/2400'/0'/<role>/0`), ensuring genesis wallet compatibility.

See **[WALLET-HOW-TO.md](./WALLET-HOW-TO.md)** for user documentation.

| Command | Status | Method | Notes |
|---------|--------|--------|-------|
| `wallet create` | ✅ Implemented | SDK 3.x | BIP39 mnemonic generation |
| `wallet balance` | ✅ Implemented | SDK 3.x primary | `--use-toolkit` fallback available |
| `wallet fund` | ✅ Implemented | SDK 3.x primary | `--use-toolkit` fallback available |
| `wallet send` | ✅ Implemented | SDK 3.x primary | Both shielded & unshielded |
| `wallet address` | ✅ Implemented | SDK 3.x primary | `--use-toolkit` fallback available |
| `wallet register-dust` | ✅ Implemented | SDK 3.x primary | `--use-toolkit` fallback available |
| `wallet generate` | ⚠️ Merged into `create` | | |
| `wallet validate` | ❌ Not implemented | | Mnemonic validation |
| `address validate` | ❌ Not implemented | | Address format validation |
| `address encode` | ❌ Not implemented | | |
| `address decode` | ❌ Not implemented | | |
| `tx send` | ⚠️ Via `wallet send` | | |
| `tx status` | ❌ Not implemented | | |

### New CLI Options (SDK 3.x)

All wallet commands now support:
- `--timeout <ms>` - Timeout for wallet sync (default: 60000ms for balance, 120000ms for fund/send)
- `--use-toolkit` - Use deprecated toolkit binary (shows warning)
- `--debug` - Show detailed debug information including service URLs

---

## Background

The Midnight Wallet SDK (`midnight-wallet`) is the official implementation of the [Midnight Wallet Specification](https://github.com/midnightntwrk/midnight-architecture/blob/main/components/WalletEngine/Specification.md). It provides:

- Key and address generation
- Address formatting (Bech32m)
- Transaction building and submission
- State synchronization with the indexer

Currently, our `midnightctl` CLI provides:
- Project scaffolding (`init`)
- Contract compilation (`compile`)
- Service management (`services`)
- Environment switching (`env`)

This integration will add wallet and address utilities to streamline the developer experience.

## Integration Approach

### Current Approach: SDK 3.x Direct Integration

We build SDK 3.x packages from source as a separate container image (`Dockerfile.sdk`) and use them directly in the CLI. This approach was adopted because:

1. **SDK packages are not yet on public npm** - requires building from source
2. **Full wallet functionality** - HD wallets, ZK proofs, transaction signing
3. **Three-wallet architecture** - ZswapWallet + UnshieldedWallet + DustWallet via WalletFacade

### Source Repositories

| Repository | Purpose | Version |
|------------|---------|---------|
| [midnight-wallet](https://github.com/midnightntwrk/midnight-wallet) | HD wallet, address format, wallet types | `6bf9fe8` |
| [midnight-js](https://github.com/midnightntwrk/midnight-js) | Providers, indexer, pub-sub | `v3.0.0-alpha.11` |
| [midnight-ledger](https://github.com/midnightntwrk/midnight-ledger) | WASM packages for ZK proofs | `ledger-6.1.0-alpha.6` |

### Key Implementation Files

- `cli/src/lib/midnight/providers.ts` - Wallet creation and provider setup
- `cli/src/lib/midnight/seed.ts` - Seed parsing (mnemonic/hex)
- `cli/src/commands/wallet/*.ts` - Wallet CLI commands

See [vendor/README.md](./vendor/README.md) for SDK architecture details.

---

## Functional Requirements

### FR-1: Mnemonic Generation

**Command:** `midnightctl wallet generate`

**Description:** Generate a new BIP39-compliant mnemonic phrase for wallet creation.

**Requirements:**
- FR-1.1: Generate a 24-word mnemonic phrase (256-bit entropy) by default
- FR-1.2: Support optional `--words` flag for 12-word mnemonic (128-bit entropy)
- FR-1.3: Display the mnemonic with clear formatting and security warnings
- FR-1.4: Optionally output as JSON with `--json` flag
- FR-1.5: Display derived wallet addresses (shielded, unshielded) for the default network

**Example:**
```bash
$ midnightctl wallet generate

Wallet Mnemonic (24 words)
==========================

  1. abandon    2. ability    3. able       4. about
  5. above      6. absent     7. absorb     8. abstract
  ...

WARNING: Store this mnemonic securely. Anyone with access to these
words can control your wallet. Never share it with anyone.

Derived Addresses (standalone):
  Unshielded: mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
  Shielded:   mn_shield-addr_standalone1qpzry9x8gf2tvdw0s3jn54k...
```

---

### FR-2: Mnemonic Validation

**Command:** `midnightctl wallet validate [mnemonic]`

**Description:** Validate a BIP39 mnemonic phrase.

**Requirements:**
- FR-2.1: Accept mnemonic as argument or prompt interactively
- FR-2.2: Validate word count (12, 15, 18, 21, or 24 words)
- FR-2.3: Validate each word exists in BIP39 English wordlist
- FR-2.4: Validate checksum
- FR-2.5: Display validation result with clear pass/fail indication
- FR-2.6: On success, optionally show derived addresses with `--show-addresses` flag

**Example:**
```bash
$ midnightctl wallet validate "abandon ability able about above absent..."

Mnemonic Validation
===================
  Word Count:  24 words
  Wordlist:    Valid (English)
  Checksum:    Valid

Result: VALID

$ midnightctl wallet validate "invalid words here"

Mnemonic Validation
===================
  Error: Word "invalid" is not in the BIP39 wordlist

Result: INVALID
```

---

### FR-3: Address Validation

**Command:** `midnightctl address validate <address>`

**Description:** Validate a Midnight address format.

**Requirements:**
- FR-3.1: Parse Bech32m-encoded Midnight addresses
- FR-3.2: Validate the prefix (`mn_`)
- FR-3.3: Identify address type (unshielded, shielded, dust)
- FR-3.4: Identify network (mainnet, testnet, standalone, etc.)
- FR-3.5: Display parsed address components

**Example:**
```bash
$ midnightctl address validate mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...

Address Validation
==================
  Format:   Valid Bech32m
  Type:     Unshielded Address
  Network:  standalone
  Data:     0x1234abcd...

Result: VALID

$ midnightctl address validate mn_shield-addr1qpzry9x8gf2tvdw0s3jn54khce6mua7l...

Address Validation
==================
  Format:   Valid Bech32m
  Type:     Shielded Address
  Network:  mainnet
  Components:
    Coin Public Key:       0xabcd1234...
    Encryption Public Key: 0x5678efgh...

Result: VALID
```

---

### FR-4: Address Encoding

**Command:** `midnightctl address encode <type> <hex-data>`

**Description:** Encode raw hex data into a Bech32m Midnight address.

**Requirements:**
- FR-4.1: Support address types: `unshielded`, `shielded`, `dust`
- FR-4.2: Accept hex-encoded public key data
- FR-4.3: Use current chain environment for network prefix (or `--network` flag)
- FR-4.4: Output the Bech32m-encoded address

**Example:**
```bash
$ midnightctl address encode unshielded 0x1234abcd5678efgh...

Encoded Address
===============
  Type:    Unshielded
  Network: standalone
  Address: mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
```

---

### FR-5: Address Decoding

**Command:** `midnightctl address decode <bech32-address>`

**Description:** Decode a Bech32m Midnight address to its components.

**Requirements:**
- FR-5.1: Parse valid Bech32m address
- FR-5.2: Extract and display address type
- FR-5.3: Extract and display network
- FR-5.4: Display raw hex data
- FR-5.5: For shielded addresses, show both public keys

**Example:**
```bash
$ midnightctl address decode mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...

Decoded Address
===============
  Type:    Unshielded Address (addr)
  Network: standalone
  Data:    1234abcd5678efgh9012ijkl3456mnop...
```

---

### FR-6: Network ID Alignment

**Description:** Align our chain environments with official Midnight NetworkIds.

**Requirements:**
- FR-6.1: Update `CHAIN_ENVIRONMENTS` to use official NetworkId values
- FR-6.2: Support additional networks: `devnet`, `qanet`, `preview`, `preprod`
- FR-6.3: Use `undeployed` for local development without deployed contracts
- FR-6.4: Ensure address encoding uses correct network prefix

**Official NetworkIds (from wallet SDK):**
```typescript
const NetworkId = {
  MainNet: 'mainnet',
  TestNet: 'testnet',
  DevNet: 'devnet',
  QaNet: 'qanet',
  Undeployed: 'undeployed',
  Preview: 'preview',
  PreProd: 'preprod',
} as const;
```

---

## Non-Functional Requirements

### NFR-1: Security

- NFR-1.1: Never log or persist mnemonic phrases
- NFR-1.2: Clear sensitive data from memory after use
- NFR-1.3: Display security warnings when showing mnemonics
- NFR-1.4: Validate all cryptographic inputs before processing

### NFR-2: Performance

- NFR-2.1: Commands should complete in < 500ms for typical operations
- NFR-2.2: Mnemonic generation should use cryptographically secure random number generation

### NFR-3: Usability

- NFR-3.1: Provide clear error messages with suggested fixes
- NFR-3.2: Support `--json` output for scripting/automation
- NFR-3.3: Include examples in `--help` output
- NFR-3.4: Use consistent formatting across all commands

### NFR-4: Maintainability

- NFR-4.1: Preserve Apache 2.0 license headers in copied source files
- NFR-4.2: Document the source commit/version of copied code
- NFR-4.3: Minimize copied code to reduce maintenance burden
- NFR-4.4: Use public npm packages for cryptographic operations

### NFR-5: Compatibility

- NFR-5.1: Compatible with Node.js 18+
- NFR-5.2: Address formats must be compatible with official Midnight tools
- NFR-5.3: Mnemonics must be BIP39-compliant and usable with official wallet

---

## Technical Design

### HD Key Derivation (BIP44)

Both SDK and toolkit use identical BIP44 derivation paths with Midnight's registered coin type `2400`:

| Role | Derivation Path | SDK Constant | Purpose |
|------|-----------------|--------------|---------|
| Unshielded External | `m/44'/2400'/0'/0/0` | `Roles.NightExternal` (0) | Public transactions |
| Unshielded Internal | `m/44'/2400'/0'/1/0` | `Roles.NightInternal` (1) | Change addresses |
| Dust | `m/44'/2400'/0'/2/0` | `Roles.Dust` (2) | Fee payments |
| Zswap (Shielded) | `m/44'/2400'/0'/3/0` | `Roles.Zswap` (3) | Private transactions |
| Metadata | `m/44'/2400'/0'/4/0` | `Roles.Metadata` (4) | Metadata storage |

This ensures:
- **Genesis wallets work correctly**: Pre-funded wallets (seeds 0x01-0x04) are accessible via SDK
- **Addresses match**: SDK-derived addresses are identical to toolkit-derived addresses
- **No legacy mode needed**: The `legacyDerivation` flag was removed as it incorrectly skipped HD derivation

### SDK 3.x Dependencies (Actual Implementation)

The CLI uses SDK 3.x packages built from source via `Dockerfile.sdk`:

```json
{
  "dependencies": {
    "@midnight-ntwrk/wallet-hd": "file:/opt/vendor/wallet/hd",
    "@midnight-ntwrk/dust-wallet": "file:/opt/vendor/wallet/dust-wallet",
    "@midnight-ntwrk/wallet-utilities": "file:/opt/vendor/wallet/utilities",
    "@midnight-ntwrk/wallet-capabilities": "file:/opt/vendor/wallet/capabilities",
    "@midnight-ntwrk/midnight-js-providers": "file:/opt/vendor/midnight-js/providers",
    "@midnight-ntwrk/midnight-js-indexer": "file:/opt/vendor/midnight-js/indexer",
    "@midnight-ntwrk/midnight-js-wallet-providers": "file:/opt/vendor/midnight-js/wallet-providers"
  }
}
```

### Actual File Structure

```
cli/
  src/
    commands/
      wallet/
        index.ts           # Command group
        create.ts          # Wallet creation with mnemonic
        balance.ts         # Balance display
        fund.ts            # Genesis funding
        send.ts            # Token transfers
        address.ts         # Address display
        register-dust.ts   # DUST registration
      contract/
        deploy.ts          # Contract deployment (uses wallet)
    lib/
      midnight/
        providers.ts       # Wallet + provider creation (SDK 3.x)
        seed.ts            # Seed parsing (mnemonic/hex)
    index.ts
```

### Core API (providers.ts)

```typescript
// Seed parsing
export type ParsedSeed = { type: 'mnemonic' | 'hex'; value: string };
export function parseSeed(input: string): ParsedSeed;

// Wallet creation (SDK 3.x architecture)
export interface WalletConfig {
  networkId: string;
  indexer: string;
  indexerWs: string;
  node: string;
  proofServer: string;
}

export interface WalletBundle {
  wallet: WalletFacade;          // Unified interface
  zswapWallet: ZswapWallet;      // Shielded operations
  unshieldedWallet: UnshieldedWallet;
  dustWallet: DustWallet;
  providers: MidnightProviders;
}

export async function createWallet(seed: string, config: WalletConfig): Promise<WalletBundle>;

// Balance retrieval
export interface Balances {
  shielded: bigint;
  unshielded: bigint;
  dust: bigint;
  total: bigint;
}

export async function getBalances(wallet: WalletBundle): Promise<Balances>;
```

### NetworkId (from SDK)

```typescript
// SDK 3.x uses string-based NetworkId
const NetworkId = {
  MainNet: 'mainnet',
  TestNet: 'testnet',
  DevNet: 'devnet',
  Standalone: 'standalone',  // Maps to 'undeployed' internally
} as const;
```

---

## Implementation Plan

### Phase 1: Foundation ✅ COMPLETE

1. ~~Add npm dependencies~~ → Using SDK 3.x packages directly
2. ~~Create `lib/midnight/` directory structure~~ → Done
3. ~~Copy and adapt utilities~~ → Using SDK packages instead
4. ~~Add `NetworkId` definitions~~ → Using SDK NetworkId

**Deliverables:**
- `cli/src/lib/midnight/providers.ts` ✅
- `cli/src/lib/midnight/seed.ts` ✅
- Updated `cli/package.json` with SDK dependencies ✅

### Phase 2: Wallet Commands ✅ COMPLETE

1. ~~Implement `midnightctl wallet generate`~~ → Merged into `wallet create`
2. `midnightctl wallet validate` → ❌ Not implemented (low priority)
3. ~~Add command to main CLI~~ → Done

**Deliverables:**
- `commands/wallet/index.ts` ✅
- `commands/wallet/create.ts` ✅
- `commands/wallet/balance.ts` ✅
- `commands/wallet/send.ts` ✅

### Phase 3: Address Commands ⚠️ PARTIAL

1. `midnightctl address validate` → ❌ Not implemented
2. `midnightctl address encode` → ❌ Not implemented
3. `midnightctl address decode` → ❌ Not implemented
4. `midnightctl wallet address` → ✅ Implemented (shows all address types)

**Remaining Work:**
- Standalone address validation/encoding commands (low priority - `wallet address` covers most use cases)

### Phase 4: Integration & Polish ⚠️ PARTIAL

1. ~~Update `env` command to use official NetworkIds~~ → Using SDK NetworkId
2. `--json` output support → ❌ Not implemented
3. ~~Update help text and examples~~ → Done
4. Integration testing → ⚠️ Basic tests only

**Remaining Work:**
- Add `--json` flag to wallet commands
- Comprehensive integration test suite

### Phase 5: Runtime Wallet Operations ✅ COMPLETE

1. ~~Implement `midnightctl wallet balance`~~ ✅ SDK 3.x primary
2. ~~Implement `midnightctl wallet fund`~~ ✅ SDK 3.x primary
3. ~~Implement `midnightctl wallet register-dust`~~ ✅ SDK 3.x primary
4. ~~Implement `midnightctl wallet address`~~ ✅ SDK 3.x primary
5. ~~Implement `midnightctl wallet send`~~ ✅ SDK 3.x (both shielded & unshielded)
6. `midnightctl tx status` → ❌ Not implemented

**Deliverables:**
- `commands/wallet/balance.ts` ✅ SDK primary with `--use-legacy-toolkit` fallback
- `commands/wallet/fund.ts` ✅ SDK primary with `--use-legacy-toolkit` fallback
- `commands/wallet/register-dust.ts` ✅ SDK primary with `--use-legacy-toolkit` fallback
- `commands/wallet/address.ts` ✅ SDK primary with `--use-legacy-toolkit` fallback
- `commands/wallet/send.ts` ✅ SDK for both shielded and unshielded transfers
- `lib/midnight/providers.ts` ✅ Added `sendUnshielded()` and `registerForDustGeneration()`
- `lib/midnight/toolkit.ts` ✅ Marked as deprecated, added `clearSyncCache()`
- `utils/logger.ts` ✅ Added `showLegacyToolkitWarning()`, `showSyncProgress()`

---

## Testing Requirements

### Unit Tests

- Mnemonic generation produces valid 12/24 word phrases
- Mnemonic validation correctly identifies valid/invalid phrases
- Address parsing handles all address types
- Address encoding produces valid Bech32m strings
- Address validation catches malformed addresses
- Network prefixes are correctly applied

### Integration Tests

- Generated mnemonics work with official Midnight wallet
- Encoded addresses are accepted by Midnight node
- Decoded addresses match original input

### Manual Testing

- Verify output formatting on different terminal widths
- Verify color output in different terminal emulators
- Test with actual testnet/mainnet addresses

---

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| SDK 3.x API changes before stable release | Medium | Medium | Pin to specific commits in Dockerfile.sdk |
| SDK packages not published to npm | Medium | High | Build from source via Dockerfile.sdk (current approach) |
| WASM package compatibility issues | High | Low | Pin ledger version, test thoroughly |
| Wallet sync performance | Medium | Medium | Add timeout handling, retry logic |

**Resolved Risks:**
- ~~Effect dependency required~~ → Using SDK packages directly (Effect included)
- ~~Cryptographic library vulnerabilities~~ → SDK uses audited libraries internally
- ~~SDK/Toolkit derivation mismatch~~ → Both use identical BIP44 paths; `legacyDerivation` flag removed
- ~~Error 115 on transaction submission~~ → Caused by SDK/Proof Server version mismatch; ensure ledger version matches proof server (see Version Compatibility below)

---

## Version Compatibility

Ensure SDK and service versions are aligned to avoid transaction errors (e.g., Error 115):

| SDK Ledger | Proof Server | Node | Indexer | Status |
|------------|--------------|------|---------|--------|
| 6.1.0-alpha.6 | 6.1.0-alpha.6 | 0.18.0 | 3.0.0-alpha.20 | ✅ Working |
| 6.1.0-alpha.6 | 6.2.0-rc.2 | 0.18.0 | 3.0.0-alpha.20 | ❌ Error 115 |

**Key insight:** The SDK ledger version must match the proof server version. Mismatched versions cause transaction submission to fail with "Custom error: 115".

See `vendor/README.md` for full compatibility matrix and `test/docker-compose.local.yml` for a working local setup.

---

## Open Questions

1. **HD Derivation Path:** Should we support custom derivation paths or use Midnight's default?
   - **Resolution:** ✅ Using SDK's default BIP44 derivation with `m/44'/2400'/0'/<role>/0`. Both SDK and toolkit use identical paths. The `legacyDerivation` flag was removed as it was incorrectly skipping HD derivation entirely.

2. **Shielded Address Generation:** Full shielded address generation requires additional cryptographic operations.
   - **Resolution:** ✅ Implemented via SDK 3.x ZswapWallet

3. **Key Export Formats:** Should we support exporting keys in different formats?
   - **Status:** ❌ Not implemented - wallets stored as JSON with mnemonic

4. **Passphrase Support:** BIP39 supports optional passphrases.
   - **Status:** ❌ Not implemented - add if users request it

5. **Wallet Encryption:** Should stored wallets be encrypted?
   - **Status:** ❌ Not implemented - low priority for early dev phase

---

## Phase 5: Runtime Wallet Operations (Priority: Medium)

This phase adds runtime wallet operations that interact with the Midnight node and indexer services. These commands complement the key/address management commands from earlier phases.

### FR-7: Wallet Balance

**Command:** `midnightctl wallet balance [seed]`

**Description:** Check wallet balance for tDUST and other tokens.

**Requirements:**
- FR-7.1: Accept wallet seed as argument or use stored default
- FR-7.2: Connect to node via `$MIDNIGHT_NODE_URL` environment variable
- FR-7.3: Display tDUST balance (unshielded and shielded)
- FR-7.4: Display registered token balances
- FR-7.5: Support `--json` output for scripting

**Example:**
```bash
$ midnightctl wallet balance
# Uses default wallet from config

$ midnightctl wallet balance 0x0000...0001

Wallet Balance
==============
  Network:    standalone
  Address:    mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...

  tDUST:
    Unshielded: 1,000,000.00
    Shielded:   0.00

  Tokens:
    (none registered)
```

---

### FR-8: Wallet Funding

**Command:** `midnightctl wallet fund <seed> <amount>`

**Description:** Fund a wallet from a genesis wallet (standalone/devnet only).

**Requirements:**
- FR-8.1: Only available on `standalone` and `devnet` networks
- FR-8.2: Use pre-funded genesis wallet (seed `0x000...001`) as source
- FR-8.3: Transfer specified amount of tDUST to target wallet
- FR-8.4: Display transaction hash and confirmation
- FR-8.5: Support `--from <seed>` to specify source wallet

**Implementation Note:** This wraps the `midnight-node-toolkit` Docker image or calls node RPC directly.

**Example:**
```bash
$ midnightctl wallet fund 0xabcd...1234 1000

Funding Wallet
==============
  Network:     standalone
  From:        Genesis Wallet #1
  To:          mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
  Amount:      1,000.00 tDUST

  Transaction: 0x9876...fedc
  Status:      Confirmed (block #12345)

$ midnightctl wallet fund 0xabcd...1234 500 --from 0x000...002
# Fund from a specific genesis wallet
```

---

### FR-9: Token Registration (DUST)

**Command:** `midnightctl wallet register-dust <seed>`

**Description:** Register a wallet for DUST token operations.

**Requirements:**
- FR-9.1: Register the wallet's shielded address for DUST token
- FR-9.2: Display registration transaction hash
- FR-9.3: Warn if wallet is already registered

**Example:**
```bash
$ midnightctl wallet register-dust 0xabcd...1234

DUST Registration
=================
  Wallet:      mn_shield-addr_standalone1qpzry9x8gf2tvdw0s3jn54k...
  Transaction: 0x5678...abcd
  Status:      Registered

Note: You can now receive shielded DUST tokens at this address.
```

---

### FR-10: Transaction Sending

**Command:** `midnightctl tx send <from-seed> <to-address> <amount>`

**Description:** Send tDUST tokens to another address.

**Requirements:**
- FR-10.1: Validate destination address format
- FR-10.2: Check sufficient balance before sending
- FR-10.3: Support both unshielded and shielded transfers
- FR-10.4: Display transaction hash and wait for confirmation
- FR-10.5: Support `--no-wait` flag to return immediately

**Example:**
```bash
$ midnightctl tx send 0xabcd...1234 mn_addr_standalone1xyz... 100

Sending Transaction
===================
  From:    mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
  To:      mn_addr_standalone1xyz...
  Amount:  100.00 tDUST
  Type:    Unshielded Transfer

  Transaction: 0xfedc...9876
  Status:      Confirmed (block #12350)
  New Balance: 900.00 tDUST
```

---

### FR-11: Transaction Status

**Command:** `midnightctl tx status <tx-hash>`

**Description:** Check the status of a transaction.

**Requirements:**
- FR-11.1: Query transaction by hash
- FR-11.2: Display confirmation status (pending, confirmed, failed)
- FR-11.3: Show block number if confirmed
- FR-11.4: Display error message if failed
- FR-11.5: Support `--json` output

**Example:**
```bash
$ midnightctl tx status 0x9876...fedc

Transaction Status
==================
  Hash:    0x9876...fedc
  Status:  Confirmed
  Block:   #12345
  Type:    Transfer
  From:    mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
  To:      mn_addr_standalone1xyz...
  Amount:  1,000.00 tDUST
```

---

### FR-12: Wallet Address Display

**Command:** `midnightctl wallet address <seed>`

**Description:** Display wallet addresses derived from a seed.

**Requirements:**
- FR-12.1: Derive and display unshielded address
- FR-12.2: Derive and display shielded address
- FR-12.3: Use current chain environment for network prefix
- FR-12.4: Support `--network` flag to override
- FR-12.5: Support `--json` output

**Example:**
```bash
$ midnightctl wallet address 0xabcd...1234

Wallet Addresses
================
  Network:     standalone
  
  Unshielded:  mn_addr_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
  Shielded:    mn_shield-addr_standalone1qpzry9x8gf2tvdw0s3jn54k...
  DUST:        mn_dust_standalone1qpzry9x8gf2tvdw0s3jn54khce6mua7l...
```

---

### Implementation Notes for Phase 5

**Dependencies:**
- Requires running midnight-node service (via `midnightctl services` or external)
- May use `midnight-node-toolkit` Docker image for some operations
- Requires indexer for balance queries

**Environment Variables:**
```bash
MIDNIGHT_NODE_URL=http://localhost:9944      # Node RPC endpoint
MIDNIGHT_INDEXER_URL=http://localhost:8088   # Indexer GraphQL endpoint
MIDNIGHT_DEFAULT_WALLET=0x000...001          # Optional default wallet seed
```

**Error Handling:**
- Clear error if services are not running
- Suggest `midnightctl services start` if connection fails
- Validate network compatibility (e.g., funding only on standalone/devnet)

---

## Future Phases (Backlog)

### Contract Operations (Phase 6)

```bash
midnightctl contract deploy <path>           # Deploy compiled contract
midnightctl contract call <addr> <method>    # Call contract method
midnightctl contract state <addr>            # Query contract state
```

### Advanced Wallet Features (Phase 7)

```bash
midnightctl wallet export <seed> --format    # Export keys in various formats
midnightctl wallet import <file>             # Import wallet from file
midnightctl wallet history <seed>            # Transaction history
midnightctl wallet shield <seed> <amount>    # Shield tokens
midnightctl wallet unshield <seed> <amount>  # Unshield tokens
```

---

## References

### Internal Documentation
- [WALLET-HOW-TO.md](./WALLET-HOW-TO.md) - User guide for wallet operations
- [vendor/README.md](./vendor/README.md) - SDK 3.x architecture and build process

### External Resources
- [Midnight Wallet SDK](https://github.com/midnightntwrk/midnight-wallet)
- [Midnight Wallet Specification](https://github.com/midnightntwrk/midnight-architecture/blob/main/components/WalletEngine/Specification.md)
- [BIP39 Specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [Bech32m Specification (BIP350)](https://github.com/bitcoin/bips/blob/master/bip-0350.mediawiki)
- [@scure/bip39](https://github.com/paulmillr/scure-bip39)
- [@scure/base](https://github.com/paulmillr/scure-base)

---

## Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Author | | 2025-12-17 | |
| Reviewer | | | |
| Approver | | | |
