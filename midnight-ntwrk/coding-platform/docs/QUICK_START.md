# Midnight Development Platform - Quick Start Guide

## Overview
Get started with Midnight Network DApp development in under 10 minutes using cloud-based development environments.

## Prerequisites
- Google Cloud Platform account
- `gcloud` CLI installed and configured
- Terraform 1.5+
- Basic knowledge of smart contracts

## Step 1: Deploy Infrastructure (5 minutes)

### 1.1 Clone the Repository
```bash
git clone https://github.com/midnight-network/cloud-platform
cd cloud-platform
```

### 1.2 Configure GCP Project
```bash
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID
```

### 1.3 Enable Required APIs
```bash
gcloud services enable \
  compute.googleapis.com \
  workstations.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com
```

### 1.4 Deploy with Terraform
```bash
cd terraform
terraform init
terraform plan -var="project_id=$PROJECT_ID"
terraform apply -var="project_id=$PROJECT_ID" -auto-approve
```

## Step 2: Build and Push Container Image (3 minutes)

### 2.1 Build Container Image
```bash
# The build script auto-detects podman or docker
./scripts/build.sh
```

### 2.2 Push to Artifact Registry
```bash
# Push script handles authentication and registry URL
./scripts/push.sh
```

## Step 3: Access Your Workstation (2 minutes)

### 3.1 Get Workstation URL
```bash
WORKSTATION_URL=$(terraform -chdir=../terraform output -raw workstation_url)
echo "Access your workstation at: $WORKSTATION_URL"
```

### 3.2 Open in Browser
Navigate to the workstation URL in your browser. You'll have access to:
- VS Code (Code OSS) IDE
- Pre-installed Midnight tools
- Sample DApp template
- Integrated terminal

## Step 4: Create Your First DApp

### 4.1 Open Terminal in IDE
Once in the IDE, open a new terminal (Terminal → New Terminal)

### 4.2 Create New Project

#### Option A: Using Midnight CLI
```bash
midnight new my-first-dapp
cd /workspace/projects/my-first-dapp
```

#### Option B: Using OpenCode AI Assistant
```bash
# Launch OpenCode TUI
opencode

# Ask the AI to help you:
# - "Create a new Midnight DApp project"
# - "Help me write a token contract"
# - "Explain how to use zero-knowledge proofs"
# - "Debug my smart contract"
```

### 4.3 Compile Contract
```bash
midnight compile
# or
make compile
```

### 4.4 Run Tests
```bash
midnight test
# or
npm test
```

### 4.5 Generate Proofs
```bash
midnight prove
# or
make prove
```

### 4.6 Deploy to Testnet
```bash
midnight deploy
# or
make deploy
```

## Step 5: Access Your DApp

### 5.1 Start Development Server
```bash
npm run dev
# or
make dev
```

### 5.2 Open DApp Interface
Navigate to `http://localhost:3000` in the workstation's browser

## Common Commands

| Command | Description |
|---------|-------------|
| `midnight new <name>` | Create new DApp project |
| `midnight compile` | Compile Compact contracts |
| `midnight test` | Run contract tests |
| `midnight prove` | Generate ZK proofs |
| `midnight deploy` | Deploy to testnet |
| `make help` | Show all available make commands |

## Troubleshooting

### Workstation Won't Start
```bash
# Check cluster status
gcloud workstations clusters describe midnight-mvp-cluster \
  --region=us-central1

# Restart workstation
gcloud workstations start midnight-developer-1 \
  --cluster=midnight-mvp-cluster \
  --config=midnight-mvp-config \
  --region=us-central1
```

### Compilation Errors
```bash
# Check compiler version
compactc --version

# Validate contract syntax
compactc --check contracts/Token.compact
```

### Proof Service Issues
```bash
# Check service health
curl http://localhost:8080/health

# Restart proof service
supervisorctl restart proof-service
```

## Next Steps

1. **Explore Templates**: Check `/workspace/templates` for more examples
2. **Read Documentation**: Full docs at `/workspace/docs`
3. **Join Community**: Discord, Forum, GitHub Discussions
4. **Deploy to Mainnet**: Upgrade to production configuration

## Support

- Documentation: [docs.midnight.network](https://docs.midnight.network)
- GitHub Issues: [github.com/midnight-network/issues](https://github.com/midnight-network/issues)
- Discord: [discord.gg/midnight](https://discord.gg/midnight)
- Email: support@midnight.network