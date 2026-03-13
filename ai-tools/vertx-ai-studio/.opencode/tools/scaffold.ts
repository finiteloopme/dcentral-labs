import { tool } from "@opencode-ai/plugin"
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs"
import { join } from "path"

// ─── Project Detection ───────────────────────────────────────────────

type ProjectType = "node" | "go" | "python" | "rust" | "java" | "generic"

function detectProject(root: string): ProjectType {
  if (existsSync(join(root, "package.json"))) return "node"
  if (existsSync(join(root, "go.mod"))) return "go"
  if (
    existsSync(join(root, "pyproject.toml")) ||
    existsSync(join(root, "requirements.txt"))
  )
    return "python"
  if (existsSync(join(root, "Cargo.toml"))) return "rust"
  if (
    existsSync(join(root, "pom.xml")) ||
    existsSync(join(root, "build.gradle"))
  )
    return "java"
  return "generic"
}

function projectLabel(pt: ProjectType): string {
  const labels: Record<ProjectType, string> = {
    node: "Node.js/TypeScript",
    go: "Go",
    python: "Python",
    rust: "Rust",
    java: "Java",
    generic: "Generic",
  }
  return labels[pt]
}

// ─── File Helpers ────────────────────────────────────────────────────

function ensureDir(dir: string): void {
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
}

function safeWrite(
  path: string,
  content: string,
  force: boolean,
): string {
  if (existsSync(path) && !force) {
    return `  SKIP: ${path} (already exists)`
  }
  ensureDir(join(path, ".."))
  writeFileSync(path, content)
  return `  CREATED: ${path}`
}

// ─── Makefile Generation ─────────────────────────────────────────────

function generateMakefile(_pt: ProjectType): string {
  return `.PHONY: help \\
  local-init local-clean local-build local-run local-test local-lint \\
  container-init container-clean container-build container-run \\
  cloud-init cloud-build cloud-deploy cloud-clean \\
  logs-list logs-last logs-clean

help: ## Show this help
\t@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \\
\t  awk 'BEGIN {FS = ":.*?## "}; {printf "  \\033[36m%-20s\\033[0m %s\\n", $$1, $$2}'

# ─── Local Development ───────────────────────────────────────────────

local-init: ## Initialize local dev environment
\t@bash scripts/local.sh init

local-clean: ## Clean local build artifacts
\t@bash scripts/local.sh clean

local-build: ## Build the project locally
\t@bash scripts/local.sh build

local-run: ## Run the project locally
\t@bash scripts/local.sh run

local-test: ## Run tests locally
\t@bash scripts/local.sh test

local-lint: ## Run linter locally
\t@bash scripts/local.sh lint

# ─── Container Development ───────────────────────────────────────────

container-init: ## Pull/build base images
\t@bash scripts/container.sh init

container-clean: ## Remove containers and images
\t@bash scripts/container.sh clean

container-build: ## Build container image
\t@bash scripts/container.sh build

container-run: ## Run container locally
\t@bash scripts/container.sh run

# ─── Cloud Runtime ───────────────────────────────────────────────────

cloud-init: ## Initialize cloud resources (via Cloud Build)
\t@bash scripts/cloud.sh init

cloud-build: ## Build and push to Artifact Registry (via Cloud Build)
\t@bash scripts/cloud.sh build

cloud-deploy: ## Deploy to cloud runtime (via Cloud Build)
\t@bash scripts/cloud.sh deploy

cloud-clean: ## Tear down cloud resources (via Cloud Build)
\t@bash scripts/cloud.sh clean

# ─── Logs ─────────────────────────────────────────────────────────────

logs-list: ## List recent log files
\t@ls -lt logs/*.log 2>/dev/null | head -20 || echo "No log files found"

logs-last: ## Show the most recent log file
\t@ls -t logs/*.log 2>/dev/null | head -1 | xargs cat 2>/dev/null || echo "No log files found"

logs-clean: ## Remove all log files
\t@rm -rf logs/*.log && echo "Cleaned log files" || true
`
}

// ─── Scripts Generation ──────────────────────────────────────────────

