# SESSION.md

> **Last Updated:** 2026-01-16  
> **Purpose:** Track project status, implementation progress, and session context for continuity

---

## Project Overview

**genai-chain-dev** is a modular framework for creating GenAI-enabled blockchain development platforms. It provides:

- **Earthly-based builds** with composable, overridable targets
- **TOML configuration** parsed at build time for chain-specific settings
- **Cloud Workstations integration** using Google's Code OSS base image
- **OpenCode AI agent** pre-configured with chain-specific context
- **Podman/Docker compatible** local development workflow

### Design Principles

1. **Build-time over runtime** - Do as much as possible during image build
2. **Sane defaults with overrides** - Earthly inheritance for customization
3. **TOML-driven configuration** - Single source of truth per chain
4. **Cloud Workstations native** - Use Google's base images and patterns
5. **CLI bundled in image** - No runtime downloads

---

## Repository Structure

```
genai-chain-dev/
├── Earthfile                           # Root orchestrator
├── Makefile                            # Root Makefile (use CHAIN= argument)
├── README.md
├── SESSION.md                          # This file
├── .env.example                        # Configuration template
├── cloudbuild.yaml                     # Parameterized Cloud Build (build + deploy)
├── cloudbuild-plan.yaml                # Terraform plan only
├── cloudbuild-destroy.yaml             # Destroy infrastructure
│
├── core/                               # Shared framework
│   ├── Earthfile                       # Base targets
│   ├── cli/                            # CLI framework (TypeScript)
│   ├── scripts/                        # Container setup scripts
│   ├── build/                          # TOML parser utilities
│   └── terraform/                      # Reusable TF modules
│
├── terraform/                          # Shared Terraform (chain as variable)
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── workstations.auto.tfvars.example
│
├── chains/
│   ├── evm/                            # EVM chain type
│   │   ├── Earthfile
│   │   ├── cli/                        # EVM CLI (viem, Foundry wrapper)
│   │   ├── scripts/                    # Foundry installation
│   │   └── templates/                  # Project templates
│   │
│   └── somnia/                         # First chain implementation (simplified)
│       ├── Earthfile                   # Chain-specific build
│       ├── chain.config.toml           # Chain configuration (single source)
│       └── AGENTS.md                   # OpenCode AI context
│
├── scripts/                            # Build/deploy scripts
│   ├── common.sh                       # parse_toml, load_chain_config, ensure_state_bucket
│   ├── cloud.sh                        # Cloud Build operations
│   ├── earthly-container.sh            # Run Earthly via Podman (no local install)
│   ├── build.sh
│   ├── run-local.sh
│   ├── deploy.sh                       # Local Terraform (uses shared terraform/)
│   ├── test.sh
│   ├── clean.sh
│   └── new-chain.sh                    # Creates Earthfile, config, AGENTS.md only
│
└── docs/                               # Documentation
```

---

## Implementation Status

### Phase 1: Core Framework ✅ COMPLETE

| Component | Status | Files |
|-----------|--------|-------|
| Directory structure | ✅ Complete | - |
| SESSION.md | ✅ Complete | `SESSION.md` |
| Root Earthfile | ✅ Complete | `Earthfile` |
| Core Earthfile | ✅ Complete | `core/Earthfile` |
| CLI framework | ✅ Complete | `core/cli/src/*` |
| CLI tests | ✅ Complete | `core/cli/src/__tests__/*` |
| TOML parser | ✅ Complete | `core/build/*` |
| Install scripts | ✅ Complete | `core/scripts/install/*` |
| Profile scripts | ✅ Complete | `core/scripts/profile.d/*` |
| Terraform: workstations | ✅ Complete | `core/terraform/modules/workstations/*` |
| Terraform: artifact-registry | ✅ Complete | `core/terraform/modules/artifact-registry/*` |

### Phase 2: EVM Chain Type ✅ COMPLETE

