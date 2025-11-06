# MVP Requirements Document: Privacy-Preserving DeFi Risk Management
**Version:** 1.0
**Date:** November 6, 2025
**Owner:** Engineering / DevOps

---

## 1. Executive Summary
This MVP will demonstrate a privacy-preserving DeFi transaction where a user deposits assets into an Arc.network protocol, subject to a 10% Total Value Locked (TVL) concentration limit. The concentration check must happen privately on Midnight.network, ensuring no public observer knows the user's individual balance.

**Core Value Proposition:** Enforcing systemic risk rules (public) on confidential user data (private) without centralized surveillance.

## 2. Architecture Overview
The MVP consists of four primary logical components:
1.  **Operator Laptop:** The control plane running `make` commands.
2.  **Mock Server (GCP):** A standard VM hosting the emulated blockchains (`anvil` for Arc, `midnight-node-docker` for Midnight).
3.  **TEE Service (GCP Confidential Space):** The trusted orchestrator running in an Intel TDX enclave. It holds ephemeral session keys, connects to both blockchains, generates ZK proofs, and manages transaction atomicity.
4.  **User Frontend (Local/Web):** A simple UI to trigger the TEE actions.

## 3. Technology Stack Choices
| Area | Choice | Rationale |
| :--- | :--- | :--- |
| **Confidential Hardware** | Intel TDX (GCP C3 Series) | Current best-in-class availability on GCP. |
| **Container Runtime** | Confidential Space | GCP's managed, hardened TEE runtime with built-in attestation. |
| **Local Development** | Podman | OCI-compliant, daemonless alternative to Docker. |
| **Infrastructure as Code**| Terraform (GCS Backend) | Industry standard, required for reproducible complex GCP setups. |
| **CI/CD Remote** | Google Cloud Build (GCB) | Secure, managed environment for building TEE images and running Terraform. |
| **Orchestration** | GNU Make + Shell Scripts | Minimalist local control plane; complex logic resides in auditable scripts. |
| **Mocks** | Anvil (Foundry) + Midnight Docker Node | Standard emulators for standard EVM and Midnight environments. |

---

## 4. Functional Requirements (User Journey)

### 4.1 Prerequisites (State Zero)
* **REQ-PRE-01:** Mock Arc chain (Anvil) is running and seeded with `MockUSDC`, `DeFiVault`, and `ComplianceRegistry` contracts.
* **REQ-PRE-02:** Mock Midnight chain is running with `PrivateLedger` contract deployed.
* **REQ-PRE-03:** TEE Service is healthy, attested, and has loaded latest contract addresses from config.

### 4.2 The Deposit Transaction (Happy Path)
* **REQ-FUN-01 (Initiate):** User frontend sends authenticated request to TEE: `POST /deposit {amount: 1M, asset: USDC}`.
* **REQ-FUN-02 (Compliance Check):** TEE queries `ComplianceRegistry` on Arc Mock to confirm user address is allowed (stubbed KYC).
* **REQ-FUN-03 (Risk Check & Lock):** TEE submits private transaction to Midnight Mock:
    * *Logic:* `IF (user_bal + amount) < 0.10 * (tvl + amount) THEN update_state ELSE revert`.
* **REQ-FUN-04 (Proof Generation):** TEE generates ZK proof of the successful Midnight state update.
* **REQ-FUN-05 (Settlement):** TEE submits transaction to `DeFiVault` on Arc Mock: `deposit(amount, zk_proof)`.
* **REQ-FUN-06 (Atomicity/Rollback):** IF REQ-FUN-05 fails (e.g., Arc reverts), TEE MUST submit a compensating transaction to Midnight to revert the private state change.

---

## 5. Component Specifications

### 5.1 TEE Service API (Confidential Space)
The TEE must expose a minimal, secured HTTP API.
* `GET /healthz`: Returns 200 OK only if successfully booted, attested, and connected to mocks.
* `POST /api/v1/session`: Handshake to establish secure, ephemeral user session.
* `POST /api/v1/deposit`: Triggers the main functional flow.

### 5.2 Mock Ecosystem (Standard VM)
Must run on a single `e2-standard` GCP instance via Docker Compose.
* **Service A: Arc (Anvil):** Exposed internally on port 8545. Non-mining mode (instant finality for demo).
* **Service B: Midnight Node:** Exposed internally on standard ports.

### 5.3 Smart Contracts (Stubs)
* **Arc (`DeFiVault.sol`):**
    * Must accept a dummy ZK proof (for MVP, we may mock the *verification* step if true Midnight integration is too complex for Sprint 1, but the architecture must support it).
    * Public `totalValueLocked` variable.
* **Midnight (`PrivateLedger.compact`):**
    * Private state map: `user -> balance`.
    * Public state variable: `mirror_tvl` (synced from Arc for the check).

---

## 6. DevOps & Infrastructure Requirements

### 6.1 Bootstrap Phase (One-Time Setup)
* **REQ-OPS-01:** `make bootstrap` must run a script to:
    * Create GCP Project (if needed).
    * Enable required APIs (Compute, IAM, Cloud Build, Artifact Registry, Secret Manager).
    * Create GCS Bucket for Terraform state with versioning enabled.

### 6.2 Infrastructure as Code (Terraform)
All infra must be defined in Terraform, executed via GCB.
* **REQ-INF-01 (Networking):** Private VPC; TEE VM can only egress to Mock VM internal IP and required GCP APIs.
* **REQ-INF-02 (Mock Server):** Standard GCE VM with Docker installed.
* **REQ-INF-03 (TEE Server):** C3-series VM with Intel TDX enabled.
* **REQ-INF-04 (IAM & WIP):** Workload Identity Pool configured to trust only the specific TEE container image hash.

### 6.3 CI/CD Pipelines (Google Cloud Build)
* **REQ-CICD-01 (Infra Pipeline):** `cloudbuild-infra.yaml` runs `terraform init/plan/apply` using the GCS backend.
* **REQ-CICD-02 (App Pipeline):** `cloudbuild-app.yaml` builds the TEE container (using Podman/Docker), pushes to Artifact Registry, and *automatically updates* the WIP policy with the new image digest.

### 6.4 Operational Control Plane (Makefile)
The developer interacts ONLY via `make` commands.
* `make bootstrap`: Run one-time setup.
* `make infra-up`: Deploy Mock VM and TEE networking.
* `make mocks-up`: Start Anvil/Midnight on the remote Mock VM.
* `make seed-mocks`: Deploy smart contracts to Anvil; update GCP Secret Manager with new addresses.
* `make deploy-app`: Build TEE container and update TEE VM.
* `make status`: Curl the TEE `/healthz` endpoint.
* `make logs`: Tail TEE logs via Cloud Logging.

---

## 7. MVP Limitations (Out of Scope)
1.  **True Decentralized Atomicity:** We rely on the TEE for rollback if Arc fails, rather than a cryptographic 2-phase commit.
2.  **Hardware Wallet Integration:** User private keys will be ephemeral session keys for the demo, not actual Ledger/Trezor integration.
3.  **Midnight Universal Verifier:** If the actual Midnight `Verifier.sol` is not available for Anvil, we will stub the verification check in `DeFiVault.sol` (accept ANY proof) but maintain the full proof generation flow in the TEE.