#!/bin/bash

set -ex

# Function to run commands inside a container
run_in_container() {
  local ACTION=$1
  shift

  local IMAGE=""
  local IMAGE_COMMAND=""

  case "$ACTION" in
    terraform|helm)
      IMAGE_COMMAND=""
      ;;
    gcloud|yq|kubectl)
      IMAGE_COMMAND=$ACTION
      ;;
    *)
      echo "Usage: $0 [--project-id <project_id>] {terraform|helm|gcloud|yq|kubectl} [-w /path/to/workdir] ..." >&2
      exit 1
      ;;
  esac

  case "$ACTION" in
    terraform)
      IMAGE="docker.io/hashicorp/terraform:latest"
      ;;
    helm|yq|kubectl)
      IMAGE="midnight-gke-tools"
      ;;
    gcloud)
      IMAGE="docker.io/google/cloud-sdk:latest"
      ;;
  esac

  if [ -z "$TF_LOG" ]; then
    TF_LOG="WARN"
  fi

  exec podman run --rm -it \
    -v $(pwd):/app -w $WORKDIR \
    -v $USER_HOME/.config/gcloud:/root/.config/gcloud \
    -v $USER_HOME/.kube:/root/.kube \
    -e KUBECONFIG=/root/.kube/config \
    -e GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json \
    -e TF_VAR_project_id=$PROJECT_ID \
    -e TF_LOG=$TF_LOG \
    $IMAGE $IMAGE_COMMAND "$@"
}

# Function to generate helm key
helm_generate_key() {
  local WORKDIR=$1
  NODE_KEY=$(podman run --rm -it docker.io/parity/subkey:latest generate-node-key | sed -n '2p')
  podman run --rm -it \
    -v $(pwd):/app -w $WORKDIR \
    -v $USER_HOME/.config/gcloud:/root/.config/gcloud \
    -v $USER_HOME/.kube:/root/.kube \
    -e KUBECONFIG=/root/.kube/config \
    -e GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json \
    -e TF_VAR_project_id=$PROJECT_ID \
    -e TF_LOG=$TF_LOG \
    midnight-gke-tools yq e ".midnightNode.nodeKey = \"$NODE_KEY\"" -i ./midnight-duo/values.yaml
}

# Function to apply helm chart
helm_apply() {
  local WORKDIR=$1
  exec podman run --rm -it \
    -v $(pwd):/app -w $WORKDIR \
    -v $USER_HOME/.config/gcloud:/root/.config/gcloud \
    -v $USER_HOME/.kube:/root/.kube \
    -e KUBECONFIG=/root/.kube/config \
    -e GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json \
    -e TF_VAR_project_id=$PROJECT_ID \
    -e TF_LOG=$TF_LOG \
    midnight-gke-tools helm upgrade --install midnight-duo ./midnight-duo
}

# Main script
PROJECT_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id)
      PROJECT_ID="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

ACTION=$1
shift

USER_HOME=$(getent passwd $(whoami) | cut -d: -f6)

WORKDIR="/app"
if [ "$1" == "-w" ]; then
  WORKDIR="$2"
  shift 2
fi

case "$ACTION" in
  helm-generate-key)
    helm_generate_key $WORKDIR
    ;;
  helm-apply)
    helm_apply $WORKDIR
    ;;
  *)
    run_in_container $ACTION "$@"
    ;;
esac