| Component | Status | Files |
|-----------|--------|-------|
| EVM Earthfile | ✅ Complete | `chains/evm/Earthfile` |
| EVM CLI entry | ✅ Complete | `chains/evm/cli/src/index.ts` |
| Wallet commands | ✅ Complete | `chains/evm/cli/src/commands/wallet/*` |
| Contract commands | ✅ Complete | `chains/evm/cli/src/commands/contract/*` |
| Node commands | ✅ Complete | `chains/evm/cli/src/commands/node/*` |
| Init command | ✅ Complete | `chains/evm/cli/src/commands/init.ts` |
| Network commands | ✅ Complete | `chains/evm/cli/src/commands/network.ts` |
| Wallet store lib | ✅ Complete | `chains/evm/cli/src/lib/wallet-store.ts` |
| Provider lib | ✅ Complete | `chains/evm/cli/src/lib/provider.ts` |
| Anvil lib | ✅ Complete | `chains/evm/cli/src/lib/anvil.ts` |
| CLI tests | ✅ Complete | `chains/evm/cli/src/__tests__/*` |
| Foundry installer | ✅ Complete | `chains/evm/scripts/install/foundry.sh` |
| Foundry template | ✅ Complete | `chains/evm/templates/foundry/*` |

### Phase 3: Somnia Chain ✅ COMPLETE

| Component | Status | Files |
|-----------|--------|-------|
| Somnia Earthfile | ✅ Complete | `chains/somnia/Earthfile` |
| chain.config.toml | ✅ Complete | `chains/somnia/chain.config.toml` |
| AGENTS.md | ✅ Complete | `chains/somnia/AGENTS.md` |

> **Note:** Per-chain terraform/, cloudbuild.yaml, and Makefile were removed during refactoring.
> Infrastructure is now centralized (see Phase 5).

### Phase 4: Scripts & Documentation ✅ COMPLETE

| Component | Status | Files |
|-----------|--------|-------|
| common.sh | ✅ Complete | `scripts/common.sh` |
| build.sh | ✅ Complete | `scripts/build.sh` |
| run-local.sh | ✅ Complete | `scripts/run-local.sh` |
| deploy.sh | ✅ Complete | `scripts/deploy.sh` |
| test.sh | ✅ Complete | `scripts/test.sh` |
| clean.sh | ✅ Complete | `scripts/clean.sh` |
| new-chain.sh | ✅ Complete | `scripts/new-chain.sh` |
| README.md | ✅ Complete | `README.md` |
| FRAMEWORK.md | ✅ Complete | `docs/FRAMEWORK.md` |
| ADDING-CHAIN.md | ✅ Complete | `docs/ADDING-CHAIN.md` |
| TOML-REFERENCE.md | ✅ Complete | `docs/TOML-REFERENCE.md` |

### Phase 5: Centralized Automation Refactoring ✅ COMPLETE

Refactored to centralize automation, enforce podman, and add prerequisites.

| Component | Status | Files |
|-----------|--------|-------|
| Root Makefile | ✅ Complete | `Makefile` (use `CHAIN=` argument) |
| Root cloudbuild.yaml | ✅ Complete | `cloudbuild.yaml` (parameterized) |
| cloudbuild-plan.yaml | ✅ Complete | `cloudbuild-plan.yaml` |
| cloudbuild-destroy.yaml | ✅ Complete | `cloudbuild-destroy.yaml` |
| .env.example | ✅ Complete | `.env.example` |
| Shared Terraform | ✅ Complete | `terraform/` (versions, variables, main, outputs) |
| tfvars example | ✅ Complete | `terraform/workstations.auto.tfvars.example` |
| cloud.sh | ✅ Complete | `scripts/cloud.sh` (Cloud Build operations) |
| common.sh updates | ✅ Complete | Added `parse_toml()`, `load_chain_config()`, `ensure_state_bucket()` |
| Podman enforcement | ✅ Complete | All scripts use podman only (no docker fallback) |
| README prerequisites | ✅ Complete | SA bootstrap instructions in README |

