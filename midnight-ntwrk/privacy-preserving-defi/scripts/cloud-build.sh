#!/bin/bash
set -e

echo "☁️  Building and pushing application via Cloud Build..."
gcloud builds submit --config=cicd/cloudbuild-app.yaml .