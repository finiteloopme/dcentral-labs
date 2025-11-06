#!/bin/bash
set -e

echo "☁️  Deploying Privacy-Preserving DeFi to Cloud via Cloud Build..."

# Build and push TEE service image
echo "Building and pushing TEE service image..."
gcloud builds submit --config=cicd/cloudbuild-app.yaml .

echo "✅ Application deployment complete!"
echo ""
echo "🌐 To deploy infrastructure, run:"
echo "  gcloud builds submit --config=cicd/cloudbuild-infra.yaml ."
echo ""
echo "🔧 To deploy both app and infrastructure:"
echo "  gcloud builds submit --config=cicd/cloudbuild-app.yaml . && gcloud builds submit --config=cicd/cloudbuild-infra.yaml ."