**Files Deleted:**
- `chains/somnia/Makefile`
- `chains/somnia/cloudbuild.yaml`
- `chains/somnia/terraform/` (entire directory)

**Key Design Decisions:**
- Podman only (no docker fallback)
- State bucket: project-wide, not per-chain
- SA bootstrap documented in README, not automated
- TOML parsed via TypeScript (`core/build/parse-toml.ts`)
- Chain config is single source of truth (`chain.config.toml`)

---

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Build system | Earthly | Composable, cacheable, compatible with Cloud Build |
| Container runtime | Podman only | Rootless, daemonless, OCI-compliant |
| Base image | Google Code OSS | Cloud Workstations native, VS Code included |
| CLI language | TypeScript | Type safety, familiar to web3 devs |
| CLI framework | Commander.js | Simple, well-documented |
| Testing | Vitest | Fast, ESM-native |
| Wallet storage | Plaintext JSON | Ephemeral dev convenience |
| Config format | TOML | Human-readable, well-structured |
| First chain | Somnia | User requirement |
| Terraform state | Project-wide bucket | Single state, chain as variable |
| TOML parsing | TypeScript | `core/build/parse-toml.ts`, not bash |
| Automation | Centralized | Root Makefile/cloudbuild, not per-chain |

---

## Key Interfaces

### ChainAdapter

```typescript
interface ChainAdapter {
  readonly id: string;           // "evm", "midnight"
  readonly displayName: string;  // "Somnia", "Midnight"
  wallet: WalletAdapter;
  contract: ContractAdapter;
  node?: NodeAdapter;
  networks: NetworkConfig[];
}
```

### WalletAdapter

```typescript
interface WalletAdapter {
  create(name: string): Promise<WalletResult>;
  import(name: string, secret: string): Promise<WalletResult>;
  list(): Promise<WalletInfo[]>;
  balance(name?: string): Promise<BalanceResult>;
  send(to: string, amount: string): Promise<TxResult>;
  address(name?: string): Promise<string>;
  remove(name: string): Promise<void>;
  setDefault(name: string): Promise<void>;
}
```

---

## CLI Commands (EVM)

| Command | Description | Wraps |
|---------|-------------|-------|
| `init <name>` | Scaffold Foundry project | Template copy |
| `compile` | Compile contracts | `forge build` |
| `test` | Run tests | `forge test` |
| `deploy <contract>` | Deploy contract | `forge script` |
| `verify <address>` | Verify on explorer | `forge verify-contract` |
| `wallet create <name>` | Create HD wallet | viem |
| `wallet import <name>` | Import from mnemonic/key | viem |
| `wallet balance [name]` | Check balance | viem |
| `wallet send <to> <amount>` | Send native token | viem |
| `wallet address [name]` | Show address | viem |
| `wallet list` | List wallets | Local storage |
| `wallet export <name>` | Export private key | Local storage |
| `wallet remove <name>` | Remove wallet | Local storage |
| `wallet set-default <name>` | Set default wallet | Local storage |
| `node start` | Start Anvil | `anvil` |
| `node stop` | Stop Anvil | Process kill |
| `node status` | Check status | Process check |
| `node logs` | View Anvil logs | Log file |
| `network list` | List networks | From config |
| `network current` | Show current network | From config |

---

## Version Compatibility

| Component | Version | Notes |
|-----------|---------|-------|
| Earthly | 0.8+ | Required for VERSION 0.8 syntax |
| Node.js | 20.x | LTS, used in CLI |
| TypeScript | 5.x | CLI development |
| Vitest | 1.x | Unit testing |
| viem | 2.x | EVM wallet/provider operations |
| Foundry | nightly | Forge, Cast, Anvil |
| Terraform | 1.5+ | Infrastructure |

---

## Environment Variables

### Build-time (from TOML)

