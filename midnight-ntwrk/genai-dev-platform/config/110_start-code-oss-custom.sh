#!/bin/bash
# Override Code OSS startup to use port 8080
echo "🌙 Starting Code OSS on port 8080 for Midnight Vibe Platform..."

# Kill any existing Code OSS processes
pkill -f "codeoss-cloudworkstations" || true
sleep 2

# Start Code OSS on port 8080 as user
cd /opt/code-oss
sudo -u user /opt/code-oss/bin/codeoss-cloudworkstations --port=8080 --host=0.0.0.0 &

echo "✅ Code OSS started on port 8080"