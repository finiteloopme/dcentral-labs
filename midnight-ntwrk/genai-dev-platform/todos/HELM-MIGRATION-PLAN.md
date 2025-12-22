# Helm Migration Plan: Midnight K8s Services

**Status:** Ready for execution  
**Created:** 2025-12-22  
**Prerequisite:** `make deploy` must complete successfully first

## Overview

Replace the Terraform-managed K8s resources (`terraform/modules/midnight-k8s-services/`) with a Helm chart deployed via Terraform's `helm_release` resource. This enables quick K8s-only updates via `helm upgrade` while maintaining unified infrastructure management.

## Decisions

| Decision | Choice |
|----------|--------|
| Chart location | `charts/` directory in this repo |
| Values structure | Separate files per environment |
| Service URLs | `kubernetes_service` data sources for TF integration |
| Helm state | In-cluster (K8s secrets) |
| Migration | Clean cutover |
| Versioning | Chart version = semver, appVersion = composite |

## File Summary

| Action | Files | Count |
|--------|-------|-------|
| Create | Helm chart + scripts | 12 |
| Modify | Terraform + scripts + Makefile | 6 |
| Delete | Old Terraform module | 3 |
| **Total** | | **21** |

---

## Files to Create

### 1. `scripts/common.sh` Additions

Add these functions to the existing `scripts/common.sh`:

```bash
# ==============================================================================
# Project Paths
# ==============================================================================

# Get the project root directory
# Works by finding the caller script's directory, then going up one level
get_project_dir() {
    local caller_script="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
    local caller_dir
    caller_dir="$(cd "$(dirname "$caller_script")" && pwd)"
    echo "$(cd "${caller_dir}/.." && pwd)"
}

# ==============================================================================
# Tool Validation
# ==============================================================================

require_helm() {
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed. Please install Helm 3.x"
        log_info "Install: https://helm.sh/docs/intro/install/"
        exit 1
    fi
}

require_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        log_info "Install: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
}

require_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud is not installed"
        log_info "Install: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
}
```

### 2. `scripts/helm.sh`

