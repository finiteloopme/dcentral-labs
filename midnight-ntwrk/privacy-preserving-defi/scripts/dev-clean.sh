#!/bin/bash
set -e

echo "🧹 Cleaning local development resources..."
cd cicd
podman-compose down -v
podman system prune -f

rm -rf ../logs/*

echo "✅ Local resources cleaned!"