function generateCommonSh(): string {
  return `#!/usr/bin/env bash
# Common functions sourced by all scripts
set -euo pipefail

# ─── Logging ──────────────────────────────────────────────────────────

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[0;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

log_info()  { echo -e "\${BLUE}[INFO]\${NC}  $*"; }
log_ok()    { echo -e "\${GREEN}[OK]\${NC}    $*"; }
log_warn()  { echo -e "\${YELLOW}[WARN]\${NC}  $*"; }
log_error() { echo -e "\${RED}[ERROR]\${NC} $*" >&2; }

die() { log_error "$@"; exit 1; }

# ─── Environment ─────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "\${SCRIPT_DIR}/.." && pwd)"

# Load .env if it exists (do NOT commit .env files)
if [[ -f "\${PROJECT_ROOT}/.env" ]]; then
  # shellcheck disable=SC1091
  source "\${PROJECT_ROOT}/.env"
fi

# ─── Defaults (override in .env or environment) ──────────────────────

export PROJECT_NAME="\${PROJECT_NAME:-$(basename "\${PROJECT_ROOT}")}"
export IMAGE_NAME="\${IMAGE_NAME:-\${PROJECT_NAME}}"
export IMAGE_TAG="\${IMAGE_TAG:-latest}"
export GCP_PROJECT="\${GCP_PROJECT:-}"
export GCP_REGION="\${GCP_REGION:-us-central1}"
export AR_REPO="\${AR_REPO:-\${PROJECT_NAME}}"

# ─── Helpers ──────────────────────────────────────────────────────────

require_cmd() {
  command -v "$1" &>/dev/null || die "'$1' is required but not installed."
}

confirm() {
  local prompt="\${1:-Are you sure?} [y/N] "
  read -r -p "\${prompt}" response
  [[ "\${response}" =~ ^[Yy]$ ]]
}

# ─── Log Capture ─────────────────────────────────────────────────────

LOG_DIR="\${PROJECT_ROOT}/logs"
mkdir -p "\${LOG_DIR}"

# Start capturing all stdout/stderr to a per-run log file.
# Usage: start_log <action-name>
start_log() {
  local action="\${1:-unknown}"
  LOG_FILE="\${LOG_DIR}/$(date +%Y%m%d-%H%M%S)-\${action}.log"
  exec > >(tee -a "\${LOG_FILE}") 2>&1
  log_info "Logging to \${LOG_FILE}"
}
`
}

