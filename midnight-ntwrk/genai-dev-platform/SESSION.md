# SESSION.md

> **Last Updated:** 2025-01-08  
> **Purpose:** Track project status, outstanding work, and session context for continuity

---

## Current Session Focus

**Session Date:** 2025-01-08

Fixed Cloud Build IAM permissions blocking `make deploy`:
- Added `roles/iam.serviceAccountAdmin` to Cloud Build SA roles
- Added workstation user IAM bindings for service account access
- Updated session timeouts (idle: 12h, running: 24h)

---

## Platform Status

### Current Capabilities (All Implemented)

| Feature | Status | Description |
|---------|--------|-------------|
| Browser-based IDE | ✅ | Code OSS accessible from anywhere |
| OpenCode AI Agent | ✅ | Gemini/Claude via Vertex AI |
| Compact Compiler | ✅ | Pre-installed Midnight smart contract toolchain |
| Midnight CLI (`midnightctl`) | ✅ | Project scaffolding, compilation, service management |
| Wallet Management | ✅ | Create, fund, send, balance operations (SDK 3.x) |
| Managed Services | ✅ | Node, proof server, indexer on GKE Autopilot |
| Multi-chain Environments | ✅ | Standalone, devnet, testnet, mainnet |

### Wallet CLI Commands

| Command | Status | Notes |
|---------|--------|-------|
| `wallet create` | ✅ | SDK 3.x, BIP39 mnemonic generation |
| `wallet balance` | ✅ | SDK 3.x primary, `--use-toolkit` fallback |
| `wallet fund` | ✅ | SDK 3.x primary, standalone/devnet only |
| `wallet send` | ✅ | SDK 3.x, unshielded transfers only (shielded requires shielded tokens) |
| `wallet address` | ✅ | SDK 3.x primary |
| `wallet register-dust` | ✅ | SDK 3.x primary |
| `wallet import` | ✅ | Import from seed/mnemonic |
| `wallet list` | ✅ | List all wallets |
| `wallet set-default` | ✅ | Set default wallet |
| `wallet remove` | ✅ | Remove wallet |
| `wallet validate` | ❌ | Not implemented (low priority) |
| `address validate` | ❌ | Not implemented |
| `address encode` | ❌ | Not implemented |
| `address decode` | ❌ | Not implemented |
| `tx status` | ❌ | Not implemented |

### Contract Commands

| Command | Status | Notes |
|---------|--------|-------|
| `contract deploy` | ⚠️ WIP | Command exists but not fully functional |

### Version Compatibility

| SDK Ledger | Proof Server | Node | Indexer | Status |
|------------|--------------|------|---------|--------|
| 6.1.0-alpha.6 | 6.1.0-alpha.6 | 0.18.0 | 3.0.0-alpha.20 | ✅ Working |

**Key insight:** SDK ledger version must match proof server version.

---

## Completed Work

### This Session (2025-01-08)

- [x] Fixed Cloud Build SA IAM permissions for workstation user bindings
  - Added `roles/iam.serviceAccountAdmin` to `cloudbuild_sa_roles`
  - Required for `google_service_account_iam_binding` on workstation SA
- [x] Added workstation user/admin IAM bindings on workstation service account
  - Grants `roles/iam.serviceAccountUser` to all workstation users
  - Required for connecting to workstations
- [x] Updated README with bootstrap command for new IAM role
- [x] Increased workstation session timeouts (idle: 4h→12h, running: 12h→24h)

### 2025-01-07

- [x] Created `docs/GETTING-STARTED.md` - Hands-on tutorial (35-45 min)
- [x] Updated `README.md` with "New to Midnight?" section
- [x] Consolidated planning docs into SESSION.md
- [x] Removed duplicate `todos/` directory

### Earlier Work

- [x] SDK 3.x wallet integration (all core commands)
- [x] HD derivation fix (BIP44 paths match toolkit)
- [x] OpenCode AI agent setup with Vertex AI
- [x] GKE Autopilot deployment with managed services
- [x] Cloud Workstations configuration
- [x] Container image build pipeline (SDK + platform)

---

## Outstanding Work

### High Priority

