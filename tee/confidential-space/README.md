# Confidential Space Hello World

A minimal Rust (axum) HTTP server deployed on [GCP Confidential Space](https://cloud.google.com/confidential-computing/confidential-space/docs) behind a global HTTP load balancer via a Managed Instance Group (MIG).

The project demonstrates end-to-end deployment of a containerised workload into a hardware-backed Trusted Execution Environment (TEE), first on the **debug** Confidential Space image (SSH enabled, VM stays running) and then on the **production** image (locked down, no operator access).

---

## Architecture

```
Internet
   │
   ▼
Global HTTP Load Balancer (port 80)
   │
   ▼
Backend Service ◄── Health Check (HTTP GET /health :8080)
   │
   ▼
Managed Instance Group (auto-healing, autoscaler 1-3 replicas)
   │
   ▼
Confidential Space VMs (AMD SEV, N2D)
   └─ Container-Optimized OS pulls container image from Artifact Registry
      └─ Runs axum Rust server on :8080
```

| Component | Detail |
|-----------|--------|
| Confidential Computing | AMD SEV on `n2d-standard-2` (supports live migration) |
| OS Image | `confidential-space-debug` or `confidential-space` from `confidential-space-images` project |
| Container Runtime | Built-in launcher pulls image ref from VM metadata (`tee-image-reference`) |
| Health Check | HTTP `GET /health` on port 8080 — interval 10s, healthy after 2, unhealthy after 3 |
| Auto-healing | MIG replaces instances that fail health check (300s initial delay for boot + container pull) |
| Rolling Updates | Proactive update policy — MIG automatically replaces instances when the template changes (surge 1, unavailable 0) |
| Autoscaler | 1–3 replicas, 60% CPU utilisation target |
| Terraform Execution | Cloud Build (`gcloud builds submit`) using a dedicated `cs-terraform` service account — no local Terraform binary required |

---

## Project Structure

```
confidential-space/
├── config.toml                       # Primary configuration (checked into git)
├── .env.example                      # Template for local overrides (.env is gitignored)
├── .gitignore
├── .gcloudignore                     # Excludes target/, .git/, .terraform/ from Cloud Build uploads
├── Makefile                          # Minimalist task runner — delegates to scripts/
├── Cargo.toml                        # Rust project manifest
├── Cargo.lock
├── Dockerfile                        # Multi-stage: rust:1.85 builder → debian:bookworm-slim
├── src/
│   └── main.rs                       # Axum HTTP server (GET / and GET /health)
├── scripts/
│   ├── common.sh                     # Config loader: parses config.toml (yq) + .env overlay
│   ├── setup.sh                      # Bootstrap: install yq, enable GCP APIs, create bucket + AR repo
│   ├── image.sh                      # Container image build (local) / submit (Cloud Build)
│   ├── cloud-build.sh                # Terraform plan/apply/destroy/output via Cloud Build
│   └── health.sh                     # Probe the load balancer health and root endpoints
└── terraform/
    ├── main.tf                       # Root module: wires networking, compute, lb modules
    ├── variables.tf                  # Input variables (populated from terraform.tfvars)
    ├── outputs.tf                    # LB IP, service account email, MIG name
    ├── backend.tf                    # GCS remote state backend
    ├── cloudbuild.yaml               # Cloud Build steps for Terraform (hashicorp/terraform:1.9)
    ├── cloudbuild-image.yaml         # Cloud Build steps for container image build + push
    └── modules/
        ├── networking/               # Firewall rules (health-check probes, IAP SSH), reserved LB IP
        ├── compute/                  # Service account, instance template, MIG, autoscaler
        └── lb/                       # Backend service, URL map, HTTP proxy, forwarding rule
```

---

## Configuration

### config.toml

Primary configuration file checked into version control. All defaults live here.

```toml
[gcp]
project_id = "kunal-scratch"
region     = "us-central1"
zone       = "us-central1-a"

[app]
name = "cs-hello-world"
port = 8080

[compute]
machine_type      = "n2d-standard-2"
confidential_type = "SEV"
mig_min_replicas  = 1
mig_max_replicas  = 3

[docker]
registry   = "us-docker.pkg.dev"
repository = "confidential-space-repo"

[cloudbuild]
service_account = "cs-terraform"

[deploy]
environment = "debug"   # "debug" or "prod"
```

### .env (local overrides)

Copy `.env.example` to `.env` and uncomment any value you want to override. Variable names follow the pattern `SECTION_KEY` (uppercased, dot replaced with underscore).

```bash
cp .env.example .env
# edit .env as needed
```

Inline environment variables also work:

```bash
DEPLOY_ENVIRONMENT=prod make tf-apply
```

### Config Precedence

Highest wins:

```
inline env vars  >  .env file  >  config.toml
```

For example, `DEPLOY_ENVIRONMENT=prod make deploy-prod` overrides the `deploy.environment` value from `config.toml`.

### Config Flow

```
config.toml ──(yq -p toml -o props)──► env vars ──(.env source)──► inline env ──► final config
                                                                                       │
                                                                             ┌─────────┴──────────┐
                                                                             │                    │
                                                                        scripts/*.sh        terraform.tfvars
                                                                     (image, health, etc)   (generated, submitted
                                                                                             to Cloud Build)
```

### Derived Values

These are computed automatically by `scripts/common.sh`:

| Variable | Derivation |
|----------|------------|
| `CS_IMAGE_FAMILY` | `confidential-space-debug` if `DEPLOY_ENVIRONMENT=debug`, else `confidential-space` |
| `DOCKER_IMAGE_URI` | `${DOCKER_REGISTRY}/${GCP_PROJECT_ID}/${DOCKER_REPOSITORY}/${APP_NAME}:latest` |
| `TF_STATE_BUCKET` | `${GCP_PROJECT_ID}-cs-tf-state` |
| `CB_SA_EMAIL` | `${CLOUDBUILD_SERVICE_ACCOUNT}@${GCP_PROJECT_ID}.iam.gserviceaccount.com` |

---

## Prerequisites

- **gcloud CLI** — authenticated with a project that has billing enabled
- **Podman** — optional, only needed for local image builds (`make image-build`)
- **yq** — installed automatically by `make setup` (go-yq v4)
- **No Terraform or Docker required locally** — all image builds, pushes, and Terraform runs happen in Cloud Build

---

## Deployment

### One-time Setup

```bash
make setup
```

This will:
1. Install `yq` (go-yq v4) to `~/.local/bin` if not present
2. Verify `gcloud` and `podman` are available
3. Enable required GCP APIs (`compute`, `confidentialcomputing`, `artifactregistry`, `cloudbuild`, `storage`)
4. Create the `iam.googleapis.com` API if not enabled
5. Create a dedicated Cloud Build service account (`cs-terraform@PROJECT.iam`) with the exact IAM roles needed by Terraform (see below)
6. Create a GCS bucket for Terraform state (`${PROJECT_ID}-cs-tf-state`) with versioning
7. Create an Artifact Registry container repository

#### Cloud Build Service Account

All Cloud Build jobs (image builds and Terraform operations) run as a dedicated service account rather than the default Cloud Build SA. This follows the principle of least privilege.

| Role | Purpose |
|------|---------|
| `roles/compute.admin` | Create/manage VMs, MIG, LB, firewall, health checks, instance templates |
| `roles/iam.serviceAccountAdmin` | Create the workload service account |
| `roles/iam.serviceAccountUser` | Attach the workload SA to VM instances |
| `roles/resourcemanager.projectIamAdmin` | Bind IAM roles to the workload SA |
| `roles/storage.admin` | Read/write Terraform state in GCS |
| `roles/artifactregistry.writer` | Push container images to Artifact Registry |
| `roles/logging.logWriter` | Write Cloud Build logs |

### Phase 1: Debug Deployment

```bash
make deploy-debug
```

This runs the full pipeline:
1. Submits the source to Cloud Build, which builds the container image and pushes it to Artifact Registry
2. Submits Terraform apply via Cloud Build with the **debug** Confidential Space image

Debug image behaviour:
- SSH is enabled — you can SSH into the VM to inspect the container
- The VM stays running after the workload exits (return code 4)
- Container logs are redirected to Cloud Logging
- IAP SSH firewall rule is created

Verify the deployment:

```bash
make health
```

### Phase 2: Production Deployment

Once everything works in debug:

```bash
make deploy-prod
```

The MIG uses a **proactive rolling update policy** — when the instance template changes (e.g., switching from debug to production CS image), the MIG automatically drains the old instance and spins up a new one with zero downtime (`max_surge=1`, `max_unavailable=0`).

Production image behaviour:
- SSH is **disabled** — the operator cannot access the VM
- `tee-restart-policy=Always` keeps the workload alive
- The VM stops on unrecoverable failure (return code 1)
- IAP SSH firewall rule is **not** created

Verify the deployment (wait ~5 minutes for the CS image to boot and pull the container):

```bash
make health
```

The response should show `"environment": "prod"` confirming the production instance is serving.

---

## Makefile Targets

### Build

| Target | Description |
|--------|-------------|
| `make build` | Compile the Rust binary locally (`cargo build --release`) |
| `make image-build` | Build the container image locally with podman (for testing) |
| `make image-submit` | Build + push the container image via Cloud Build |

### Infrastructure (via Cloud Build)

| Target | Description |
|--------|-------------|
| `make tf-plan` | Run `terraform plan` via Cloud Build |
| `make tf-apply` | Run `terraform apply` via Cloud Build |
| `make tf-destroy` | Run `terraform destroy` via Cloud Build |
| `make tf-output` | Fetch Terraform outputs via Cloud Build |

### Full Pipelines

| Target | Description |
|--------|-------------|
| `make deploy-debug` | Image submit (Cloud Build) + terraform apply with `confidential-space-debug` image |
| `make deploy-prod` | Image submit (Cloud Build) + terraform apply with `confidential-space` (production) image |

### Operations

| Target | Description |
|--------|-------------|
| `make health` | Probe the load balancer (`GET /health` and `GET /`) |
| `make config` | Print the resolved configuration |
| `make clean` | Remove local build artifacts and generated tfvars |
| `make setup` | Install yq, enable GCP APIs, bootstrap GCS bucket + AR repo |

---

## HTTP Endpoints

| Method | Path | Response |
|--------|------|----------|
| `GET` | `/` | `{"message": "Hello from Confidential Space!", "environment": "debug", "timestamp": "..."}` |
| `GET` | `/health` | `{"status": "healthy"}` |

The `environment` field reflects the `ENVIRONMENT` env var passed to the container via Confidential Space metadata (`tee-env-ENVIRONMENT`).

### Confidential Space Launch Policies

The Dockerfile declares launch policy labels that allow the Confidential Space launcher to accept operator-provided configuration:

```dockerfile
LABEL "tee.launch_policy.allow_env_override"="ENVIRONMENT"
LABEL "tee.launch_policy.log_redirect"="always"
```

Without these labels, the CS launcher will reject `tee-env-*` metadata and `tee-container-log-redirect` respectively. Any new environment variables passed via metadata must be added to `allow_env_override` (comma-separated).

---

## Terraform Modules

All Terraform runs inside Cloud Build using the `hashicorp/terraform:1.9` image, authenticated as the dedicated `cs-terraform` service account. State is stored in a GCS bucket.

### modules/networking

| Resource | Purpose |
|----------|---------|
| `google_compute_firewall.allow_health_check` | Allow Google health-check probes (`130.211.0.0/22`, `35.191.0.0/16`) on app port |
| `google_compute_firewall.allow_iap_ssh` | Allow IAP SSH access (debug only, conditional) |
| `google_compute_global_address.lb_ip` | Reserved static IP for the load balancer |

### modules/compute

| Resource | Purpose |
|----------|---------|
| `google_service_account.workload` | Workload SA with `workloadUser`, `artifactregistry.reader`, `logging.logWriter` roles |
| `google_compute_instance_template.cs_workload` | Confidential VM template: SEV, secure boot, CS image, container metadata |
| `google_compute_instance_group_manager.mig` | Zonal MIG with named port `http:8080`, auto-healing (300s delay), proactive rolling updates |
| `google_compute_autoscaler.mig` | 1–3 replicas, 60% CPU target, 120s cooldown |

### modules/lb

| Resource | Purpose |
|----------|---------|
| `google_compute_backend_service.default` | HTTP backend pointing to MIG, utilisation-based balancing |
| `google_compute_url_map.default` | Default route to backend service |
| `google_compute_target_http_proxy.default` | HTTP proxy |
| `google_compute_global_forwarding_rule.default` | Global forwarding rule on port 80 with reserved IP |

The `google_compute_health_check` is defined at the root level to avoid a circular dependency between the `compute` module (needs health check for auto-healing) and the `lb` module (needs the MIG instance group for the backend).

---

## Debugging

### SSH into debug VM

When deployed with the debug image, you can SSH into the Confidential Space VM:

```bash
gcloud compute ssh <INSTANCE_NAME> --zone=us-central1-a --project=kunal-scratch
```

### Interactive shell inside the container

Once SSHed in:

```bash
sudo ctr task exec -t --exec-id shell tee-container bash
```

### View Cloud Logging

Container stdout/stderr is redirected to Cloud Logging under the `confidential-space-launcher` log name:

```bash
gcloud logging read \
  'resource.type="gce_instance" AND logName:"confidential-space-launcher"' \
  --project=kunal-scratch \
  --limit=50 \
  --format="table(timestamp, textPayload)"
```

### MIG instance status

```bash
gcloud compute instance-groups managed list-instances cs-hello-world-mig \
  --zone=us-central1-a \
  --project=kunal-scratch
```

---

## Teardown

```bash
make tf-destroy
```

This removes all GCP resources created by Terraform. The Terraform state bucket and Artifact Registry repository (created by `make setup`) are **not** deleted — remove them manually if needed:

```bash
gsutil rm -r gs://kunal-scratch-cs-tf-state
gcloud artifacts repositories delete confidential-space-repo --location=us --project=kunal-scratch --quiet
```
