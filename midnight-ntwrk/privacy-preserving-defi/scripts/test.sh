#!/bin/bash
set -e

echo "🧪 Running tests..."
cd contracts
forge test

cd ../tee-service
cargo test

echo "✅ Tests completed!"