| Variable | Description |
|----------|-------------|
| `CLI_NAME` | CLI binary name (e.g., `somniactl`) |
| `CHAIN_NAME` | Display name (e.g., `Somnia`) |
| `CHAIN_ID` | Default chain ID |
| `RPC_URL` | Default RPC endpoint |
| `EXPLORER_URL` | Block explorer URL |
| `FAUCET_URL` | Testnet faucet URL |
| `NATIVE_CURRENCY` | Native token symbol |

### Runtime

| Variable | Description |
|----------|-------------|
| `CHAIN_CONFIG_DIR` | Config directory (default: `/etc/chain`) |
| `WALLET_DIR` | Wallet storage (default: `~/.config/{cli_name}/wallets`) |

---

## Session Archive

### 2026-01-16 (Session 5)

**Focus:** Fix local container runtime issues (port binding, gcloud directory)

**Completed:**
- [x] Fixed Code OSS `EACCES: permission denied 0.0.0.0:80` error when running locally
  - Base image hardcodes `EDITOR_PORT=80` which requires root privileges
  - Created `codeoss-port.sh` configure script to patch `110_start-code-oss.sh` at build time
  - Runtime detection: checks for GCP metadata service, uses port 80 on GCP, port 8080 locally
- [x] Fixed `/home/user/.config/gcloud/gce: No such file or directory` error
  - Base image's `disable_gcloud_gce_check.sh` profile script writes to non-existent directory
  - Created `gcloud-dirs.sh` as a startup script (not build-time) installed to `/etc/workstation-startup.d/015_gcloud-dirs.sh`
  - Runs after `010_add-user.sh` (user creation) but before `110_start-code-oss.sh`
  - Creates `/home/user/.config/gcloud/`, `/home/user/.cache/`, `/home/user/.codeoss-cloudworkstations/` with proper ownership
- [x] Updated `core/Earthfile` to run configure scripts in `workstation-base` target
- [x] Verified fix: Code OSS accessible at http://localhost:8080

- [x] Added `make stop` target and container stopping to `make clean`
  - `make stop CHAIN=somnia` - Stop running container without cleaning
  - `make clean CHAIN=somnia` - Now stops container before cleaning build artifacts
  - Added `--stop-only` flag to `clean.sh`
  - Without `CHAIN=`, stops all chain containers
- [x] Added `--replace` flag to detached container runs
  - `make run CHAIN=somnia` now automatically replaces existing container
  - No more "name already in use" errors on re-run
- [x] Fixed OpenCode "command not found" error for user account
  - Root cause: Official installer installs to `/root/.opencode/` which is inaccessible to `user`
  - Solution: Changed to `npm install -g opencode-ai` (like midnight-ntwrk repo)
  - OpenCode now installs to `/usr/bin/opencode`, accessible to all users
- [x] Fixed OpenCode "EACCES: permission denied" for config directory
  - Root cause: `/home/user/.config/opencode/` didn't exist
  - Solution: Renamed `gcloud-dirs.sh` to `user-dirs.sh`, added opencode config directory
  - Now creates: `.config/gcloud/`, `.config/opencode/`, `.cache/`, `.codeoss-cloudworkstations/`
- [x] Added Vertex AI configuration for OpenCode (Gemini + Claude models)
  - Created `core/opencode/opencode.json` with Vertex AI model config
  - Models: gemini-2.5-pro, gemini-2.5-flash, gemini-2.0-flash, claude-opus-4-1
  - Created profile.d scripts for proper environment setup:
    - `gcloud-adc.sh` - Local dev ADC credentials
    - `gcp-project.sh` - GCE metadata project detection (Cloud Workstations)
    - `opencode.sh` - User symlinks + VERTEX_LOCATION
  - Removed redundant `opencode-setup.sh` startup script
- [x] Added gcloud ADC mounting for local development
  - `run-local.sh` now mounts `~/.config/gcloud/application_default_credentials.json`
  - Auto-detects `GOOGLE_CLOUD_PROJECT` from gcloud config
  - Enables OpenCode Vertex AI integration locally
