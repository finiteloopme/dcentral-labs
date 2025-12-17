# Wallet Integration Requirements

**Document Version:** 1.0  
**Date:** 2025-12-17  
**Status:** Draft  

## Overview

This document outlines the requirements for integrating wallet utilities from the [midnight-wallet](https://github.com/midnightntwrk/midnight-wallet) SDK into the `midnightctl` CLI tool. The goal is to provide developers with essential wallet and address management capabilities directly from the command line.

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

### Selected Approach: Hybrid (Approach 3)

We will use a hybrid approach that combines:

1. **Public NPM packages** for audited cryptographic libraries
2. **Copied source files** from the midnight-wallet repo for Midnight-specific logic

This approach was chosen because:
- No dependency on private `@midnight-ntwrk/*` npm registry
- Uses battle-tested, audited crypto libraries (`@scure/*`)
- Minimal code to maintain from the wallet SDK
- Apache 2.0 license allows copying with attribution

### Source Repository

- **Repository:** https://github.com/midnightntwrk/midnight-wallet
- **License:** Apache 2.0
- **Relevant Packages:**
  - `packages/hd/` - HD wallet and mnemonic utilities
  - `packages/address-format/` - Bech32m address encoding
  - `packages/abstractions/` - NetworkId and type definitions

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

### Dependencies to Add

```json
{
  "dependencies": {
    "@scure/bip39": "^1.4.0",
    "@scure/base": "^1.1.0"
  }
}
```

| Package | Version | Purpose | License |
|---------|---------|---------|---------|
| `@scure/bip39` | ^1.4.0 | BIP39 mnemonic generation/validation | MIT |
| `@scure/base` | ^1.1.0 | Bech32m encoding/decoding | MIT |

**Note:** We intentionally avoid adding `effect` as a dependency. The wallet SDK uses Effect-TS heavily, but we will rewrite copied utilities to use plain TypeScript to keep our bundle smaller and simpler.

### File Structure

```
cli/
  src/
    commands/
      wallet/
        index.ts        # Command group
        generate.ts     # FR-1: Mnemonic generation
        validate.ts     # FR-2: Mnemonic validation
      address/
        index.ts        # Command group
        validate.ts     # FR-3: Address validation
        encode.ts       # FR-4: Address encoding
        decode.ts       # FR-5: Address decoding
    lib/
      midnight/
        mnemonic.ts     # Mnemonic utilities (from hd package)
        address.ts      # Address formatting (from address-format package)
        network.ts      # NetworkId definitions
        types.ts        # Type definitions
        LICENSE         # Apache 2.0 license text
        README.md       # Source attribution and version info
    index.ts            # Add new command groups
```

### Source Files to Copy

| Source File | Target Location | Modifications |
|-------------|-----------------|---------------|
| `packages/hd/src/MnemonicUtils.ts` | `lib/midnight/mnemonic.ts` | Remove Effect dependency |
| `packages/address-format/src/index.ts` | `lib/midnight/address.ts` | Remove Effect/ledger dependencies, simplify |
| `packages/abstractions/src/NetworkId.ts` | `lib/midnight/network.ts` | Copy as-is |

### API Design

```typescript
// lib/midnight/mnemonic.ts
export function generateMnemonic(strength?: 128 | 256): string[];
export function validateMnemonic(mnemonic: string): boolean;
export function mnemonicToSeed(mnemonic: string, passphrase?: string): Uint8Array;

// lib/midnight/address.ts
export type AddressType = 'addr' | 'shield-addr' | 'shield-cpk' | 'shield-epk' | 'dust';

export interface ParsedAddress {
  type: AddressType;
  network: string;
  data: Uint8Array;
}

export function parseAddress(bech32Address: string): ParsedAddress;
export function encodeAddress(type: AddressType, network: string, data: Uint8Array): string;
export function validateAddress(bech32Address: string): { valid: boolean; error?: string };

// lib/midnight/network.ts
export const NetworkId = {
  MainNet: 'mainnet',
  TestNet: 'testnet',
  DevNet: 'devnet',
  QaNet: 'qanet',
  Undeployed: 'undeployed',
  Preview: 'preview',
  PreProd: 'preprod',
  Standalone: 'standalone',  // Our addition for GKE-managed local dev
} as const;
```

---

## Implementation Plan

### Phase 1: Foundation (Priority: High)

1. Add npm dependencies (`@scure/bip39`, `@scure/base`)
2. Create `lib/midnight/` directory structure
3. Copy and adapt `MnemonicUtils.ts`
4. Copy and adapt address format utilities
5. Add `NetworkId` definitions

**Deliverables:**
- `lib/midnight/mnemonic.ts`
- `lib/midnight/address.ts`
- `lib/midnight/network.ts`
- `lib/midnight/LICENSE`
- Updated `package.json`

### Phase 2: Wallet Commands (Priority: High)

1. Implement `midnightctl wallet generate`
2. Implement `midnightctl wallet validate`
3. Add command to main CLI
4. Write unit tests

**Deliverables:**
- `commands/wallet/index.ts`
- `commands/wallet/generate.ts`
- `commands/wallet/validate.ts`
- Unit tests

### Phase 3: Address Commands (Priority: Medium)

1. Implement `midnightctl address validate`
2. Implement `midnightctl address encode`
3. Implement `midnightctl address decode`
4. Add command to main CLI
5. Write unit tests

**Deliverables:**
- `commands/address/index.ts`
- `commands/address/validate.ts`
- `commands/address/encode.ts`
- `commands/address/decode.ts`
- Unit tests

### Phase 4: Integration & Polish (Priority: Medium)

1. Update `env` command to use official NetworkIds
2. Add `--json` output support to all new commands
3. Update help text and examples
4. Integration testing

**Deliverables:**
- Updated `commands/env/index.ts`
- JSON output support
- Updated documentation

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
| Wallet SDK API changes | Medium | Medium | Pin to specific commit, document version |
| Cryptographic library vulnerabilities | High | Low | Use well-audited @scure packages, keep updated |
| Address format changes in Midnight protocol | High | Low | Monitor midnight-wallet releases |
| Effect dependency required | Medium | Medium | Rewrite utilities without Effect |

---

## Open Questions

1. **HD Derivation Path:** Should we support custom derivation paths or use Midnight's default?
   - **Recommendation:** Use Midnight's default path initially, add `--path` flag later if needed.

2. **Shielded Address Generation:** Full shielded address generation requires additional cryptographic operations. Should we support this in Phase 2 or defer?
   - **Recommendation:** Defer full shielded key generation to a future phase; focus on validation/parsing first.

3. **Key Export Formats:** Should we support exporting keys in different formats (hex, base64, JSON)?
   - **Recommendation:** Support hex and JSON initially; add others based on user feedback.

4. **Passphrase Support:** BIP39 supports optional passphrases. Should we include this?
   - **Recommendation:** Yes, add `--passphrase` flag to wallet commands.

---

## References

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
