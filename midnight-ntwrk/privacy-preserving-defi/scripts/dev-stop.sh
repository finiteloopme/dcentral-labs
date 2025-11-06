#!/bin/bash
set -e

echo "🛑 Stopping local development services..."
cd cicd
podman-compose down

pkill -f "python3 -m http.server" || true
pkill -f "cargo run" || true

echo "✅ Local services stopped!"