function generateLocalSh(pt: ProjectType): string {
  const builds: Record<ProjectType, { init: string; clean: string; build: string; run: string; test: string; lint: string }> = {
    node: {
      init: '  require_cmd node\n  npm install\n  log_ok "Dependencies installed"',
      clean: '  rm -rf node_modules dist .next coverage build out\n  log_ok "Cleaned local artifacts"',
      build: '  npm run build\n  log_ok "Build complete"',
      run: '  npm run dev',
      test: '  npm test\n  log_ok "Tests passed"',
      lint: '  npm run lint 2>/dev/null || npx eslint .\n  log_ok "Lint passed"',
    },
    go: {
      init: '  require_cmd go\n  go mod download\n  log_ok "Dependencies downloaded"',
      clean: '  rm -rf bin/ dist/\n  go clean -cache\n  log_ok "Cleaned local artifacts"',
      build: '  go build -o bin/ ./...\n  log_ok "Build complete"',
      run: '  go run .',
      test: '  go test ./...\n  log_ok "Tests passed"',
      lint: '  golangci-lint run 2>/dev/null || go vet ./...\n  log_ok "Lint passed"',
    },
    python: {
      init: '  require_cmd python3\n  python3 -m venv .venv\n  source .venv/bin/activate\n  pip install -r requirements.txt 2>/dev/null || pip install -e ".[dev]" 2>/dev/null || true\n  log_ok "Virtual environment created and dependencies installed"',
      clean: '  rm -rf .venv __pycache__ .eggs *.egg-info dist build .pytest_cache .mypy_cache\n  find . -name "*.pyc" -delete\n  log_ok "Cleaned local artifacts"',
      build: '  python3 -m build 2>/dev/null || log_warn "No build step configured"\n  log_ok "Build complete"',
      run: '  source .venv/bin/activate 2>/dev/null || true\n  python3 -m "${PROJECT_NAME}" 2>/dev/null || python3 main.py 2>/dev/null || python3 app.py 2>/dev/null || die "Could not determine entry point"',
      test: '  source .venv/bin/activate 2>/dev/null || true\n  python3 -m pytest\n  log_ok "Tests passed"',
      lint: '  source .venv/bin/activate 2>/dev/null || true\n  ruff check . 2>/dev/null || python3 -m flake8 .\n  log_ok "Lint passed"',
    },
    rust: {
      init: '  require_cmd cargo\n  cargo fetch\n  log_ok "Dependencies fetched"',
      clean: '  cargo clean\n  log_ok "Cleaned local artifacts"',
      build: '  cargo build --release\n  log_ok "Build complete"',
      run: '  cargo run',
      test: '  cargo test\n  log_ok "Tests passed"',
      lint: '  cargo clippy -- -D warnings\n  log_ok "Lint passed"',
    },
    java: {
      init: '  if [[ -f pom.xml ]]; then\n    require_cmd mvn\n    mvn dependency:resolve\n  elif [[ -f build.gradle ]]; then\n    require_cmd gradle\n    gradle dependencies\n  fi\n  log_ok "Dependencies resolved"',
      clean: '  if [[ -f pom.xml ]]; then mvn clean; elif [[ -f build.gradle ]]; then gradle clean; fi\n  log_ok "Cleaned local artifacts"',
      build: '  if [[ -f pom.xml ]]; then mvn package -DskipTests; elif [[ -f build.gradle ]]; then gradle build -x test; fi\n  log_ok "Build complete"',
      run: '  if [[ -f pom.xml ]]; then mvn exec:java; elif [[ -f build.gradle ]]; then gradle run; fi',
      test: '  if [[ -f pom.xml ]]; then mvn test; elif [[ -f build.gradle ]]; then gradle test; fi\n  log_ok "Tests passed"',
      lint: '  if [[ -f pom.xml ]]; then mvn checkstyle:check; elif [[ -f build.gradle ]]; then gradle check; fi\n  log_ok "Lint passed"',
    },
    generic: {
      init: '  log_warn "No project type detected. Customize this script for your project."\n  log_ok "Init complete"',
      clean: '  rm -rf build dist out tmp\n  log_ok "Cleaned local artifacts"',
      build: '  log_warn "No build step configured. Edit scripts/local.sh to add your build command."',
      run: '  log_warn "No run command configured. Edit scripts/local.sh to add your run command."',
      test: '  log_warn "No test command configured. Edit scripts/local.sh to add your test command."',
      lint: '  log_warn "No lint command configured. Edit scripts/local.sh to add your lint command."',
    },
  }

  const b = builds[pt]
  // NOTE: \${b.*} interpolations in the template below are JS template expressions,
  // not bash variables — do NOT escape them with a backslash.
  return `#!/usr/bin/env bash
# Local development operations
# Usage: bash scripts/local.sh {init|clean|build|run|test|lint}

SCRIPT_DIR="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "\${SCRIPT_DIR}/common.sh"
start_log "local-\${1:-unknown}"

init() {
  log_info "Initializing local dev environment..."
${b.init}
}

clean() {
  log_info "Cleaning local artifacts..."
${b.clean}
}

build() {
  log_info "Building locally..."
${b.build}
}

run() {
  log_info "Running locally..."
${b.run}
}

test() {
  log_info "Running tests..."
${b.test}
}

lint() {
  log_info "Running linter..."
${b.lint}
}

# ─── Dispatch ─────────────────────────────────────────────────────────

case "\${1:-}" in
  init)  init  ;;
  clean) clean ;;
  build) build ;;
  run)   run   ;;
  test)  test  ;;
  lint)  lint  ;;
  *)     die "Usage: $0 {init|clean|build|run|test|lint}" ;;
esac
`
}

