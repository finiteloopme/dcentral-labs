---
name: gcloud-ops
description: Google Cloud Platform operations patterns and best practices
---

## What I do

- Guide GCP resource management with gcloud CLI
- Document IAM best practices and least-privilege patterns
- Provide common operational workflows for Compute, GKE, and Cloud Run
- Cover logging and monitoring patterns

## When to use me

Use this skill when managing Google Cloud resources, setting up GCP
infrastructure, troubleshooting GCP services, or configuring IAM policies.

## Authentication

```bash
# Login interactively
gcloud auth login

# Login with service account
gcloud auth activate-service-account --key-file=key.json

# Application default credentials (for Terraform, SDKs)
gcloud auth application-default login

# Check current auth
gcloud auth list
gcloud config get-value account
```

## Project & Config

```bash
# Set project
gcloud config set project PROJECT_ID

# Set region/zone
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

# View all config
gcloud config list

# Named configurations (for multiple projects)
gcloud config configurations create staging
gcloud config configurations activate staging
gcloud config set project my-staging-project
```

## Compute Engine

```bash
# List instances
gcloud compute instances list

# Create instance
gcloud compute instances create my-vm \
  --machine-type=e2-medium \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB

# SSH into instance
gcloud compute ssh my-vm --zone=us-central1-a

# Stop / Start / Delete
gcloud compute instances stop my-vm
gcloud compute instances start my-vm
gcloud compute instances delete my-vm
```

## GKE (Google Kubernetes Engine)

```bash
# Create cluster
gcloud container clusters create my-cluster \
  --num-nodes=3 \
  --machine-type=e2-standard-4 \
  --region=us-central1

# Get credentials (configure kubectl)
gcloud container clusters get-credentials my-cluster --region=us-central1

# List clusters
gcloud container clusters list

# Resize
gcloud container clusters resize my-cluster --num-nodes=5 --region=us-central1

# Delete cluster
gcloud container clusters delete my-cluster --region=us-central1
```

## Cloud Run

```bash
# Deploy from container image
gcloud run deploy my-service \
  --image=gcr.io/PROJECT/image:tag \
  --region=us-central1 \
  --allow-unauthenticated

# Deploy from source
gcloud run deploy my-service --source=. --region=us-central1

# List services
gcloud run services list

# View logs
gcloud run services logs read my-service --region=us-central1

# Delete service
gcloud run services delete my-service --region=us-central1
```

## IAM Best Practices

### Principle of least privilege
- Grant the minimum permissions needed for the task
- Use predefined roles over primitive roles (Owner/Editor/Viewer)
- Use custom roles for fine-grained access

### Common operations
```bash
# View project IAM policy
gcloud projects get-iam-policy PROJECT_ID

# Grant a role
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=user:alice@example.com \
  --role=roles/compute.viewer

# Revoke a role
gcloud projects remove-iam-policy-binding PROJECT_ID \
  --member=user:alice@example.com \
  --role=roles/compute.viewer

# List service accounts
gcloud iam service-accounts list
```

### Recommended roles by task

| Task | Role |
|------|------|
| View resources | `roles/viewer` |
| Deploy Cloud Run | `roles/run.developer` |
| Manage GKE | `roles/container.clusterAdmin` |
| Manage Compute | `roles/compute.instanceAdmin.v1` |
| Manage Storage | `roles/storage.admin` |
| View logs | `roles/logging.viewer` |

## Logging & Monitoring

```bash
# Read recent logs
gcloud logging read "resource.type=gce_instance" --limit=20

# Read logs with severity filter
gcloud logging read "severity>=ERROR" --freshness=1h

# Read logs for a specific resource
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="my-service"'

# Tail logs (stream)
gcloud logging tail "resource.type=gce_instance"
```

## Cost Management

- Use `e2-` machine types for cost-effective general workloads
- Enable committed use discounts for predictable workloads
- Use preemptible/spot VMs for fault-tolerant batch workloads
- Set up budget alerts: `gcloud billing budgets create ...`
- Review recommendations: `gcloud recommender recommendations list ...`

## Terraform with GCP

When using Terraform with Google Cloud:

```hcl
provider "google" {
  project = "my-project"
  region  = "us-central1"
}
```

- Use `google_project_service` to enable APIs declaratively
- Use `terraform import` to bring existing resources under management
- Store state in a GCS backend: `terraform { backend "gcs" { bucket = "..." } }`
- Use workspaces for environment separation (dev/staging/prod)

## Agent Integration

- NEVER modify IAM policies without showing the diff and getting user
  confirmation.
- ALWAYS show what will change before executing destructive GCP operations.
