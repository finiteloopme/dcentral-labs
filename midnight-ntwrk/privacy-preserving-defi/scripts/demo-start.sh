#!/bin/bash
set -e

echo "🚀 Starting production demo services..."
cd cicd
podman-compose -f docker-compose.prod.yml up -d
sleep 15

echo "🌐 Starting frontend..."
cd ../frontend
python3 -m http.server 3000 > ../logs/frontend.log 2>&1 &

echo "✅ Production demo services started!"
echo "  Frontend: http://localhost:3000"
echo "  TEE Service: http://localhost:8080 (Production Mode)"
echo "  Arc RPC: http://localhost:8545"
echo "  Proof Server: http://localhost:6300"
echo ""
echo "🔐 ZK proofs are now generated using the real Midnight proof server!"
echo "📊 Monitor logs with: make dev-logs"