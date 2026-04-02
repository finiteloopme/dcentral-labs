#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/common.sh"

# Detect and use the appropriate compose command
if [ -z "${COMPOSE_CMD:-}" ]; then
    COMPOSE_CMD=$(detect_compose_command)
fi

# Forward all arguments to docker-compose with the correct file path
exec $COMPOSE_CMD -f "$PROJECT_ROOT/oci/docker-compose.yml" "$@"