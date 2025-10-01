{{/*
Expand the name of the chart.
*/}}
{{- define "midnight-node.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "midnight-node.fullname" -}}
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
{{- define "midnight-node.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "midnight-node.labels" -}}
helm.sh/chart: {{ include "midnight-node.chart" . }}
{{ include "midnight-node.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "midnight-node.selectorLabels" -}}
app.kubernetes.io/name: {{ include "midnight-node.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "midnight-node.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "midnight-node.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Component-specific labels for midnight-node
*/}}
{{- define "midnight-node.midnightLabels" -}}
{{ include "midnight-node.labels" . }}
app.kubernetes.io/component: midnight-node
{{- end }}

{{/*
Component-specific labels for cardano-node
*/}}
{{- define "midnight-node.cardanoLabels" -}}
{{ include "midnight-node.labels" . }}
app.kubernetes.io/component: cardano-node
{{- end }}

{{/*
Component-specific labels for postgres
*/}}
{{- define "midnight-node.postgresLabels" -}}
{{ include "midnight-node.labels" . }}
app.kubernetes.io/component: postgres
{{- end }}

{{/*
Component-specific labels for db-sync
*/}}
{{- define "midnight-node.dbSyncLabels" -}}
{{ include "midnight-node.labels" . }}
app.kubernetes.io/component: db-sync
{{- end }}

{{/*
Component-specific labels for ogmios
*/}}
{{- define "midnight-node.ogmiosLabels" -}}
{{ include "midnight-node.labels" . }}
app.kubernetes.io/component: ogmios
{{- end }}

{{/*
Component-specific labels for proof-server
*/}}
{{- define "midnight-node.proofServerLabels" -}}
{{ include "midnight-node.labels" . }}
app.kubernetes.io/component: proof-server
{{- end }}

{{/*
Generate postgres connection string
*/}}
{{- define "midnight-node.postgresConnectionString" -}}
{{- printf "postgresql://%s:%s@%s:%s/%s" .Values.global.postgresUser "%s" .Values.global.postgresHost (.Values.global.postgresPort | toString) .Values.global.postgresDb -}}
{{- end }}

{{/*
Generate postgres host with port
*/}}
{{- define "midnight-node.postgresHostPort" -}}
{{- printf "%s:%s" .Values.global.postgresHost (.Values.global.postgresPort | toString) -}}
{{- end }}

{{/*
Generate cardano node socket path
*/}}
{{- define "midnight-node.cardanoSocketPath" -}}
{{- .Values.global.cardanoNodeSocketPath | default "/ipc/node.socket" -}}
{{- end }}

{{/*
Generate storage class name
*/}}
{{- define "midnight-node.storageClassName" -}}
{{- if .Values.persistence.storageClass -}}
{{- if (eq "-" .Values.persistence.storageClass) -}}
""
{{- else -}}
{{ .Values.persistence.storageClass }}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Generate image pull policy
*/}}
{{- define "midnight-node.imagePullPolicy" -}}
{{- .pullPolicy | default "IfNotPresent" -}}
{{- end }}

{{/*
Generate security context
*/}}
{{- define "midnight-node.securityContext" -}}
{{- if .Values.securityContext -}}
{{- toYaml .Values.securityContext -}}
{{- else -}}
runAsUser: 1000
runAsGroup: 1000
readOnlyRootFilesystem: false
{{- end -}}
{{- end }}

{{/*
Generate pod security context
*/}}
{{- define "midnight-node.podSecurityContext" -}}
{{- if .Values.podSecurityContext -}}
{{- toYaml .Values.podSecurityContext -}}
{{- else -}}
fsGroup: 1000
{{- end -}}
{{- end }}

{{/*
Generate node selector
*/}}
{{- define "midnight-node.nodeSelector" -}}
{{- if .Values.nodeSelector -}}
{{- toYaml .Values.nodeSelector -}}
{{- end -}}
{{- end }}

{{/*
Generate tolerations
*/}}
{{- define "midnight-node.tolerations" -}}
{{- if .Values.tolerations -}}
{{- toYaml .Values.tolerations -}}
{{- end -}}
{{- end }}

{{/*
Generate affinity
*/}}
{{- define "midnight-node.affinity" -}}
{{- if .Values.affinity -}}
{{- toYaml .Values.affinity -}}
{{- end -}}
{{- end }}

{{/*
Generate network configuration for testnet
*/}}
{{- define "midnight-node.networkConfig" -}}
{{- if eq .Values.global.network "testnet-02" -}}
testnet-02
{{- else if eq .Values.global.network "preview" -}}
preview
{{- else -}}
{{ .Values.global.network }}
{{- end -}}
{{- end }}

{{/*
Generate bootnodes based on network
*/}}
{{- define "midnight-node.bootnodes" -}}
{{- if .Values.midnightNode.environment.BOOTNODES -}}
{{ .Values.midnightNode.environment.BOOTNODES }}
{{- else if eq .Values.global.network "testnet-02" -}}
/dns/boot-node-01.testnet-02.midnight.network/tcp/30333/ws/p2p/12D3KooWMjUq13USCvQR9Y6yFzYNYgTQBLNAcmc8psAuPx2UUdnB /dns/boot-node-02.testnet-02.midnight.network/tcp/30333/ws/p2p/12D3KooWR1cHBUWPCqk3uqhwZqUFekfWj8T7ozK6S18DUT745v4d /dns/boot-node-03.testnet-02.midnight.network/tcp/30333/ws/p2p/12D3KooWQxxUgq7ndPfAaCFNbAxtcKYxrAzTxDfRGNktF75SxdX5
{{- else -}}
""
{{- end -}}
{{- end }}

{{/*
Generate resource limits and requests
*/}}
{{- define "midnight-node.resources" -}}
{{- if . -}}
{{- toYaml . -}}
{{- end -}}
{{- end }}