```bash
#!/bin/bash
#
# Helm operations for Midnight K8s services
#
# Usage:
#   ./scripts/helm.sh upgrade     # Upgrade/install services
#   ./scripts/helm.sh status      # Show release status
#   ./scripts/helm.sh rollback    # Rollback to previous release
#   ./scripts/helm.sh history     # Show release history
#   ./scripts/helm.sh template    # Render templates locally
#   ./scripts/helm.sh uninstall   # Uninstall release
#

set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Get project directory and load environment
PROJECT_DIR="$(get_project_dir)"
load_env

# ==============================================================================
# Configuration
# ==============================================================================

RELEASE_NAME="${RELEASE_NAME:-midnight-services}"
NAMESPACE="${NAMESPACE:-midnight-services}"
CHART_PATH="${PROJECT_DIR}/charts/midnight-services"
CHAIN_ENVIRONMENT="${CHAIN_ENVIRONMENT:-standalone}"

# Image overrides (optional)
MIDNIGHT_NODE_IMAGE="${MIDNIGHT_NODE_IMAGE:-}"
PROOF_SERVER_IMAGE="${PROOF_SERVER_IMAGE:-}"
INDEXER_IMAGE="${INDEXER_IMAGE:-}"
INDEXER_SECRET="${INDEXER_SECRET:-}"

# ==============================================================================
# Helpers
# ==============================================================================

get_values_files() {
    local values_args="-f ${CHART_PATH}/values.yaml"
    
    local env_values="${CHART_PATH}/values-${CHAIN_ENVIRONMENT}.yaml"
    if [[ -f "$env_values" ]]; then
        values_args="$values_args -f $env_values"
    else
        log_error "Values file not found: $env_values"
        exit 1
    fi
    
    echo "$values_args"
}

get_set_args() {
    local set_args=""
    
    [[ -n "$MIDNIGHT_NODE_IMAGE" ]] && set_args="$set_args --set node.image=$MIDNIGHT_NODE_IMAGE"
    [[ -n "$PROOF_SERVER_IMAGE" ]] && set_args="$set_args --set proofServer.image=$PROOF_SERVER_IMAGE"
    [[ -n "$INDEXER_IMAGE" ]] && set_args="$set_args --set indexer.image=$INDEXER_IMAGE"
    [[ -n "$INDEXER_SECRET" ]] && set_args="$set_args --set indexer.secret=$INDEXER_SECRET"
    
    echo "$set_args"
}

# ==============================================================================
# Commands
# ==============================================================================

cmd_upgrade() {
    require_helm
    
    log_info "Upgrading Midnight services..."
    echo ""
    echo "  Release:     $RELEASE_NAME"
    echo "  Namespace:   $NAMESPACE"
    echo "  Environment: $CHAIN_ENVIRONMENT"
    echo ""
    
    local values_args=$(get_values_files)
    local set_args=$(get_set_args)
    
    # shellcheck disable=SC2086
    helm upgrade "$RELEASE_NAME" "$CHART_PATH" \
        --install \
        --namespace "$NAMESPACE" \
        --create-namespace \
        $values_args \
        $set_args \
        "$@"
    
    log_success "Upgrade complete"
}

cmd_status() {
    require_helm
    helm status "$RELEASE_NAME" --namespace "$NAMESPACE"
}

cmd_rollback() {
    require_helm
    local revision="${1:-}"
    
    if [[ -z "$revision" ]]; then
        log_info "Rolling back to previous release..."
        helm rollback "$RELEASE_NAME" --namespace "$NAMESPACE"
    else
        log_info "Rolling back to revision $revision..."
        helm rollback "$RELEASE_NAME" "$revision" --namespace "$NAMESPACE"
    fi
    
    log_success "Rollback complete"
}

cmd_history() {
    require_helm
    helm history "$RELEASE_NAME" --namespace "$NAMESPACE"
}

cmd_template() {
    require_helm
    
    local values_args=$(get_values_files)
    local set_args=$(get_set_args)
    
    # shellcheck disable=SC2086
    helm template "$RELEASE_NAME" "$CHART_PATH" \
        --namespace "$NAMESPACE" \
        $values_args \
        $set_args \
        "$@"
}

cmd_uninstall() {
    require_helm
    
    log_warning "This will uninstall $RELEASE_NAME from $NAMESPACE!"
    echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
    sleep 5
    
    helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE"
    log_success "Uninstall complete"
}

cmd_pods() {
    require_kubectl
    kubectl get pods -n "$NAMESPACE" "$@"
}

cmd_logs() {
    require_kubectl
    local service="${1:-}"
    
    if [[ -z "$service" ]]; then
        log_error "Usage: $0 logs <service> [kubectl logs options]"
        echo "  Services: node, proof-server, indexer"
        exit 1
    fi
    
    shift
    kubectl logs -n "$NAMESPACE" -l "app=$service" "$@"
}

cmd_help() {
    cat <<EOF
Midnight Helm Operations Script

Usage: $(basename "$0") <command> [options]

Commands:
    upgrade              Upgrade/install Midnight services
    status               Show Helm release status
    rollback [revision]  Rollback to previous (or specific) revision
    history              Show release history
    template             Render templates locally (dry-run)
    uninstall            Uninstall the release
    pods                 List pods in namespace
    logs <service>       Show logs for a service (node, proof-server, indexer)

Configuration:
    Set in .env or as environment variables:
    
    CHAIN_ENVIRONMENT   standalone, testnet, mainnet (default: standalone)
    RELEASE_NAME        Helm release name (default: midnight-services)
    NAMESPACE           Kubernetes namespace (default: midnight-services)
    
    Image overrides (optional):
    MIDNIGHT_NODE_IMAGE    Override node image
    PROOF_SERVER_IMAGE     Override proof server image
    INDEXER_IMAGE          Override indexer image
    INDEXER_SECRET         32-byte hex secret for indexer

Examples:
    $(basename "$0") upgrade                      # Install/upgrade
    $(basename "$0") upgrade --dry-run            # Preview upgrade
    $(basename "$0") status                       # Check status
    $(basename "$0") rollback                     # Rollback to previous
    $(basename "$0") rollback 2                   # Rollback to revision 2
    $(basename "$0") logs node -f                 # Follow node logs
    $(basename "$0") pods -w                      # Watch pods
    
    CHAIN_ENVIRONMENT=testnet $(basename "$0") upgrade
EOF
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local command="${1:-help}"
    shift 2>/dev/null || true
    
    case "$command" in
        upgrade)   cmd_upgrade "$@" ;;
        status)    cmd_status ;;
        rollback)  cmd_rollback "$@" ;;
        history)   cmd_history ;;
        template)  cmd_template "$@" ;;
        uninstall) cmd_uninstall ;;
        pods)      cmd_pods "$@" ;;
        logs)      cmd_logs "$@" ;;
        help|-h|--help) cmd_help ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
```