function generateContainerSh(pt: ProjectType): string {
  const port =
    pt === "node"
      ? "3000"
      : pt === "go"
        ? "8080"
        : pt === "python"
          ? "8000"
          : pt === "java"
            ? "8080"
            : "8080"

  return `#!/usr/bin/env bash
# Container development operations (Podman)
# Usage: bash scripts/container.sh {init|clean|build|run}

SCRIPT_DIR="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "\${SCRIPT_DIR}/common.sh"
start_log "container-\${1:-unknown}"

CONTAINER_PORT="\${CONTAINER_PORT:-${port}}"
HOST_PORT="\${HOST_PORT:-\${CONTAINER_PORT}}"

init() {
  log_info "Initializing container environment..."
  require_cmd podman
  # Pull base image to warm cache
  podman pull "$(head -1 "\${PROJECT_ROOT}/cicd/Dockerfile" | awk '{print $2}')" 2>/dev/null || true
  log_ok "Container environment ready"
}

clean() {
  log_info "Cleaning containers and images..."
  podman stop "\${PROJECT_NAME}" 2>/dev/null || true
  podman rm "\${PROJECT_NAME}" 2>/dev/null || true
  podman rmi "\${IMAGE_NAME}:\${IMAGE_TAG}" 2>/dev/null || true
  log_ok "Cleaned containers and images"
}

build() {
  log_info "Building container image..."
  require_cmd podman
  podman build \\
    -f "\${PROJECT_ROOT}/cicd/Dockerfile" \\
    -t "\${IMAGE_NAME}:\${IMAGE_TAG}" \\
    "\${PROJECT_ROOT}"
  log_ok "Image built: \${IMAGE_NAME}:\${IMAGE_TAG}"
}

run() {
  log_info "Running container..."
  require_cmd podman
  podman run --rm \\
    --name "\${PROJECT_NAME}" \\
    -p "\${HOST_PORT}:\${CONTAINER_PORT}" \\
    "\${IMAGE_NAME}:\${IMAGE_TAG}"
}

# ─── Dispatch ─────────────────────────────────────────────────────────

case "\${1:-}" in
  init)  init  ;;
  clean) clean ;;
  build) build ;;
  run)   run   ;;
  *)     die "Usage: $0 {init|clean|build|run}" ;;
esac
`
}

function generateCloudSh(): string {
  return `#!/usr/bin/env bash
# Cloud runtime operations (via Cloud Build)
# Usage: bash scripts/cloud.sh {init|build|deploy|clean}

SCRIPT_DIR="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "\${SCRIPT_DIR}/common.sh"
start_log "cloud-\${1:-unknown}"

AR_LOCATION="\${GCP_REGION}"
AR_IMAGE="\${AR_LOCATION}-docker.pkg.dev/\${GCP_PROJECT}/\${AR_REPO}/\${IMAGE_NAME}:\${IMAGE_TAG}"

init() {
  log_info "Initializing cloud resources..."
  require_cmd gcloud

  [[ -z "\${GCP_PROJECT}" ]] && die "GCP_PROJECT is not set. Export it or add to .env"

  # Submit Cloud Build to run Terraform init + plan
  gcloud builds submit \\
    --project="\${GCP_PROJECT}" \\
    --config="\${PROJECT_ROOT}/cicd/cloudbuild-plan.yaml" \\
    --substitutions="_TF_ACTION=init" \\
    "\${PROJECT_ROOT}"

  log_ok "Cloud resources initialized"
}

build() {
  log_info "Building and pushing image via Cloud Build..."
  require_cmd gcloud

  [[ -z "\${GCP_PROJECT}" ]] && die "GCP_PROJECT is not set. Export it or add to .env"

  gcloud builds submit \\
    --project="\${GCP_PROJECT}" \\
    --config="\${PROJECT_ROOT}/cicd/cloudbuild.yaml" \\
    --substitutions="_IMAGE_NAME=\${AR_IMAGE}" \\
    "\${PROJECT_ROOT}"

  log_ok "Image built and pushed: \${AR_IMAGE}"
}

deploy() {
  log_info "Deploying via Cloud Build..."
  require_cmd gcloud

  [[ -z "\${GCP_PROJECT}" ]] && die "GCP_PROJECT is not set. Export it or add to .env"

  gcloud builds submit \\
    --project="\${GCP_PROJECT}" \\
    --config="\${PROJECT_ROOT}/cicd/cloudbuild-apply.yaml" \\
    --substitutions="_TF_ACTION=apply" \\
    "\${PROJECT_ROOT}"

  log_ok "Deployment complete"
}

clean() {
  log_info "Tearing down cloud resources..."
  require_cmd gcloud

  [[ -z "\${GCP_PROJECT}" ]] && die "GCP_PROJECT is not set. Export it or add to .env"

  if ! confirm "This will destroy cloud infrastructure. Continue?"; then
    log_warn "Aborted."
    exit 0
  fi

  gcloud builds submit \\
    --project="\${GCP_PROJECT}" \\
    --config="\${PROJECT_ROOT}/cicd/cloudbuild-apply.yaml" \\
    --substitutions="_TF_ACTION=destroy" \\
    "\${PROJECT_ROOT}"

  log_ok "Cloud resources destroyed"
}

# ─── Dispatch ─────────────────────────────────────────────────────────

case "\${1:-}" in
  init)   init   ;;
  build)  build  ;;
  deploy) deploy ;;
  clean)  clean  ;;
  *)      die "Usage: $0 {init|build|deploy|clean}" ;;
esac
`
}

