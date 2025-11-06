#!/bin/bash
set -e

echo "📋 Showing local service logs..."
cd cicd
podman-compose logs -f