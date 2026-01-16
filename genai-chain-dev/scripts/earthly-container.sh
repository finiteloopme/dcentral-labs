#!/usr/bin/env bash
#
# Run Earthly via container - no local installation required
#
# Usage:
#   ./scripts/earthly-container.sh [workdir] <earthly args>
#   ./scripts/earthly-container.sh chains/somnia -P +dev
#   ./scripts/earthly-container.sh -P +dev  # runs from repo root
#
# This script wraps Earthly in a container, allowing builds without
# installing Earthly locally. Requires Podman.
#
# The entire repository is mounted at /workspace, with the working
# directory set to the specified subdirectory. This allows Earthfile
# IMPORT statements to resolve correctly.
#
# Cache is persisted to ~/.earthly for faster rebuilds.
# Podman socket is mounted to allow image export to host.

set -euo pipefail

EARTHLY_VERSION="v0.8.15"
EARTHLY_IMAGE="earthly/earthly:${EARTHLY_VERSION}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Ensure podman is available
if ! command -v podman &>/dev/null; then
    echo "Error: podman is required but not installed" >&2
    exit 1
fi

# First arg is workdir if it's a directory path, otherwise use repo root
CONTAINER_WORKDIR="/workspace"
if [[ $# -gt 0 && -d "${REPO_ROOT}/$1" ]]; then
    CONTAINER_WORKDIR="/workspace/$1"
    shift
fi

# Create cache directory if it doesn't exist
mkdir -p "${HOME}/.earthly"

# Detect Podman socket path for image export to host
PODMAN_SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
SOCKET_MOUNT=""
if [[ -S "${PODMAN_SOCKET}" ]]; then
    SOCKET_MOUNT="-v ${PODMAN_SOCKET}:/var/run/docker.sock"
    echo "Podman socket detected - images will be exported to host"
else
    echo "Warning: Podman socket not found at ${PODMAN_SOCKET}"
    echo "Images will NOT be exported to host. Start socket with:"
    echo "  systemctl --user start podman.socket"
fi

# shellcheck disable=SC2086
exec podman run --rm --privileged \
    --hostname earthly-buildkitd \
    -v "${REPO_ROOT}:/workspace" \
    -v "${HOME}/.earthly:/root/.earthly" \
    -v earthly-tmp:/tmp/earthly:rw \
    ${SOCKET_MOUNT} \
    -w "${CONTAINER_WORKDIR}" \
    -e EARTHLY_BUILDKIT_TLS_ENABLED=false \
    "${EARTHLY_IMAGE}" "$@"
