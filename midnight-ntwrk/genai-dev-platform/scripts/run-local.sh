#!/bin/bash

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ==============================================================================
# Usage
# ==============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run the Midnight development container in privileged mode using Podman.

Options:
    -n, --name NAME           Image name (default: $DEFAULT_IMAGE_NAME)
    -t, --tag TAG             Image tag (default: $DEFAULT_IMAGE_TAG)
    -c, --container NAME      Container name (default: $DEFAULT_CONTAINER_NAME)
    -d, --detach              Run container in detached mode
    -v, --volume PATH         Mount additional volume (can be used multiple times)
    -p, --port PORT           Expose additional port (can be used multiple times)
    --shell SHELL             Shell to use (default: /bin/bash)
    --rm                      Remove container after exit (default for interactive)
    -h, --help                Show this help message

Environment Variables:
    IMAGE_NAME                Override default image name
    IMAGE_TAG                 Override default image tag
    CONTAINER_NAME            Override default container name

Examples:
    $(basename "$0")                              # Run interactively
    $(basename "$0") -d                           # Run detached
    $(basename "$0") -v \$(pwd):/workspace        # Mount current dir
    $(basename "$0") -p 8080:8080                 # Expose port 8080
EOF
}

# ==============================================================================
# Run Function
# ==============================================================================

run_container() {
    local image_name="$1"
    local image_tag="$2"
    local container_name="$3"
    local detach="$4"
    local shell="$5"
    local auto_rm="$6"
    shift 6
    local extra_args=("$@")

    local full_image
    full_image="$(get_full_image "$image_name" "$image_tag")"

    require_image "$full_image"

    local run_args=(
        "--privileged"
        "--network" "host"
        "--name" "$container_name"
        "-e" "EDITOR_PORT=8080"
    )

    # Note: With --network host, port mappings are not needed.
    # Services bind directly to host ports:
    #   - 8080:  Code OSS web server
    #   - 9944:  Node WebSocket
    #   - 6300:  Proof Server
    #   - 8081:  Indexer
    #   - 5432:  PostgreSQL

    # Add extra arguments (volumes, ports, etc.)
    if [[ ${#extra_args[@]} -gt 0 ]]; then
        run_args+=("${extra_args[@]}")
    fi

    if [[ "$detach" == "true" ]]; then
        run_args+=("-d")
        log_launch "Starting container in detached mode: $container_name"
        
        if podman run "${run_args[@]}" "$full_image"; then
            echo ""
            log_success "Container started: $container_name"
            log_info "To attach: podman exec -it $container_name /bin/bash"
            log_info "To stop:   podman stop $container_name"
            log_info "To remove: podman rm $container_name"
        else
            log_error "Failed to start container"
            exit 1
        fi
    else
        run_args+=("-it")
        if [[ "$auto_rm" == "true" ]]; then
            run_args+=("--rm")
        fi
        
        log_launch "Starting interactive container: $container_name"
        log_info "Image: $full_image"
        log_info "Mode: privileged"
        echo ""

        podman run "${run_args[@]}" "$full_image" "$shell"
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local image_name=""
    local image_tag=""
    local container_name=""
    local detach="false"
    local shell="/bin/bash"
    local auto_rm="true"
    local extra_args=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                image_name="$2"
                shift 2
                ;;
            -t|--tag)
                image_tag="$2"
                shift 2
                ;;
            -c|--container)
                container_name="$2"
                shift 2
                ;;
            -d|--detach)
                detach="true"
                auto_rm="false"
                shift
                ;;
            -v|--volume)
                extra_args+=("-v" "$2")
                shift 2
                ;;
            -p|--port)
                extra_args+=("-p" "$2")
                shift 2
                ;;
            --shell)
                shell="$2"
                shift 2
                ;;
            --rm)
                auto_rm="true"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Load .env file if present
    load_env

    # Resolve values with priority: CLI args > env vars > defaults
    image_name="$(resolve_image_name "$image_name")"
    image_tag="$(resolve_image_tag "$image_tag")"
    container_name="$(resolve_container_name "$container_name")"

    # Validate dependencies
    require_podman

    # Run
    run_container "$image_name" "$image_tag" "$container_name" "$detach" "$shell" "$auto_rm" "${extra_args[@]}"
}

main "$@"
