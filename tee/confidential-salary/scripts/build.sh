#!/bin/bash

set -e

echo "========================================="
echo "Building Confidential Salary Analyzer"
echo "========================================="

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "→ Building shared library..."
cd shared
cargo build --release
cd ..

echo "→ Building server application..."
cd server
cargo build --release
cd ..

echo "→ Building client application..."
cd client
cargo build --release
cd ..

echo ""
echo "✓ Build completed successfully!"
echo ""
echo "Binaries located at:"
echo "  - Server: target/release/server"
echo "  - Client: target/release/client"
echo ""