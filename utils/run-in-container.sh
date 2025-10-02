#!/bin/bash

# ==============================================================================
# run-in-container.sh
#
# A helper script to execute commands within a specified container environment
# using Podman. It mounts the current working directory into the container,
# allowing the command to act on local files.
#
# Usage:
#   ./run-in-container.sh <container_type> [command_to_run...]
#
# Examples:
#   # Run 'go version' in a Golang container
#   ./run-in-container.sh golang go version
#
#   # Run 'npm install' in a Node.js container
#   ./run-in-container.sh node npm install
#
#   # Get an interactive shell in a Debian container
#   ./run-in-container.sh debian
#
#   # Run forge build in a Paradigm Forge container
#   ./run-in-container.sh forge forge build
# ==============================================================================

# --- Configuration: Define Container Images ---
# This section maps a short name (e.g., 'golang') to a full container image URL.
# Add or modify images here as needed.

get_container_image() {
  case "$1" in
    golang)
      echo "docker.io/library/golang:latest"
      ;;
    rust)
      echo "docker.io/library/rust:latest"
      ;;
    python)
      echo "docker.io/library/python:latest"
      ;;
    node)
      echo "docker.io/library/node:latest"
      ;;
    debian)
      echo "docker.io/library/debian:latest"
      ;;
    gcloud)
      # Google Cloud CLI
      echo "gcr.io/google.com/cloudsdktool/google-cloud-cli:latest"
      ;;
    forge)
      # Paradigm's Foundry development environment for Solidity
      echo "ghcr.io/foundry-rs/foundry:latest"
      ;;
    podman)
      # Includes the Podman client for building images
      echo "quay.io/podman/stable"
      ;;
    *)
      return 1
      ;;
  esac
}

# --- Helper Functions ---

# Prints usage information and exits.
usage() {
  echo "Usage: $0 <container_type> [command...]"
  echo ""
  echo "A wrapper script to run commands in a containerized environment using Podman."
  echo ""
  echo "Available container types:"
  echo "  golang   - For Go development"
  echo "  rust     - For Rust development"
  echo "  python   - For Python development"
  echo "  node     - For Node.js/JavaScript development"
  echo "  debian   - A general-purpose Debian environment"
  echo "  gcloud   - For Google Cloud CLI commands"
  echo "  forge    - For Paradigm's Foundry (Solidity development)"
  echo "  podman   - For building container images"
  echo ""
  echo "If no command is provided, the script will start an interactive shell ('bash') inside the container."
  exit 1
}

# --- Main Script Logic ---

# Capture the user's current working directory at the time of execution.
# This ensures that all operations are relative to where the user is,
# not where the script is located.
USER_CWD="$PWD"

# Check for minimum required arguments
if [ "$#" -lt 1 ]; then
  echo "Error: No container type specified."
  usage
fi

CONTAINER_TYPE="$1"
shift # Consume the container_type argument

# Retrieve the container image URL
CONTAINER_IMAGE=$(get_container_image "$CONTAINER_TYPE")
if [ $? -ne 0 ]; then
  echo "Error: Unknown container type '$CONTAINER_TYPE'."
  usage
fi

# If no command is provided, default to an interactive bash shell
if [ "$#" -eq 0 ]; then
  set -- "bash" # Set the command to "bash"
fi

# --- Execution ---
# Run the command in the specified container.
#
# This script supports passing extra arguments to Podman via the
# EXTRA_PODMAN_ARGS environment variable. This is useful for advanced
# configurations, such as mounting persistent cache directories.
#
# Example for Rust build caching:
#   export EXTRA_PODMAN_ARGS="-v $HOME/.cargo/registry:/usr/local/cargo/registry -v $HOME/.cargo/git:/usr/local/cargo/git"
#   ./run-in-container.sh rust cargo build
#
# Podman Flags:
#   --rm          : Automatically remove the container when it exits.
#   -it           : Allocate a pseudo-TTY and keep STDIN open.
#   -v "$USER_CWD:$USER_CWD": Mount the current directory into the container at the same path.
#   -w "$USER_CWD"     : Set the working directory inside the container.
#   --security-opt label=disable: Disable SELinux separation, often needed for volume mounts.
#
echo "Container:  $CONTAINER_TYPE ($CONTAINER_IMAGE)"
[ -n "$EXTRA_PODMAN_ARGS" ] && echo "Extra args: $EXTRA_PODMAN_ARGS"
echo "Command:    $@"
echo "------------------------------------------------------------------------------"

# The EXTRA_PODMAN_ARGS variable is intentionally not quoted to allow for word splitting.
# This lets you pass multiple arguments like: EXTRA_PODMAN_ARGS="-v /path1:/path1 -v /path2:/path2"
exec podman run \
  --rm \
  -it \
  -v "$USER_CWD:$USER_CWD" \
  -w "$USER_CWD" \
  --security-opt label=disable \
  $EXTRA_PODMAN_ARGS \
  "$CONTAINER_IMAGE" \
  "$@"