- [x] Added chain-specific environment variable overrides
  - Can override `RPC_URL`, `CHAIN_ID`, `EXPLORER_URL`, `FAUCET_URL` via .env or shell
  - Useful for local Anvil forks or connecting to different testnet endpoints
  - `run-local.sh` now sources `.env` file
- [x] Fixed container env var persistence for login shells
  - Container env vars passed via `-e` are now persisted to `/etc/container-env.sh` at startup
  - New `profile.d/container-env.sh` sources this file so login shells see the vars
  - Fixes `GOOGLE_CLOUD_PROJECT` not being available in user shell

**Key Changes:**
| Category | Before | After |
|----------|--------|-------|
| Code OSS port (local) | 80 (permission denied) | 8080 (non-privileged) |
| Code OSS port (GCP) | 80 | 80 (unchanged) |
| User directories | Missing at runtime | Created by startup script `015_user-dirs.sh` |
| `make clean` | Only cleaned artifacts | Stops containers first, then cleans |
| `make stop` | Did not exist | New target to stop containers |
| `make run` (detached) | Failed if container existed | Uses `--replace` to auto-remove old container |
| OpenCode install | Official installer → `/root/.opencode/` | npm global install → `/usr/bin/opencode` |
| OpenCode config | None | Vertex AI config with Gemini + Claude models |
| Profile scripts | Combined gcloud-adc.sh | Split: gcloud-adc.sh, gcp-project.sh, opencode.sh |

**Files Created:**
- `core/scripts/configure/codeoss-port.sh` - Build-time patch for port detection
- `core/scripts/configure/user-dirs.sh` - Startup script for user directory creation + env var persistence
- `core/opencode/opencode.json` - Vertex AI model configuration (Gemini + Claude)
- `core/scripts/profile.d/gcp-project.sh` - GCE metadata project detection
- `core/scripts/profile.d/opencode.sh` - User symlinks + VERTEX_LOCATION
- `core/scripts/profile.d/container-env.sh` - Sources persisted container env vars

**Files Modified:**
- `core/Earthfile` - Run codeoss-port.sh at build time, install user-dirs.sh, copy opencode.json
- `scripts/clean.sh` - Added `stop_containers()` function, `--stop-only` flag
- `scripts/run-local.sh` - Added `--replace` flag, gcloud ADC mounting, chain env overrides, load .env
- `Makefile` - Added `stop` target, updated `clean` description
- `README.md` - Fixed ethers.js→viem reference, added `stop`/`clean` to make targets, added Vertex AI setup docs
- `docs/FRAMEWORK.md` - Fixed ethers.js→viem references
- `docs/ADDING-CHAIN.md` - Removed outdated per-chain terraform/makefile/cloudbuild, updated for centralized approach, fixed docker→podman
- `core/scripts/install/opencode.sh` - Changed from official installer to npm global install
- `core/scripts/profile.d/gcloud-adc.sh` - Simplified to local ADC only
- `.env.example` - Added local dev override section (RPC_URL, CHAIN_ID, etc.)

**Files Deleted:**
- `core/scripts/configure/opencode-setup.sh` - Replaced by profile.d/opencode.sh
- `core/scripts/configure/gcloud-dirs.sh` - Replaced by user-dirs.sh

---

### 2026-01-15 (Session 4)

**Focus:** Migrate EVM CLI from ethers.js to viem + Fix containerized Earthly build issues

**Completed:**
- [x] Replaced ethers.js with viem in `package.json`
- [x] Rewrote `provider.ts` to use viem's client-based architecture
  - Uses `createPublicClient` for read operations
  - Uses `createWalletClient` for write operations  
  - Uses `defineChain` to build chain from TOML config
- [x] Rewrote `wallet-store.ts` to use viem's account utilities
  - Uses `generateMnemonic` and `mnemonicToAccount` for wallet creation
  - Uses `privateKeyToAccount` for private key imports
