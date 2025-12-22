#!/bin/bash
#
# Run the development container locally using Podman
#

set -euo pipefail

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run the Midnight development container locally using Podman.

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

Examples:
    $(basename "$0")                              # Run interactively
    $(basename "$0") -d                           # Run detached
    $(basename "$0") -v \$(pwd):/workspace        # Mount current dir
EOF
}

main() {
    local image_name=""
    local image_tag=""
    local container_name=""
    local detach="false"
    local shell="/bin/bash"
    local auto_rm="true"
    local extra_args=()

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

    load_env

    image_name="$(resolve_image_name "$image_name")"
    image_tag="$(resolve_image_tag "$image_tag")"
    container_name="$(resolve_container_name "$container_name")"

    require_podman

    local full_image
    full_image="$(get_full_image "$image_name" "$image_tag")"

    require_image "$full_image"

    local run_args=(
        "--name" "$container_name"
        "-e" "CHAIN_ENVIRONMENT=standalone"
    )

    # Pass Midnight service URLs if configured in .env
    if [[ -n "${MIDNIGHT_NODE_URL:-}" ]]; then
        log_info "MIDNIGHT_NODE_URL=$MIDNIGHT_NODE_URL"
        run_args+=("-e" "MIDNIGHT_NODE_URL=$MIDNIGHT_NODE_URL")
    fi
    if [[ -n "${INDEXER_URL:-}" ]]; then
        log_info "INDEXER_URL=$INDEXER_URL"
        run_args+=("-e" "INDEXER_URL=$INDEXER_URL")
    fi
    if [[ -n "${PROOF_SERVER_URL:-}" ]]; then
        log_info "PROOF_SERVER_URL=$PROOF_SERVER_URL"
        run_args+=("-e" "PROOF_SERVER_URL=$PROOF_SERVER_URL")
    fi

    # Mount gcloud ADC credentials if available (for OpenCode Vertex AI integration)
    local gcloud_config_dir="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}"
    local gcloud_adc_file="${gcloud_config_dir}/application_default_credentials.json"

    if [[ -f "$gcloud_adc_file" ]]; then
        log_info "Mounting gcloud ADC for Vertex AI access"
        run_args+=("-v" "${gcloud_config_dir}:/home/ubuntu/.config/gcloud:ro")
        
        # Auto-detect project from gcloud config if not already set
        if [[ -z "${GOOGLE_CLOUD_PROJECT:-}" ]]; then
            local detected_project
            detected_project=$(gcloud config get-value project 2>/dev/null || true)
            if [[ -n "$detected_project" ]]; then
                log_info "GOOGLE_CLOUD_PROJECT=$detected_project"
                run_args+=("-e" "GOOGLE_CLOUD_PROJECT=$detected_project")
            fi
        else
            log_info "GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT"
            run_args+=("-e" "GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT")
        fi
    else
        log_warning "gcloud ADC not found. OpenCode Vertex AI integration will not work."
        log_info "Run: gcloud auth application-default login"
    fi

    # Port mappings for local development
    run_args+=("-p" "8080:8080")   # Code OSS
    run_args+=("-p" "9944:9944")   # Node WebSocket (if running local node)
    run_args+=("-p" "6300:6300")   # Proof Server
    run_args+=("-p" "8081:8081")   # Indexer

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
            log_info "Access Code OSS: http://localhost:8080"
            log_info "To attach: podman exec -it $container_name /bin/bash"
            log_info "To stop:   podman stop $container_name"
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
        echo ""

        podman run "${run_args[@]}" "$full_image" "$shell"
    fi
}

main "$@"
