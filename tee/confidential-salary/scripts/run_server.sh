#!/bin/bash

set -e

echo "========================================="
echo "Starting Confidential Salary Server"
echo "========================================="

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f "server/target/release/server" ]; then
    echo "Server binary not found. Building..."
    ./scripts/build.sh
fi

export RUST_LOG=server=info,warp=info

if [ "$1" == "--tdx" ] || [ "$TDX_ENABLED" == "1" ]; then
    echo "→ Running in TDX mode (if available)"
    export TDX_ENABLED=1
else
    echo "→ Running in simulation mode"
    echo "  To enable TDX mode, run with --tdx flag or set TDX_ENABLED=1"
fi

echo ""
echo "→ Starting server on port 8080..."
echo ""

cd server
exec ./target/release/server