# Helix Relay Benchmark Suite (GCP)

This repository contains infrastructure-as-code to deploy two competing architectures for the Helix MEV Relay:
1. **The Monolith**: Single C2-standard-16 VM with Local SSD (Dockerized).
2. **The Cloud Native**: GKE (C2 Nodes) + Cloud SQL Enterprise Plus + Memorystore Redis.

## Prerequisites
- Google Cloud SDK (`gcloud`) installed and authenticated.
- `make` installed.
- A GCP Project.

## Quick Start

1. **Initialize Environment**
   Enables Cloud Build and creates a GCS bucket for Terraform state.
   ```bash
   make setup
   ```

2. **Deploy Infrastructure**
   Triggers a remote build to provision all resources.
   ```bash
   make deploy
   ```

3. **Run Benchmarks**
   SSH into the `attacker-vm` created by the script to launch loads against the internal IPs.
