#!/bin/bash
set -e

echo "🚀 Starting local development services..."
cd cicd
podman-compose up -d anvil proof-server
sleep 10

echo "🌐 Starting frontend..."
cd ../frontend
python3 -m http.server 3000 > ../logs/frontend.log 2>&1 &

echo "🔧 Starting TEE service..."
cd ../tee-service
nohup cargo run > ../logs/tee-service.log 2>&1 &

echo "✅ Local services started!"
echo "  Frontend: http://localhost:3000"
echo "  TEE Service: http://localhost:8080"
echo "  Arc RPC: http://localhost:8545"
echo "  Proof Server: http://localhost:6300"