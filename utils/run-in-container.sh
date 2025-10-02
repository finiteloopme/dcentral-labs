#!/bin/bash

# ==============================================================================
# run-in-container.sh
#
# A helper script to execute commands within a specified container environment.
# It mounts the current working directory into the container, allowing the
# command to act on local files.
#
# This script is modular and supports multiple container runtimes.
#
# Usage:
#   ./run-in-container.sh [options] <container_type> [command_to_run...]
#
# Options:
#   --runtime <runtime>   : Specify the container runtime (e.g., podman, docker). Defaults to podman.
#   --add <type> <image>  : Add or update a container image in ~/.utils/images.yaml.
#
# Examples:
#   # Run 'go version' in a Golang container using podman
#   ./run-in-container.sh golang go version
#
#   # Run 'npm install' in a Node.js container using docker
#   ./run-in-container.sh --runtime docker node npm install
#
#   # Add a new bitcore container image
#   ./run-in-container.sh --add bitcore bitcore/bitcore
#
#   # Get an interactive shell in a Debian container
#   ./run-in-container.sh debian
# ==============================================================================

# --- Configuration ---
UTILS_DIR="$HOME/.utils"
IMAGES_FILE="$UTILS_DIR/images.yaml"
DEFAULT_RUNTIME="podman"

# --- Default Images ---
# These are used if the images.yaml file is not found.
read -r -d '' DEFAULT_IMAGES << EOM
golang: docker.io/library/golang:latest
rust: docker.io/library/rust:latest
python: docker.io/library/python:latest
node: docker.io/library/node:latest
debian: docker.io/library/debian:latest
gcloud: gcr.io/google.com/cloudsdktool/google-cloud-cli:latest
forge: ghcr.io/foundry-rs/foundry:latest
podman: quay.io/podman/stable
EOM

# --- Helper Functions ---

# Prints usage information and exits.
usage() {
  echo "Usage: $0 [options] <container_type> [command...]"
  echo ""
  echo "A wrapper script to run commands in a containerized environment."
  echo ""
  echo "Options:"
  echo "  --runtime <runtime>   : Specify the container runtime (e.g., podman, docker). Defaults to ${DEFAULT_RUNTIME}."
  echo "  --add <type> <image>  : Add or update a container image in ${IMAGES_FILE}."
  echo ""
  echo "Available container types:"
  if [ -f "$IMAGES_FILE" ]; then
    echo " (from ${IMAGES_FILE}):"
    grep -o '^[a-zA-Z0-9_-]*:' "$IMAGES_FILE" | sed 's/://' | awk '{printf "  %-20s\\n", $1}'
  else
    echo " (default):"
    echo "$DEFAULT_IMAGES" | grep -o '^[a-zA-Z0-9_-]*:' | sed 's/://' | awk '{printf "  %-20s\\n", $1}'
  fi
  echo ""
  echo "If no command is provided, the script will start an interactive shell ('bash') inside the container."
  exit 1
}

# Adds or updates a container image in the images.yaml file.
add_or_update_image() {
  local type="$1"
  local image="$2"

  if [ -z "$type" ] || [ -z "$image" ]; then
    echo "Error: Both container type and image must be specified."
    usage
  fi

  # Create the utils directory if it doesn't exist
  mkdir -p "$UTILS_DIR"

  # Create the images file if it doesn't exist
  if [ ! -f "$IMAGES_FILE" ]; then
    touch "$IMAGES_FILE"
  fi

  # Check if the container type already exists
  if grep -q "^$type:" "$IMAGES_FILE"; then
    # Update existing entry
    sed -i "s|^$type:.*|$type: $image|" "$IMAGES_FILE"
    echo "Updated container type '$type' in $IMAGES_FILE."
  else
    # Add new entry
    echo "$type: $image" >> "$IMAGES_FILE"
    echo "Added new container type '$type' to $IMAGES_FILE."
  fi
  exit 0
}

# Retrieves the container image URL.
# It first checks the images.yaml file, then falls back to the default images.
get_container_image() {
  local type="$1"
  local image=""

  if [ -f "$IMAGES_FILE" ]; then
    image=$(grep "^$type:" "$IMAGES_FILE" | sed 's/^[a-zA-Z0-9_-]*: //')
  fi

  if [ -z "$image" ]; then
    image=$(echo "$DEFAULT_IMAGES" | grep "^$type:" | sed 's/^[a-zA-Z0-9_-]*: //')
  fi

  echo "$image"
}

# --- Main Script Logic ---

RUNTIME="$DEFAULT_RUNTIME"

# Parse command-line arguments
while [[ "$1" =~ ^- ]]; do
  case "$1" in
    --runtime)
      RUNTIME="$2"
      shift 2
      ;;
    --add)
      add_or_update_image "$2" "$3"
      ;;
    *)
      usage
      ;;
  esac
done

# Capture the user's current working directory
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
if [ -z "$CONTAINER_IMAGE" ]; then
  echo "Error: Unknown container type '$CONTAINER_TYPE'."
  usage
fi

# If no command is provided, default to an interactive bash shell
if [ "$#" -eq 0 ]; then
  set -- "bash"
fi

# --- Execution ---
echo "Container Runtime: $RUNTIME"
echo "Container:         $CONTAINER_TYPE ($CONTAINER_IMAGE)"
[ -n "$EXTRA_ARGS" ] && echo "Extra args:        $EXTRA_ARGS"
echo "Command:           $@"
echo "------------------------------------------------------------------------------"

# Execute the command using the selected container runtime
case "$RUNTIME" in
  podman)
    # The EXTRA_PODMAN_ARGS variable is intentionally not quoted to allow for word splitting.
    exec podman run \
      --rm \
      -it \
      -v "$USER_CWD:$USER_CWD" \
      -w "$USER_CWD" \
      --security-opt label=disable \
      $EXTRA_PODMAN_ARGS \
      "$CONTAINER_IMAGE" \
      "$@"
    ;;
  docker)
    # The EXTRA_DOCKER_ARGS variable is intentionally not quoted to allow for word splitting.
    exec docker run \
      --rm \
      -it \
      -v "$USER_CWD:$USER_CWD" \
      -w "$USER_CWD" \
      $EXTRA_DOCKER_ARGS \
      "$CONTAINER_IMAGE" \
      "$@"
    ;;
  *)
    echo "Error: Unsupported container runtime '$RUNTIME'."
    exit 1
    ;;
esac
