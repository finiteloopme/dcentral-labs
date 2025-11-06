#!/bin/bash
set -e

echo "🗑️  Destroying Privacy-Preserving DeFi Cloud Infrastructure..."

# Destroy infrastructure via Cloud Build
echo "Destroying infrastructure..."
gcloud builds submit --config=cicd/cloudbuild-destroy.yaml .

echo "✅ Infrastructure destroyed!"