// ─── Container Files Generation ─────────────────────────────────────

function generateDockerfile(pt: ProjectType): string {
  const dockerfiles: Record<ProjectType, string> = {
    node: `# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -s /bin/sh -D appuser
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package*.json ./
EXPOSE 3000
USER appuser
CMD ["node", "dist/index.js"]
`,
    go: `# Stage 1: Build
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/bin/server .

# Stage 2: Runtime
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/bin/server /server
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/server"]
`,
    python: `# Stage 1: Build
FROM python:3.12-slim AS builder
WORKDIR /app
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Stage 2: Runtime
FROM python:3.12-slim
WORKDIR /app
RUN groupadd -g 1001 appgroup && useradd -u 1001 -g appgroup -m appuser
COPY --from=builder --chown=appuser:appgroup /opt/venv /opt/venv
COPY --from=builder --chown=appuser:appgroup /app .
ENV PATH="/opt/venv/bin:$PATH"
EXPOSE 8000
USER appuser
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
`,
    rust: `# Stage 1: Build
FROM rust:1.77-alpine AS builder
WORKDIR /app
RUN apk add --no-cache musl-dev
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs && cargo build --release && rm -rf src
COPY . .
RUN cargo build --release

# Stage 2: Runtime
FROM gcr.io/distroless/static-debian12
COPY --from=builder /app/target/release/app /app
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/app"]
`,
    java: `# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml ./
RUN mvn dependency:resolve
COPY . .
RUN mvn package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -s /bin/sh -D appuser
COPY --from=builder --chown=appuser:appgroup /app/target/*.jar app.jar
EXPOSE 8080
USER appuser
CMD ["java", "-jar", "app.jar"]
`,
    generic: `FROM alpine:3.19
WORKDIR /app
COPY . .
EXPOSE 8080
CMD ["sh", "-c", "echo 'Replace this with your application command'"]
`,
  }
  return dockerfiles[pt]
}

function generateDockerignore(pt: ProjectType): string {
  const common = `.git
.gitignore
.env
.env.*
*.md
LICENSE
.DS_Store
tmp/
.cache/
cicd/terraform/
cicd/cloudbuild*.yaml
`
  const extras: Record<ProjectType, string> = {
    node: `node_modules/
dist/
coverage/
.next/
.nuxt/
`,
    go: `bin/
vendor/
`,
    python: `__pycache__/
*.pyc
.venv/
venv/
.eggs/
*.egg-info/
.pytest_cache/
.mypy_cache/
`,
    rust: `target/
`,
    java: `target/
build/
.gradle/
`,
    generic: `build/
out/
`,
  }
  return common + extras[pt]
}

// ─── Cloud Build Generation ─────────────────────────────────────────