| Item | Description | Notes |
|------|-------------|-------|
| Contract deployment | `midnightctl contract deploy` not working | Marked as "Coming Soon" in docs |
| Helm migration | Migrate K8s services from Terraform to Helm | Ready for execution, see plan below |

### Medium Priority

| Item | Description | Notes |
|------|-------------|-------|
| `--json` output | Add JSON output flag to wallet commands | For scripting/automation |
| Integration tests | Comprehensive test suite for CLI | Basic tests only currently |
| Shielded transfers | Document shielding workflow | Genesis wallets have unshielded only |

### Low Priority

| Item | Description | Notes |
|------|-------------|-------|
| `wallet validate` | Validate BIP39 mnemonic | Low priority |
| `address validate/encode/decode` | Address utility commands | `wallet address` covers most use cases |
| `tx status` | Query transaction status | |
| Wallet encryption | Encrypt stored wallet files | Low priority for dev phase |
| Passphrase support | BIP39 optional passphrase | Add if users request |

---

## Helm Migration Plan

**Status:** Ready for execution  
**Prerequisite:** `make deploy` must complete successfully first

### Overview

Replace Terraform-managed K8s resources with Helm chart deployed via `helm_release` resource. Enables fast K8s-only updates via `helm upgrade`.

### Decisions Made

| Decision | Choice |
|----------|--------|
| Chart location | `charts/midnight-services/` |
| Values structure | Separate files per environment |
| Service URLs | `kubernetes_service` data sources |
| Helm state | In-cluster (K8s secrets) |
| Migration | Clean cutover |

### Files Summary

| Action | Count |
|--------|-------|
| Create (Helm chart + scripts) | 12 |
| Modify (Terraform + Makefile) | 6 |
| Delete (old TF module) | 3 |
| **Total** | **21** |

### Cutover Steps

```bash
# 1. Configure kubectl
gcloud container clusters get-credentials midnight-dev-gke --region us-central1 --project $PROJECT_ID

# 2. Remove K8s resources from Terraform state
./scripts/cloud.sh state-cleanup "module.midnight_k8s_services"

# 3. Delete namespace (clean slate)
kubectl delete namespace midnight-services

# 4. Create Helm chart files (see detailed plan)

# 5. Deploy via Terraform
make deploy BUILD_SDK=false

# 6. Verify
./scripts/helm.sh status
./scripts/helm.sh pods
```

---

## Backlog (Future Enhancements)

### AI-Powered Development

| Feature | Description |
|---------|-------------|
| Compact Language Server | Autocomplete, go-to-definition for `.compact` |
| AI Contract Auditor | Analyze contracts for privacy leaks |
| Natural Language → Compact | Generate code from descriptions |
| Privacy Pattern Library | Pre-built patterns (transfers, auctions) |

### ZK Development Tools

| Feature | Description |
|---------|-------------|
| Circuit Visualizer | Graphical view of ZK circuits |
| Proof Debugger | Step through proof generation |
| Gas/Proof Cost Estimator | Estimate costs before deployment |
| Witness Inspector | Debug private inputs |

### Enhanced DApp Development

| Feature | Description |
|---------|-------------|
| DApp Scaffolding | `midnightctl init --template voting\|token\|nft` |
| Frontend SDK Integration | React/Vue templates with Midnight.js |
| Transaction Simulator | Simulate before sending |
| Privacy Flow Visualizer | Show public vs private data |

### Testing & Security

| Feature | Description |
|---------|-------------|
| Fuzz Testing | Automated property-based testing |
| Privacy Leak Detection | Static analysis |
| Formal Verification | Prove contract properties |
| Testnet Faucet | Easy testnet funding |

### Observability

| Feature | Description |
|---------|-------------|
| Transaction Explorer | View history, decode calldata |
| Indexer Query Builder | GraphQL builder with autocomplete |
| Log Aggregation | Unified log view |
| Metrics Dashboard | Proof times, throughput |

---

## Decisions Log

