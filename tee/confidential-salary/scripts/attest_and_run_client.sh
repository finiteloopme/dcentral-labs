#!/bin/bash

set -e

echo "========================================="
echo "Confidential Salary Client"
echo "========================================="

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f "client/target/release/client" ]; then
    echo "Client binary not found. Building..."
    ./scripts/build.sh
fi

SERVER_URL="${SERVER_URL:-http://localhost:8080}"
MODE="${1:-demo}"

echo "→ Server URL: $SERVER_URL"
echo "→ Mode: $MODE"
echo ""

cd client

case "$MODE" in
    demo)
        echo "Running demo mode..."
        ./target/release/client --server "$SERVER_URL" demo
        ;;
    interactive)
        echo "Running interactive mode..."
        ./target/release/client --server "$SERVER_URL" interactive
        ;;
    health)
        echo "Checking server health..."
        ./target/release/client --server "$SERVER_URL" health
        ;;
    submit)
        shift
        echo "Submitting salary data..."
        ./target/release/client --server "$SERVER_URL" submit "$@"
        ;;
    *)
        echo "Usage: $0 [demo|interactive|health|submit]"
        echo ""
        echo "Modes:"
        echo "  demo        - Run a demonstration with sample data"
        echo "  interactive - Interactive mode with prompts"
        echo "  health      - Check server health status"
        echo "  submit      - Submit salary data (use --help for options)"
        echo ""
        echo "Environment variables:"
        echo "  SERVER_URL  - Server URL (default: http://localhost:8080)"
        exit 1
        ;;
esac