function generateCloudbuildYaml(): string {
  return `# Main build pipeline: build image and push to Artifact Registry
# Triggered by: push to main branch or manual submission
steps:
  # Build container image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-f'
      - 'cicd/Dockerfile'
      - '-t'
      - '\${_IMAGE_NAME}'
      - '.'

  # Push to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'push'
      - '\${_IMAGE_NAME}'

images:
  - '\${_IMAGE_NAME}'

substitutions:
  _IMAGE_NAME: 'us-central1-docker.pkg.dev/\${PROJECT_ID}/app/app:latest'

options:
  logging: CLOUD_LOGGING_ONLY
`
}

function generateCloudbuildPlanYaml(): string {
  return `# Terraform plan pipeline
# Triggered by: pull request events
# Runs terraform init + plan and outputs the plan for review
steps:
  # Initialize Terraform
  - name: 'hashicorp/terraform:1.7'
    dir: 'cicd/terraform'
    args:
      - 'init'
      - '-backend-config=bucket=\${_TF_STATE_BUCKET}'
      - '-backend-config=prefix=\${_TF_STATE_PREFIX}'
    env:
      - 'TF_IN_AUTOMATION=true'

  # Run plan (or custom action)
  - name: 'hashicorp/terraform:1.7'
    dir: 'cicd/terraform'
    args:
      - '\${_TF_ACTION}'
      - '-no-color'
      - '-input=false'
    env:
      - 'TF_IN_AUTOMATION=true'
      - 'TF_VAR_project_id=\${PROJECT_ID}'
      - 'TF_VAR_region=\${_REGION}'

substitutions:
  _TF_ACTION: 'plan'
  _TF_STATE_BUCKET: '\${PROJECT_ID}-tfstate'
  _TF_STATE_PREFIX: 'app'
  _REGION: 'us-central1'

options:
  logging: CLOUD_LOGGING_ONLY
`
}

function generateCloudbuildApplyYaml(): string {
  return `# Terraform apply pipeline
# Triggered by: merge to main branch
# Runs terraform init + apply (or destroy) with auto-approve
steps:
  # Initialize Terraform
  - name: 'hashicorp/terraform:1.7'
    dir: 'cicd/terraform'
    args:
      - 'init'
      - '-backend-config=bucket=\${_TF_STATE_BUCKET}'
      - '-backend-config=prefix=\${_TF_STATE_PREFIX}'
    env:
      - 'TF_IN_AUTOMATION=true'

  # Apply (or destroy)
  - name: 'hashicorp/terraform:1.7'
    dir: 'cicd/terraform'
    args:
      - '\${_TF_ACTION}'
      - '-auto-approve'
      - '-no-color'
      - '-input=false'
    env:
      - 'TF_IN_AUTOMATION=true'
      - 'TF_VAR_project_id=\${PROJECT_ID}'
      - 'TF_VAR_region=\${_REGION}'

substitutions:
  _TF_ACTION: 'apply'
  _TF_STATE_BUCKET: '\${PROJECT_ID}-tfstate'
  _TF_STATE_PREFIX: 'app'
  _REGION: 'us-central1'

options:
  logging: CLOUD_LOGGING_ONLY
`
}

// ─── Terraform Generation ────────────────────────────────────────────

function generateTfProviders(): string {
  return `terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
`
}

function generateTfBackend(): string {
  return `# State is stored in GCS. Backend config values are passed via
# Cloud Build substitutions (-backend-config flags).
terraform {
  backend "gcs" {
    # bucket and prefix are set via -backend-config in cloudbuild YAML
  }
}
`
}

function generateTfVariables(): string {
  return `variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "app"
}

variable "image" {
  description = "Container image to deploy (full Artifact Registry path)"
  type        = string
  default     = ""
}
`
}