### 3. `charts/midnight-services/Chart.yaml`

```yaml
apiVersion: v2
name: midnight-services
description: Midnight blockchain services (node, proof-server, indexer)
type: application
version: 0.1.0
appVersion: "node-0.18.0_proof-6.1.0_indexer-3.0.0"
maintainers:
  - name: Midnight Team
keywords:
  - midnight
  - blockchain
  - zk-proofs
```

### 4. `charts/midnight-services/.helmignore`

```
# Patterns to ignore when building packages
.DS_Store
.git/
.gitignore
.idea/
*.swp
*.bak
*.tmp
*.orig
# Editor backup files
*~
# Test files
tests/
# CI files
.github/
# Documentation (except README)
*.md
!README.md
```

### 5. `charts/midnight-services/values.yaml`

```yaml
# Default values for midnight-services
# This file contains defaults that apply to all environments

global:
  labels: {}

namespace:
  name: midnight-services
  create: true

# Midnight Node
node:
  enabled: true
  image: midnightntwrk/midnight-node:0.18.0
  replicas: 1
  
  # Dev mode settings (overridden in values-standalone.yaml)
  devMode: false
  args: []
  env: {}
  
  service:
    type: LoadBalancer
    port: 9944
  
  resources:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  
  probes:
    liveness:
      enabled: true
      path: /health
      initialDelaySeconds: 60
      periodSeconds: 30
      timeoutSeconds: 5
      failureThreshold: 3
    readiness:
      enabled: true
      path: /health
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    startup:
      enabled: true
      path: /health
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 30

# Proof Server
proofServer:
  enabled: true
  image: midnightnetwork/proof-server:6.1.0-alpha.6
  replicas: 1
  
  service:
    type: LoadBalancer
    port: 6300
  
  resources:
    requests:
      cpu: "4"
      memory: "8Gi"
    limits:
      cpu: "4"
      memory: "8Gi"
  
  probes:
    liveness:
      enabled: true
      initialDelaySeconds: 30
      periodSeconds: 30
      timeoutSeconds: 5
      failureThreshold: 3
    readiness:
      enabled: true
      initialDelaySeconds: 15
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    startup:
      enabled: true
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 60  # 10 min for ZK key download

# Indexer
indexer:
  enabled: true
  image: midnightntwrk/indexer-standalone:3.0.0-alpha.20
  replicas: 1
  
  # Required: 32-byte hex secret for encryption
  secret: ""
  
  # Network ID for indexer config
  networkId: "undeployed"
  
  # Clear SQLite DB on pod start (for dev environments)
  clearDbOnStart: false
  
  service:
    type: LoadBalancer
    port: 8088
  
  resources:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
  
  probes:
    liveness:
      enabled: true
      initialDelaySeconds: 60
      periodSeconds: 30
      timeoutSeconds: 5
      failureThreshold: 3
    readiness:
      enabled: true
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    startup:
      enabled: true
      initialDelaySeconds: 15
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 30
```

### 6. `charts/midnight-services/values-standalone.yaml`