| Date | Decision | Choice | Rationale |
|------|----------|--------|-----------|
| 2025-01-08 | Cloud Build SA IAM | Add `serviceAccountAdmin` role | Required for workstation user bindings |
| 2025-01-08 | Workstation timeouts | 12h idle, 24h running | Longer dev sessions without interruption |
| 2025-01-07 | Getting started guide format | Markdown (`docs/GETTING-STARTED.md`) | Simple, works in IDE |
| 2025-01-07 | Wallet quick start approach | Use genesis wallet `0x01` | Faster for new devs |
| 2025-01-07 | Shielded transfer in docs | Removed example | Genesis wallets don't have shielded tokens |
| 2025-01-07 | Contract deploy in docs | Marked "Coming Soon" | Not yet working |
| 2025-01-07 | AI section placement | Moved to Part 2 | Key differentiator, show early |
| 2025-01-07 | Session tracking | Hybrid (current + archive) | Balance between clean state and history |
| 2025-12-21 | HD derivation | SDK default BIP44 paths | Match toolkit, genesis wallet compatibility |
| 2025-12-22 | Helm migration approach | Clean cutover | Simpler than gradual migration |

---

## Technical Reference

### SDK Dependencies

```json
{
  "@midnight-ntwrk/wallet-hd": "file:/opt/vendor/wallet/hd",
  "@midnight-ntwrk/dust-wallet": "file:/opt/vendor/wallet/dust-wallet",
  "@midnight-ntwrk/wallet-utilities": "file:/opt/vendor/wallet/utilities",
  "@midnight-ntwrk/midnight-js-providers": "file:/opt/vendor/midnight-js/providers",
  "@midnight-ntwrk/midnight-js-indexer": "file:/opt/vendor/midnight-js/indexer"
}
```

### HD Derivation Paths (BIP44)

| Role | Path | Purpose |
|------|------|---------|
| Unshielded External | `m/44'/2400'/0'/0/0` | Public transactions |
| Unshielded Internal | `m/44'/2400'/0'/1/0` | Change addresses |
| Dust | `m/44'/2400'/0'/2/0` | Fee payments |
| Zswap (Shielded) | `m/44'/2400'/0'/3/0` | Private transactions |
| Metadata | `m/44'/2400'/0'/4/0` | Metadata storage |

### Genesis Wallet Seeds

| Wallet | Seed |
|--------|------|
| Genesis #1 | `0x0000...0001` (64 hex chars) |
| Genesis #2 | `0x0000...0002` |
| Genesis #3 | `0x0000...0003` |
| Genesis #4 | `0x0000...0004` |

### Service Ports

| Service | Port | Protocol |
|---------|------|----------|
| Node | 9944 | WebSocket |
| Proof Server | 6300 | gRPC |
| Indexer | 8088 | HTTP/GraphQL |

---

## References

### Internal Documentation

- [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) - New developer tutorial
- [WALLET-HOW-TO.md](WALLET-HOW-TO.md) - Wallet operations guide
- [vendor/README.md](vendor/README.md) - SDK 3.x build process

### External Resources

- [Midnight Documentation](https://docs.midnight.network)
- [Compact Language Guide](https://docs.midnight.network/compact)
- [midnight-wallet SDK](https://github.com/midnightntwrk/midnight-wallet)
- [midnight-js SDK](https://github.com/midnightntwrk/midnight-js)

---

## Session Archive

### 2025-01-08

**Focus:** Fix Cloud Build IAM permissions blocking deployment

**Completed:**
- Added `roles/iam.serviceAccountAdmin` to Cloud Build SA roles
- Added workstation user IAM bindings (`roles/iam.serviceAccountUser` on workstation SA)
- Updated README bootstrap docs with new IAM role
- Increased workstation timeouts (idle: 12h, running: 24h)

**Root Cause:** `google_service_account_iam_binding` requires `iam.serviceAccounts.getIamPolicy` permission, which wasn't granted to Cloud Build SA.

---

### 2025-01-07

**Focus:** Developer documentation and consolidation

**Completed:**
- Created `docs/GETTING-STARTED.md` hands-on tutorial
- Updated README with link to getting started guide
- Restructured AI assistant section (moved to Part 2)
- Fixed wallet send example (create second wallet, verify transfer)
- Marked contract deploy as "Coming Soon"
- Consolidated all planning docs into SESSION.md
- Deleted `todos/` directory

**Key Decisions:**
- Use genesis wallet for quick start (vs creating new wallet with mnemonic)
- Remove shielded transfer example (genesis has unshielded only)
- Hybrid session tracking (current state + archive)