function generateTfMain(): string {
  return `# ─── Artifact Registry ────────────────────────────────────────────────

resource "google_artifact_registry_repository" "app" {
  location      = var.region
  repository_id = var.service_name
  format        = "DOCKER"
  description   = "Container images for \${var.service_name}"
}

# ─── Cloud Run Service ───────────────────────────────────────────────

resource "google_cloud_run_v2_service" "app" {
  name     = var.service_name
  location = var.region

  template {
    containers {
      image = var.image != "" ? var.image : "\${var.region}-docker.pkg.dev/\${var.project_id}/\${var.service_name}/\${var.service_name}:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# ─── IAM: Allow unauthenticated access (public service) ─────────────
# Remove this block if the service should require authentication.

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = google_cloud_run_v2_service.app.project
  location = google_cloud_run_v2_service.app.location
  name     = google_cloud_run_v2_service.app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
`
}

function generateTfOutputs(): string {
  return `output "service_url" {
  description = "URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.app.uri
}

output "artifact_registry_repo" {
  description = "Artifact Registry repository URL"
  value       = "\${var.region}-docker.pkg.dev/\${var.project_id}/\${google_artifact_registry_repository.app.repository_id}"
}
`
}

// ─── Gitignore Generation ────────────────────────────────────────────

function gitignoreEntries(pt: ProjectType): string[] {
  const common = [
    "# Environment",
    ".env",
    ".env.local",
    ".env.*.local",
    "",
    "# OS",
    ".DS_Store",
    "Thumbs.db",
    "",
    "# IDE",
    ".idea/",
    ".vscode/settings.json",
    "*.swp",
    "*.swo",
    "*~",
    "",
    "# Terraform",
    ".terraform/",
    "*.tfstate",
    "*.tfstate.backup",
    "*.tfplan",
    ".terraform.lock.hcl",
    "",
    "# Build",
    "tmp/",
    ".cache/",
    "*.log",
    "logs/",
  ]

  const perLang: Record<ProjectType, string[]> = {
    node: ["", "# Node", "node_modules/", "dist/", "build/", "out/", ".next/", ".nuxt/", "coverage/"],
    go: ["", "# Go", "bin/", "/vendor/"],
    python: ["", "# Python", "__pycache__/", "*.pyc", ".venv/", "venv/", ".eggs/", "*.egg-info/", ".pytest_cache/", ".mypy_cache/"],
    rust: ["", "# Rust", "target/"],
    java: ["", "# Java", "target/", "build/", ".gradle/", "*.class"],
    generic: ["", "# Build", "build/", "out/"],
  }

  return [...common, ...perLang[pt]]
}

// ─── Component Scaffolding Helpers ───────────────────────────────────

type ScaffoldComponent = "makefile" | "scripts" | "container" | "cloudbuild" | "terraform" | "gitignore"

const ALL_COMPONENTS: ScaffoldComponent[] = ["makefile", "scripts", "container", "cloudbuild", "terraform", "gitignore"]

async function scaffoldMakefile(root: string, pt: ProjectType, force: boolean): Promise<string[]> {
  return [
    "── Makefile ──",
    safeWrite(join(root, "Makefile"), generateMakefile(pt), force),
  ]
}

async function scaffoldScripts(root: string, pt: ProjectType, force: boolean): Promise<string[]> {
  const dir = join(root, "scripts")
  ensureDir(dir)
  const results = [
    "── Scripts ──",
    safeWrite(join(dir, "common.sh"), generateCommonSh(), force),
    safeWrite(join(dir, "local.sh"), generateLocalSh(pt), force),
    safeWrite(join(dir, "container.sh"), generateContainerSh(pt), force),
    safeWrite(join(dir, "cloud.sh"), generateCloudSh(), force),
  ]
  try {
    await Bun.$`chmod +x ${dir}/*.sh`.text()
  } catch { /* non-fatal */ }
  return results
}

function scaffoldContainer(root: string, pt: ProjectType, force: boolean): string[] {
  const dir = join(root, "cicd")
  ensureDir(dir)
  return [
    "── Container Files ──",
    safeWrite(join(dir, "Dockerfile"), generateDockerfile(pt), force),
    safeWrite(join(dir, ".dockerignore"), generateDockerignore(pt), force),
  ]
}

