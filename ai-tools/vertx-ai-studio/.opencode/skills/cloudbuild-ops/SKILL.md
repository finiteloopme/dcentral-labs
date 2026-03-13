---
name: cloudbuild-ops
description: Cloud Build CI/CD patterns with Terraform-via-Cloud-Build workflows
---

## What I do

- Guide `cloudbuild.yaml` authoring and step configuration
- Document the Terraform-via-Cloud-Build pattern (plan on PR, apply on merge)
- Define the `cicd/` directory layout conventions
- Cover trigger types, substitution variables, and security practices

## When to use me

Use this skill when setting up CI/CD pipelines with Cloud Build, when
configuring Terraform to run inside Cloud Build, or when troubleshooting
build failures.

## `cicd/` Directory Layout

```
cicd/
  Dockerfile                  # Application container build
  .dockerignore               # Build context exclusions
  cloudbuild.yaml             # Main pipeline: build image + push to AR
  cloudbuild-plan.yaml        # Terraform plan (triggered by PR)
  cloudbuild-apply.yaml       # Terraform apply (triggered by merge)
  terraform/
    providers.tf              # Google provider + required version
    backend.tf                # GCS state backend
    variables.tf              # Input variables (project_id, region, etc.)
    main.tf                   # GCP resources (AR repo, Cloud Run, IAM)
    outputs.tf                # Output values (service URL, repo URL)
```

## `cloudbuild.yaml` Structure

A Cloud Build config defines a sequence of steps:

```yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'   # Builder image
    args: ['build', '-t', '${_IMAGE}', '.'] # Command and arguments
    dir: '.'                                 # Working directory (optional)
    env: ['KEY=VALUE']                       # Environment variables (optional)

images: ['${_IMAGE}']                        # Images to push after build

substitutions:
  _IMAGE: 'us-central1-docker.pkg.dev/${PROJECT_ID}/app/app:latest'

options:
  logging: CLOUD_LOGGING_ONLY
```

### Key concepts

| Concept | Description |
|---------|-------------|
| `steps` | Ordered list of build steps. Each runs in its own container. |
| `name` | Docker image for the step. Use `gcr.io/cloud-builders/*` or any public image. |
| `args` | Command-line arguments (the image's ENTRYPOINT receives these). |
| `dir` | Working directory relative to the source root. |
| `images` | Images to push to a registry after all steps complete. |
| `substitutions` | User-defined variables prefixed with `_`. Also `$PROJECT_ID`, `$BUILD_ID`, etc. |

### Built-in substitutions

| Variable | Description |
|----------|-------------|
| `$PROJECT_ID` | GCP project ID |
| `$BUILD_ID` | Unique build identifier |
| `$COMMIT_SHA` | Git commit SHA (when triggered by repo) |
| `$BRANCH_NAME` | Git branch name |
| `$TAG_NAME` | Git tag name |
| `$SHORT_SHA` | First 7 chars of commit SHA |

## Terraform via Cloud Build

The core pattern: **Terraform never runs locally.** Cloud Build is the
execution environment for all infrastructure changes.

### Two-pipeline Model

**Pipeline 1: Plan (PR trigger)**
- Triggered when a pull request is opened or updated
- Runs `terraform init` + `terraform plan`
- Outputs the plan for review (visible in build logs)
- Does NOT apply changes

**Pipeline 2: Apply (Merge trigger)**
- Triggered when a PR is merged to the default branch
- Runs `terraform init` + `terraform apply -auto-approve`
- Applies the reviewed changes
- Can also run `terraform destroy` via substitution override

### Configuration

```yaml
# cloudbuild-plan.yaml
steps:
  - name: 'hashicorp/terraform:1.7'
    dir: 'cicd/terraform'
    args: ['init', '-backend-config=bucket=${_TF_STATE_BUCKET}']
    env: ['TF_IN_AUTOMATION=true']

  - name: 'hashicorp/terraform:1.7'
    dir: 'cicd/terraform'
    args: ['plan', '-no-color', '-input=false']
    env:
      - 'TF_IN_AUTOMATION=true'
      - 'TF_VAR_project_id=${PROJECT_ID}'
```

### State Backend

Terraform state is stored in GCS:

```hcl
terraform {
  backend "gcs" {
    # bucket and prefix set via -backend-config flags in cloudbuild YAML
  }
}
```

The bucket name is passed as a substitution: `_TF_STATE_BUCKET`.
Convention: `${PROJECT_ID}-tfstate` with prefix matching the service name.

### Service Account Permissions

The Cloud Build service account (`<project-number>@cloudbuild.gserviceaccount.com`)
needs these roles:

| Role | Purpose |
|------|---------|
| `roles/artifactregistry.admin` | Push images to Artifact Registry |
| `roles/run.admin` | Deploy Cloud Run services |
| `roles/iam.serviceAccountUser` | Act as the service account |
| `roles/storage.admin` | Read/write Terraform state in GCS |

Grant via:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:<number>@cloudbuild.gserviceaccount.com" \
  --role="roles/run.admin"
```

## Trigger Types

### Push trigger
Fires on push to a branch matching a pattern:

```bash
gcloud builds triggers create github \
  --repo-name=my-repo --repo-owner=my-org \
  --branch-pattern="^main$" \
  --build-config=cicd/cloudbuild-apply.yaml
```

### Pull request trigger
Fires on PR creation or update:

```bash
gcloud builds triggers create github \
  --repo-name=my-repo --repo-owner=my-org \
  --pull-request-pattern="^main$" \
  --build-config=cicd/cloudbuild-plan.yaml
```

### Manual trigger
Run on demand:

```bash
gcloud builds triggers run TRIGGER_ID --branch=main
```

## Security Best Practices

1. **Never put secrets in `cloudbuild.yaml`** -- Use Secret Manager:
   ```yaml
   availableSecrets:
     secretManager:
       - versionName: projects/$PROJECT_ID/secrets/my-secret/versions/latest
         env: 'MY_SECRET'
   ```

2. **Least-privilege service account** -- Only grant the roles the build needs.

3. **Pin builder image versions** -- Use `hashicorp/terraform:1.7` not
   `hashicorp/terraform:latest`.

4. **Set `TF_IN_AUTOMATION=true`** -- Suppresses interactive prompts and
   produces cleaner output.

5. **Use `-input=false`** -- Prevent Terraform from waiting for user input
   in a non-interactive environment.

6. **Review plans before apply** -- The two-pipeline model ensures a human
   reviews the plan (in PR logs) before apply runs.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Build fails with auth error | Check service account roles |
| Terraform state locked | Run `terraform force-unlock LOCK_ID` via Cloud Build |
| Image push fails | Verify Artifact Registry repo exists and SA has `artifactregistry.admin` |
| Substitution not resolved | Ensure variable starts with `_` and is declared in `substitutions` |
| Build timeout | Increase `timeout` in `options` (default: 10 minutes) |

## Agent Integration

- Terraform runs via Cloud Build, not locally. Cloud Build is the execution
  environment for all infrastructure changes.
- Cloud Build configs and Terraform modules live in `cicd/`.
- NEVER run `terraform apply` or `terraform destroy` without first showing
  the plan output and getting user confirmation.
- NEVER submit Cloud Build jobs that run `terraform apply` without user
  confirmation.
- ALWAYS show plan output before any apply operation.