```yaml
# Standalone/development environment overrides

node:
  devMode: true
  args:
    - "--dev"
    - "--rpc-external"
    - "--rpc-cors=all"
    - "--rpc-methods=unsafe"
    - "--state-pruning=archive"
  env:
    USE_MAIN_CHAIN_FOLLOWER_MOCK: "true"
    MOCK_REGISTRATIONS_FILE: "res/mock-bridge-data/default-registrations.json"
    SIDECHAIN_BLOCK_BENEFICIARY: "04bcf7ad3be7a5c790460be82a713af570f22e0f801f6659ab8e84a52be6969e"

indexer:
  networkId: "undeployed"
  clearDbOnStart: true
```

### 7. `charts/midnight-services/values-testnet.yaml`

```yaml
# Testnet environment overrides

node:
  devMode: false
  args: []
  env: {}

indexer:
  networkId: "testnet"
  clearDbOnStart: false
```

### 8. `charts/midnight-services/values-mainnet.yaml`

```yaml
# Mainnet environment overrides

node:
  devMode: false
  args: []
  env: {}

indexer:
  networkId: "mainnet"
  clearDbOnStart: false
```

### 9. `charts/midnight-services/templates/_helpers.tpl`

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "midnight-services.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "midnight-services.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "midnight-services.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "midnight-services.labels" -}}
helm.sh/chart: {{ include "midnight-services.chart" . }}
{{ include "midnight-services.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.global.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "midnight-services.selectorLabels" -}}
app.kubernetes.io/name: {{ include "midnight-services.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Namespace name
*/}}
{{- define "midnight-services.namespace" -}}
{{- .Values.namespace.name | default "midnight-services" }}
{{- end }}
```

### 10. `charts/midnight-services/templates/namespace.yaml`

```yaml
{{- if .Values.namespace.create }}
apiVersion: v1
kind: Namespace
metadata:
  name: {{ include "midnight-services.namespace" . }}
  labels:
    {{- include "midnight-services.labels" . | nindent 4 }}
{{- end }}
```

### 11. `charts/midnight-services/templates/node.yaml`

```yaml
{{- if .Values.node.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: midnight-node
  namespace: {{ include "midnight-services.namespace" . }}
  labels:
    {{- include "midnight-services.labels" . | nindent 4 }}
    app: midnight-node
spec:
  replicas: {{ .Values.node.replicas }}
  selector:
    matchLabels:
      app: midnight-node
  template:
    metadata:
      labels:
        {{- include "midnight-services.labels" . | nindent 8 }}
        app: midnight-node
    spec:
      containers:
        - name: midnight-node
          image: {{ .Values.node.image }}
          {{- if .Values.node.args }}
          args:
            {{- toYaml .Values.node.args | nindent 12 }}
          {{- end }}
          {{- if .Values.node.env }}
          env:
            {{- range $key, $value := .Values.node.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
          {{- end }}
          ports:
            - name: rpc
              containerPort: 9944
              protocol: TCP
          resources:
            requests:
              cpu: {{ .Values.node.resources.requests.cpu }}
              memory: {{ .Values.node.resources.requests.memory }}
            limits:
              cpu: {{ .Values.node.resources.limits.cpu }}
              memory: {{ .Values.node.resources.limits.memory }}
          {{- if .Values.node.probes.liveness.enabled }}
          livenessProbe:
            httpGet:
              path: {{ .Values.node.probes.liveness.path }}
              port: 9944
            initialDelaySeconds: {{ .Values.node.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.node.probes.liveness.periodSeconds }}
            timeoutSeconds: {{ .Values.node.probes.liveness.timeoutSeconds }}
            failureThreshold: {{ .Values.node.probes.liveness.failureThreshold }}
          {{- end }}
          {{- if .Values.node.probes.readiness.enabled }}
          readinessProbe:
            httpGet:
              path: {{ .Values.node.probes.readiness.path }}
              port: 9944
            initialDelaySeconds: {{ .Values.node.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.node.probes.readiness.periodSeconds }}
            timeoutSeconds: {{ .Values.node.probes.readiness.timeoutSeconds }}
            failureThreshold: {{ .Values.node.probes.readiness.failureThreshold }}
          {{- end }}
          {{- if .Values.node.probes.startup.enabled }}
          startupProbe:
            httpGet:
              path: {{ .Values.node.probes.startup.path }}
              port: 9944
            initialDelaySeconds: {{ .Values.node.probes.startup.initialDelaySeconds }}
            periodSeconds: {{ .Values.node.probes.startup.periodSeconds }}
            timeoutSeconds: {{ .Values.node.probes.startup.timeoutSeconds }}
            failureThreshold: {{ .Values.node.probes.startup.failureThreshold }}
          {{- end }}
---
apiVersion: v1
kind: Service
metadata:
  name: midnight-node
  namespace: {{ include "midnight-services.namespace" . }}
  labels:
    {{- include "midnight-services.labels" . | nindent 4 }}
    app: midnight-node
spec:
  type: {{ .Values.node.service.type }}
  selector:
    app: midnight-node
  ports:
    - name: rpc
      port: {{ .Values.node.service.port }}
      targetPort: 9944
      protocol: TCP
{{- end }}
```

### 12. `charts/midnight-services/templates/proof-server.yaml`

```yaml
{{- if .Values.proofServer.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: proof-server
  namespace: {{ include "midnight-services.namespace" . }}
  labels:
    {{- include "midnight-services.labels" . | nindent 4 }}
    app: proof-server
spec:
  replicas: {{ .Values.proofServer.replicas }}
  selector:
    matchLabels:
      app: proof-server
  template:
    metadata:
      labels:
        {{- include "midnight-services.labels" . | nindent 8 }}
        app: proof-server
    spec:
      containers:
        - name: proof-server
          image: {{ .Values.proofServer.image }}
          ports:
            - name: grpc
              containerPort: 6300
              protocol: TCP
          resources:
            requests:
              cpu: {{ .Values.proofServer.resources.requests.cpu }}
              memory: {{ .Values.proofServer.resources.requests.memory }}
            limits:
              cpu: {{ .Values.proofServer.resources.limits.cpu }}
              memory: {{ .Values.proofServer.resources.limits.memory }}
          {{- if .Values.proofServer.probes.liveness.enabled }}
          livenessProbe:
            tcpSocket:
              port: 6300
            initialDelaySeconds: {{ .Values.proofServer.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.proofServer.probes.liveness.periodSeconds }}
            timeoutSeconds: {{ .Values.proofServer.probes.liveness.timeoutSeconds }}
            failureThreshold: {{ .Values.proofServer.probes.liveness.failureThreshold }}
          {{- end }}
          {{- if .Values.proofServer.probes.readiness.enabled }}
          readinessProbe:
            tcpSocket:
              port: 6300
            initialDelaySeconds: {{ .Values.proofServer.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.proofServer.probes.readiness.periodSeconds }}
            timeoutSeconds: {{ .Values.proofServer.probes.readiness.timeoutSeconds }}
            failureThreshold: {{ .Values.proofServer.probes.readiness.failureThreshold }}
          {{- end }}
          {{- if .Values.proofServer.probes.startup.enabled }}
          startupProbe:
            tcpSocket:
              port: 6300
            initialDelaySeconds: {{ .Values.proofServer.probes.startup.initialDelaySeconds }}
            periodSeconds: {{ .Values.proofServer.probes.startup.periodSeconds }}
            timeoutSeconds: {{ .Values.proofServer.probes.startup.timeoutSeconds }}
            failureThreshold: {{ .Values.proofServer.probes.startup.failureThreshold }}
          {{- end }}
---
apiVersion: v1
kind: Service
metadata:
  name: proof-server
  namespace: {{ include "midnight-services.namespace" . }}
  labels:
    {{- include "midnight-services.labels" . | nindent 4 }}
    app: proof-server
spec:
  type: {{ .Values.proofServer.service.type }}
  selector:
    app: proof-server
  ports:
    - name: grpc
      port: {{ .Values.proofServer.service.port }}
      targetPort: 6300
      protocol: TCP
{{- end }}
```

### 13. `charts/midnight-services/templates/indexer.yaml`

```yaml
{{- if .Values.indexer.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: indexer-config
  namespace: {{ include "midnight-services.namespace" . }}
  labels:
    {{- include "midnight-services.labels" . | nindent 4 }}
    app: indexer
data:
  config.yaml: |
    run_migrations: true

    application:
      network_id: {{ .Values.indexer.networkId | quote }}
      blocks_buffer: 10
      save_ledger_state_after: 1000
      caught_up_max_distance: 10
      caught_up_leeway: 5
      active_wallets_query_delay: "500ms"
      active_wallets_ttl: "30m"
      transaction_batch_size: 50

    infra:
      secret: {{ .Values.indexer.secret | quote }}
      
      storage:
        cnn_url: "/data/indexer.sqlite"

      node:
        url: "ws://midnight-node.{{ include "midnight-services.namespace" . }}.svc.cluster.local:9944"
        reconnect_max_delay: "10s"
        reconnect_max_attempts: 30
        subscription_recovery_timeout: "30s"

      api:
        address: "0.0.0.0"
        port: 8088
        request_body_limit: "1MiB"
        max_complexity: 200
        max_depth: 15

    telemetry:
      tracing:
        enabled: false
        service_name: "indexer"
        otlp_exporter_endpoint: "http://localhost:4317"
      metrics:
        enabled: false
        address: "0.0.0.0"
        port: 9000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: indexer
  namespace: {{ include "midnight-services.namespace" . }}
  labels:
    {{- include "midnight-services.labels" . | nindent 4 }}
    app: indexer
spec:
  replicas: {{ .Values.indexer.replicas }}
  selector:
    matchLabels:
      app: indexer
  template:
    metadata:
      labels:
        {{- include "midnight-services.labels" . | nindent 8 }}
        app: indexer
    spec:
      {{- if .Values.indexer.clearDbOnStart }}
      initContainers:
        - name: clear-db
          image: busybox:latest
          command: ["sh", "-c", "rm -rf /data/indexer.sqlite* && echo 'Cleared indexer database'"]
          volumeMounts:
            - name: data
              mountPath: /data
      {{- end }}
      containers:
        - name: indexer
          image: {{ .Values.indexer.image }}
          ports:
            - name: http
              containerPort: 8088
              protocol: TCP
            - name: metrics
              containerPort: 9000
              protocol: TCP
          resources:
            requests:
              cpu: {{ .Values.indexer.resources.requests.cpu }}
              memory: {{ .Values.indexer.resources.requests.memory }}
            limits:
              cpu: {{ .Values.indexer.resources.limits.cpu }}
              memory: {{ .Values.indexer.resources.limits.memory }}
          volumeMounts:
            - name: config
              mountPath: /opt/indexer-standalone/config.yaml
              subPath: config.yaml
              readOnly: true
            - name: data
              mountPath: /data
          {{- if .Values.indexer.probes.liveness.enabled }}
          livenessProbe:
            tcpSocket:
              port: 8088
            initialDelaySeconds: {{ .Values.indexer.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.indexer.probes.liveness.periodSeconds }}
            timeoutSeconds: {{ .Values.indexer.probes.liveness.timeoutSeconds }}
            failureThreshold: {{ .Values.indexer.probes.liveness.failureThreshold }}
          {{- end }}
          {{- if .Values.indexer.probes.readiness.enabled }}
          readinessProbe:
            tcpSocket:
              port: 8088
            initialDelaySeconds: {{ .Values.indexer.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.indexer.probes.readiness.periodSeconds }}
            timeoutSeconds: {{ .Values.indexer.probes.readiness.timeoutSeconds }}
            failureThreshold: {{ .Values.indexer.probes.readiness.failureThreshold }}
          {{- end }}
          {{- if .Values.indexer.probes.startup.enabled }}
          startupProbe:
            tcpSocket:
              port: 8088
            initialDelaySeconds: {{ .Values.indexer.probes.startup.initialDelaySeconds }}
            periodSeconds: {{ .Values.indexer.probes.startup.periodSeconds }}
            timeoutSeconds: {{ .Values.indexer.probes.startup.timeoutSeconds }}
            failureThreshold: {{ .Values.indexer.probes.startup.failureThreshold }}
          {{- end }}
      volumes:
        - name: config
          configMap:
            name: indexer-config
        - name: data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: indexer
  namespace: {{ include "midnight-services.namespace" . }}
  labels:
    {{- include "midnight-services.labels" . | nindent 4 }}
    app: indexer
spec:
  type: {{ .Values.indexer.service.type }}
  selector:
    app: indexer
  ports:
    - name: http
      port: {{ .Values.indexer.service.port }}
      targetPort: 8088
      protocol: TCP
{{- end }}
```

---

## Files to Modify

### 1. Update `scripts/cloud.sh`

Replace the top section (lines 1-56) with:

```bash
#!/bin/bash
#
# Cloud deployment script for GCP
#
# Usage:
#   ./scripts/cloud.sh deploy    # Deploy all infrastructure
#   ./scripts/cloud.sh plan      # Preview changes
#   ./scripts/cloud.sh destroy   # Destroy infrastructure
#   ./scripts/cloud.sh check     # Validate configuration
#

set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Get project directory and load environment
PROJECT_DIR="$(get_project_dir)"
load_env

# ==============================================================================
# Configuration
# ==============================================================================

# Required
PROJECT_ID="${PROJECT_ID:-}"
STATE_BUCKET="${STATE_BUCKET:-}"
STATE_PREFIX="${STATE_PREFIX:-terraform/state}"

# ... rest of configuration unchanged ...
```

Remove the duplicated helper functions (lines 53-55):
```bash
# DELETE THESE LINES:
log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1" >&2; }
log_success() { echo "[OK] $1"; }
```

### 2. Update `terraform/versions.tf`

Add Helm provider:

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
  }

  backend "gcs" {}
}

# ... existing provider configurations ...

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke_cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke_cluster.ca_certificate)
  }
}
```

### 3. Update `terraform/main.tf`

Replace the `module.midnight_k8s_services` block (lines 104-121) with:

```hcl
# ===========================================
# MIDNIGHT KUBERNETES SERVICES (via Helm)
# ===========================================

resource "helm_release" "midnight_services" {
  name             = "midnight-services"
  namespace        = "midnight-services"
  create_namespace = true
  chart            = "${path.root}/../charts/midnight-services"
  
  values = [
    file("${path.root}/../charts/midnight-services/values.yaml"),
    file("${path.root}/../charts/midnight-services/values-${var.chain_environment}.yaml")
  ]
  
  set {
    name  = "node.image"
    value = var.midnight_node_image
  }
  
  set {
    name  = "proofServer.image"
    value = var.proof_server_image
  }
  
  set {
    name  = "indexer.image"
    value = var.indexer_image
  }
  
  set_sensitive {
    name  = "indexer.secret"
    value = var.indexer_secret
  }

  depends_on = [module.gke_cluster]
}

# Data sources to get LoadBalancer IPs for outputs
data "kubernetes_service_v1" "midnight_node" {
  metadata {
    name      = "midnight-node"
    namespace = "midnight-services"
  }
  depends_on = [helm_release.midnight_services]
}

data "kubernetes_service_v1" "proof_server" {
  metadata {
    name      = "proof-server"
    namespace = "midnight-services"
  }
  depends_on = [helm_release.midnight_services]
}

data "kubernetes_service_v1" "indexer" {
  metadata {
    name      = "indexer"
    namespace = "midnight-services"
  }
  depends_on = [helm_release.midnight_services]
}
```

Update the workstations module to use the data sources:

```hcl
module "workstations" {
  # ... existing config ...

  service_urls = {
    MIDNIGHT_NODE_URL = "ws://${data.kubernetes_service_v1.midnight_node.status[0].load_balancer[0].ingress[0].ip}:9944"
    PROOF_SERVER_URL  = "http://${data.kubernetes_service_v1.proof_server.status[0].load_balancer[0].ingress[0].ip}:6300"
    INDEXER_URL       = "http://${data.kubernetes_service_v1.indexer.status[0].load_balancer[0].ingress[0].ip}:8088"
    CHAIN_ENVIRONMENT = var.chain_environment
  }

  depends_on = [
    google_project_service.apis,
    google_project_iam_member.cloudbuild_sa,
    module.artifact_registry,
    helm_release.midnight_services,
  ]
}
```

### 4. Update `terraform/outputs.tf`

Update outputs to use data sources:

```hcl
output "node_url" {
  description = "URL of the Midnight node service"
  value       = "ws://${data.kubernetes_service_v1.midnight_node.status[0].load_balancer[0].ingress[0].ip}:9944"
}

output "proof_server_url" {
  description = "URL of the proof server service"
  value       = "http://${data.kubernetes_service_v1.proof_server.status[0].load_balancer[0].ingress[0].ip}:6300"
}

output "indexer_url" {
  description = "URL of the indexer service"
  value       = "http://${data.kubernetes_service_v1.indexer.status[0].load_balancer[0].ingress[0].ip}:8088"
}
```

### 5. Update `Makefile`

Add Helm targets:

```makefile
# ==============================================================================
# Helm Operations (K8s services)
# ==============================================================================

helm-upgrade:
	@./scripts/helm.sh upgrade

helm-status:
	@./scripts/helm.sh status

helm-rollback:
	@./scripts/helm.sh rollback

helm-logs:
	@./scripts/helm.sh logs $(SERVICE)
```

Update help text to include:

```makefile
@echo ""
@echo "Helm Operations (K8s services - fast iteration):"
@echo "  make helm-upgrade            Upgrade K8s services"
@echo "  make helm-status             Show Helm release status"
@echo "  make helm-rollback           Rollback to previous release"
@echo "  make helm-logs SERVICE=node  Show logs for a service"
```

---

## Files to Delete

After successful cutover:

1. `terraform/modules/midnight-k8s-services/main.tf`
2. `terraform/modules/midnight-k8s-services/variables.tf`
3. `terraform/modules/midnight-k8s-services/outputs.tf`
4. `terraform/modules/midnight-k8s-services/` (directory)

---

## Cutover Steps

Execute these steps after `make deploy` completes:

```bash
# 1. Configure kubectl to access GKE cluster
gcloud container clusters get-credentials midnight-dev-gke --region us-central1 --project $PROJECT_ID

# 2. Remove current K8s resources from Terraform state
# This must be done via Cloud Build since state is remote
./scripts/cloud.sh state-cleanup "module.midnight_k8s_services"

# 3. Delete the K8s namespace (clean slate for Helm)
kubectl delete namespace midnight-services

# 4. Create all the new files (Helm chart, scripts, etc.)
# [Implementation by assistant]

# 5. Run Terraform to deploy via Helm
make deploy BUILD_SDK=false

# 6. Verify
./scripts/helm.sh status
./scripts/helm.sh pods
kubectl get services -n midnight-services
```

---

## Post-Migration Usage

### Full Deploy (Infrastructure + K8s)

```bash
make deploy                    # Builds SDK + deploys everything
make deploy BUILD_SDK=false    # Skip SDK build
```

### K8s Services Only (Fast Iteration)

```bash
./scripts/helm.sh upgrade              # Install/upgrade
./scripts/helm.sh upgrade --dry-run    # Preview changes
./scripts/helm.sh status               # Check status
./scripts/helm.sh rollback             # Rollback to previous
./scripts/helm.sh logs node -f         # Follow node logs
./scripts/helm.sh pods -w              # Watch pods

# Or via Make
make helm-upgrade
make helm-status
make helm-rollback
make helm-logs SERVICE=node
```

### Environment-Specific Deploy

```bash
CHAIN_ENVIRONMENT=testnet ./scripts/helm.sh upgrade
CHAIN_ENVIRONMENT=mainnet ./scripts/helm.sh upgrade
```
