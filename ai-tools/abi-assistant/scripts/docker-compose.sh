#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Forward all arguments to docker-compose with the correct file path
exec docker-compose -f "$PROJECT_ROOT/oci/docker-compose.yml" "$@"