function scaffoldCloudbuild(root: string, force: boolean): string[] {
  const dir = join(root, "cicd")
  ensureDir(dir)
  return [
    "── Cloud Build ──",
    safeWrite(join(dir, "cloudbuild.yaml"), generateCloudbuildYaml(), force),
    safeWrite(join(dir, "cloudbuild-plan.yaml"), generateCloudbuildPlanYaml(), force),
    safeWrite(join(dir, "cloudbuild-apply.yaml"), generateCloudbuildApplyYaml(), force),
  ]
}

function scaffoldTerraform(root: string, force: boolean): string[] {
  const dir = join(root, "cicd", "terraform")
  ensureDir(dir)
  return [
    "── Terraform ──",
    safeWrite(join(dir, "providers.tf"), generateTfProviders(), force),
    safeWrite(join(dir, "backend.tf"), generateTfBackend(), force),
    safeWrite(join(dir, "variables.tf"), generateTfVariables(), force),
    safeWrite(join(dir, "main.tf"), generateTfMain(), force),
    safeWrite(join(dir, "outputs.tf"), generateTfOutputs(), force),
  ]
}

function scaffoldGitignore(root: string, pt: ProjectType): string[] {
  const entries = gitignoreEntries(pt)
  const gitignorePath = join(root, ".gitignore")
  let existing: string[] = []
  if (existsSync(gitignorePath)) {
    existing = readFileSync(gitignorePath, "utf-8").split("\n")
  }
  const existingSet = new Set(existing.map((l) => l.trim()))
  const toAdd = entries.filter(
    (e) => !existingSet.has(e.trim()) && e.trim() !== "",
  )

  const results = ["── .gitignore ──"]
  if (toAdd.length === 0) {
    results.push("  .gitignore is up to date")
  } else {
    const newContent = existing.length > 0
      ? existing.join("\n") + "\n\n# Added by devops scaffold\n" + toAdd.join("\n") + "\n"
      : entries.join("\n") + "\n"
    writeFileSync(gitignorePath, newContent)
    results.push(
      existing.length > 0
        ? `  Updated .gitignore: added ${toAdd.length} entries`
        : `  Created .gitignore with ${entries.length} entries`,
    )
  }
  return results
}

// ─── Tool Export ─────────────────────────────────────────────────────

export const scaffold = tool({
  description:
    "Generate project operational structure: Makefile, scripts/, cicd/Dockerfile, " +
    "cicd/cloudbuild*.yaml, cicd/terraform/, and .gitignore. Detects project type " +
    "and tailors all files. Use the 'components' parameter to generate only specific " +
    "parts, or omit it to generate everything. Skips existing files unless force=true.",
  args: {
    components: tool.schema
      .array(tool.schema.enum(["makefile", "scripts", "container", "cloudbuild", "terraform", "gitignore"]))
      .optional()
      .describe(
        "Which components to scaffold. Options: makefile, scripts, container, " +
        "cloudbuild, terraform, gitignore. Omit to generate everything.",
      ),
    force: tool.schema
      .boolean()
      .optional()
      .describe("Overwrite existing files (default: false)"),
  },
  async execute(args, context) {
    const root = context.directory || "."
    const pt = detectProject(root)
    const force = args.force || false
    const components: ScaffoldComponent[] =
      args.components && args.components.length > 0
        ? args.components as ScaffoldComponent[]
        : ALL_COMPONENTS

    const results: string[] = [
      "Project Scaffold",
      "================",
      `Detected project type: ${projectLabel(pt)}`,
      `Components: ${components.join(", ")}`,
      "",
    ]

    for (const component of components) {
      switch (component) {
        case "makefile":
          results.push(...await scaffoldMakefile(root, pt, force))
          break
        case "scripts":
          results.push(...await scaffoldScripts(root, pt, force))
          break
        case "container":
          results.push(...scaffoldContainer(root, pt, force))
          break
        case "cloudbuild":
          results.push(...scaffoldCloudbuild(root, force))
          break
        case "terraform":
          results.push(...scaffoldTerraform(root, force))
          break
        case "gitignore":
          results.push(...scaffoldGitignore(root, pt))
          break
      }
      results.push("")
    }

    results.push("================")
    results.push("Scaffold complete. Run 'make help' to see available targets.")

    return results.join("\n")
  },
})