- [x] Updated `wallet/index.ts` to use new provider API
- [x] Fixed test isolation issue in `wallet-store.test.ts` (mock `homedir()`)
- [x] All 11 tests passing
- [x] Fixed containerized Earthly TLS certificate mismatch error
  - Added `--hostname earthly-buildkitd` for consistent container hostname
  - TLS certificates in `~/.earthly/certs` now remain valid across runs
- [x] Fixed containerized Earthly image export to host Podman
  - Mount Podman socket into container for image export
  - Added `earthly-tmp` volume for better caching
- [x] Fixed OpenCode install URL (404 error)
  - Changed from `https://opencode.ai/install.sh` to `https://opencode.ai/install`
- [x] Fixed OpenCode not in PATH
  - Added symlink from `~/.opencode/bin/opencode` to `/usr/local/bin/opencode`
- [x] Verified complete somnia-dev image with all tools working:
  - Foundry (forge, cast, anvil): v1.5.1-stable
  - somniactl (chain CLI): v1.0.0
  - opencode (AI agent): v1.1.21

**Key Changes:**
| Category | Before | After |
|----------|--------|-------|
| EVM library | ethers.js ^6.11.0 | viem ^2.21.0 |
| Provider creation | `new JsonRpcProvider()` | `createPublicClient()` |
| Wallet creation | `new Wallet()` | `createWalletClient()` + `privateKeyToAccount()` |
| Chain definition | Manual object | `defineChain()` |
| Mnemonic generation | `Mnemonic.fromEntropy()` | `generateMnemonic()` |
| Transaction sending | `wallet.sendTransaction()` | `walletClient.sendTransaction()` |
| Earthly container hostname | Random (caused TLS errors) | Fixed `earthly-buildkitd` |
| Earthly image export | Not working (no runtime) | Podman socket mounted |
| OpenCode install URL | `install.sh` (404) | `install` (correct) |
| OpenCode PATH | Only in `/root/.opencode/bin` | Symlinked to `/usr/local/bin` |

**Files Modified:**
- `chains/evm/cli/package.json`
- `chains/evm/cli/src/lib/provider.ts`
- `chains/evm/cli/src/lib/wallet-store.ts`
- `chains/evm/cli/src/commands/wallet/index.ts`
- `chains/evm/cli/src/__tests__/wallet-store.test.ts`
- `scripts/earthly-container.sh` (hostname, socket mount, tmp volume)
- `core/scripts/install/opencode.sh` (URL fix, symlink to /usr/local/bin)

---

### 2026-01-15 (Session 3)

**Focus:** Add containerized Earthly build option and fix build issues

**Completed:**
- [x] Created `scripts/earthly-container.sh` - run Earthly via Podman without local installation
- [x] Added `make build-container CHAIN=<chain>` target to Makefile
- [x] Updated README.md Quick Start with containerized build instructions
- [x] Fixed Earthly 0.8 reserved target name: renamed `base` → `workstation-base` in `core/Earthfile`
- [x] Fixed EVM Earthfile to use `core+cli-build` artifacts instead of cross-context file paths
- [x] Added `.npmrc` files to CLI directories to enforce public npm registry
- [x] Regenerated `package-lock.json` files with public registry URLs

**Key Changes:**
| Category | Before | After |
|----------|--------|-------|
| Local Earthly | Required installation | Optional (containerized alternative) |
| Core Earthfile target | `base` (reserved in 0.8) | `workstation-base` |
| EVM CLI build | `COPY ../../core/cli/` (cross-context) | `COPY core+cli-build/...` (artifact) |
| npm registry | User's default (may be private) | Public `registry.npmjs.org` enforced |

**Files Created:**
- `scripts/earthly-container.sh`
- `core/cli/.npmrc`
- `chains/evm/cli/.npmrc`

