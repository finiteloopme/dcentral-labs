#!/usr/bin/env bash
#
# setup.sh - Install prerequisites and bootstrap GCP resources.
#
# What this script does:
#   1. Install yq (go-yq v4) if not present
#   2. Verify gcloud and podman are available
#   3. Enable required GCP APIs
#   4. Create dedicated Cloud Build service account with required IAM roles
#   5. Create GCS bucket for Terraform state (if not exists)
#   6. Create Artifact Registry repository (if not exists)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 1. Install yq if missing
# ---------------------------------------------------------------------------
install_yq() {
    local install_dir="$HOME/.local/bin"
    export PATH="$install_dir:$PATH"

    # Check if go-yq (mikefarah) is already installed.  A system-packaged
    # Python-based yq (e.g. /usr/bin/yq v3) does NOT count — it cannot
    # parse TOML.
    if command -v yq &>/dev/null && yq --version 2>/dev/null | grep -q "mikefarah"; then
        echo "[INFO]  go-yq already installed: $(yq --version)"
        return 0
    fi

    echo "[INFO]  Installing go-yq (mikefarah/yq v4)..."

    local os arch yq_url
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m)"

    case "$arch" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        arm64)   arch="arm64" ;;
        *)
            echo "[ERROR] Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    local yq_version="v4.44.6"
    yq_url="https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_${os}_${arch}"

    mkdir -p "$install_dir"
    curl -fsSL "$yq_url" -o "$install_dir/yq"
    chmod +x "$install_dir/yq"

    echo "[INFO]  go-yq installed: $(yq --version)"

    if ! echo "$PATH" | grep -q "$install_dir"; then
        echo "[WARN]  Add this to your shell profile:"
        echo "        export PATH=\"$install_dir:\$PATH\""
    fi
}

# ---------------------------------------------------------------------------
# 2. Verify required tools
# ---------------------------------------------------------------------------
verify_tools() {
    local missing=()

    command -v gcloud &>/dev/null || missing+=("gcloud")
    command -v podman &>/dev/null || missing+=("podman")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "[ERROR] Missing required tools: ${missing[*]}"
        echo "        Install them before proceeding."
        exit 1
    fi

    echo "[INFO]  gcloud: $(gcloud version 2>/dev/null | head -1)"
    echo "[INFO]  podman: $(podman --version)"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "======================================"
echo "  Confidential Space - Setup"
echo "======================================"

# Step 1: install yq first (needed by common.sh)
install_yq

# Step 2: verify other tools
verify_tools

# Step 3: load config (now that yq is available)
source "$SCRIPT_DIR/common.sh"

# Step 4: enable GCP APIs
echo ""
echo "[INFO]  Enabling required GCP APIs..."
gcloud services enable \
    compute.googleapis.com \
    confidentialcomputing.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com \
    storage.googleapis.com \
    --project="$GCP_PROJECT_ID" \
    --quiet

echo "[INFO]  APIs enabled."

# Step 5: create dedicated Cloud Build service account
echo ""
CB_SA_NAME="${CLOUDBUILD_SERVICE_ACCOUNT}"
CB_SA_EMAIL="${CB_SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
echo "[INFO]  Ensuring Cloud Build service account exists: $CB_SA_EMAIL"

if gcloud iam service-accounts describe "$CB_SA_EMAIL" \
    --project="$GCP_PROJECT_ID" &>/dev/null 2>&1; then
    echo "[INFO]  Service account already exists."
else
    gcloud iam service-accounts create "$CB_SA_NAME" \
        --display-name="Cloud Build Terraform SA" \
        --project="$GCP_PROJECT_ID" \
        --quiet
    echo "[INFO]  Service account created."
fi

echo "[INFO]  Granting IAM roles to $CB_SA_EMAIL ..."
CB_ROLES=(
    roles/compute.admin
    roles/iam.serviceAccountAdmin
    roles/iam.serviceAccountUser
    roles/resourcemanager.projectIamAdmin
    roles/storage.admin
    roles/artifactregistry.writer
    roles/logging.logWriter
)
for role in "${CB_ROLES[@]}"; do
    gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
        --member="serviceAccount:$CB_SA_EMAIL" \
        --role="$role" \
        --condition=None \
        --quiet >/dev/null
    echo "        $role"
done
echo "[INFO]  IAM roles granted."

# Step 6: create Terraform state bucket
echo ""
echo "[INFO]  Ensuring Terraform state bucket exists: gs://$TF_STATE_BUCKET"
if gsutil ls -b "gs://$TF_STATE_BUCKET" &>/dev/null; then
    echo "[INFO]  Bucket already exists."
else
    gsutil mb -p "$GCP_PROJECT_ID" -l "$GCP_REGION" "gs://$TF_STATE_BUCKET"
    gsutil versioning set on "gs://$TF_STATE_BUCKET"
    echo "[INFO]  Bucket created with versioning enabled."
fi

# Step 7: create Artifact Registry repository
echo ""
echo "[INFO]  Ensuring Artifact Registry repository exists: $DOCKER_REPOSITORY"
# Extract location from registry (e.g. "us" from "us-docker.pkg.dev")
ar_location="${DOCKER_REGISTRY%%-docker.pkg.dev}"
if gcloud artifacts repositories describe "$DOCKER_REPOSITORY" \
    --location="$ar_location" \
    --project="$GCP_PROJECT_ID" &>/dev/null 2>&1; then
    echo "[INFO]  Repository already exists."
else
    gcloud artifacts repositories create "$DOCKER_REPOSITORY" \
        --repository-format=docker \
        --location="$ar_location" \
        --project="$GCP_PROJECT_ID" \
        --description="Confidential Space workload images" \
        --quiet
    echo "[INFO]  Repository created."
fi

echo ""
echo "======================================"
echo "  Setup complete!"
echo "======================================"
print_config