**Files Modified:**
- `Makefile` (added `build-container` target)
- `README.md` (added containerized build docs)
- `core/Earthfile` (renamed `base` → `workstation-base`)
- `chains/evm/Earthfile` (fixed cross-context COPY)
- `core/cli/package-lock.json` (regenerated)
- `chains/evm/cli/package-lock.json` (regenerated)

---

### 2026-01-15 (Session 2)

**Focus:** Centralize automation and refactor infrastructure

**Completed:**
- [x] Created root Makefile with `CHAIN=` argument
- [x] Created parameterized cloudbuild.yaml, cloudbuild-plan.yaml, cloudbuild-destroy.yaml
- [x] Created shared `terraform/` directory (versions.tf, variables.tf, main.tf, outputs.tf)
- [x] Created `.env.example` configuration template
- [x] Rewrote README.md with prerequisites and SA bootstrap instructions
- [x] Updated `scripts/common.sh` with `parse_toml()`, `load_chain_config()`, `ensure_state_bucket()`
- [x] Created `scripts/cloud.sh` for Cloud Build operations
- [x] Updated `scripts/deploy.sh` for shared terraform
- [x] Updated `scripts/run-local.sh`, `scripts/clean.sh` for podman only
- [x] Simplified `scripts/new-chain.sh` (only creates Earthfile, config, AGENTS.md)
- [x] Deleted `chains/somnia/{Makefile, cloudbuild.yaml, terraform/}`

**Key Changes:**
| Category | Before | After |
|----------|--------|-------|
| Container runtime | Mixed docker/podman | Podman only |
| Makefile | Per-chain | Root with `CHAIN=` arg |
| Cloud Build | Per-chain | Root with `_CHAIN` substitution |
| Terraform | Per-chain | Shared with chain as variable |
| Chain config | Duplicated | Single source: `chain.config.toml` |
| State bucket | Not handled | `make check-env` creates if missing |

---

### 2026-01-15 (Session 1)

**Focus:** Complete framework implementation

**Completed:**
- [x] Phase 1: Core framework (Earthfile, CLI framework, scripts, Terraform modules)
- [x] Phase 2: EVM chain type (Foundry integration, wallet/contract/node commands)
- [x] Phase 3: Somnia chain (configuration, Terraform, cloudbuild, Makefile)
- [x] Phase 4: Scripts & documentation (build/deploy scripts, docs)

**Total Files Created:** 75+

**Notes:**
- Project located at `/home/kunall/scratchpad/dcentral-labs/genai-chain-dev/`
- Sibling to `midnight-ntwrk/` monorepo
- First chain: Somnia (EVM-compatible)
- Ready for local testing with `earthly +dev` in `chains/somnia/`

---

## Next Steps (Future Enhancements)

- [x] End-to-end build testing with Earthly (completed - `make build-container` working)
- [x] **Migrate EVM CLI from ethers.js to viem** (completed Session 4)
- [ ] Add more EVM chains (Polygon, Arbitrum, etc.) using `new-chain.sh`
- [ ] Implement non-EVM chain types (Midnight, Solana)
- [ ] Add contract verification automation
- [ ] Integrate faucet requests into CLI
- [ ] Add Hardhat compatibility layer
- [ ] Create GitHub Actions workflows

---

## References

### Internal

- `chain.config.toml` - Chain configuration (per chain)
- `AGENTS.md` - OpenCode AI context (per chain)
- `docs/FRAMEWORK.md` - Architecture documentation
- `docs/ADDING-CHAIN.md` - Guide for adding new chains
- `docs/TOML-REFERENCE.md` - Configuration reference

### External

- [Earthly Documentation](https://docs.earthly.dev/)
- [Cloud Workstations Base Images](https://cloud.google.com/workstations/docs/preconfigured-base-images)
- [Foundry Book](https://book.getfoundry.sh/)
- [viem Documentation](https://viem.sh/)
- [Somnia Network](https://somnia.network/)
