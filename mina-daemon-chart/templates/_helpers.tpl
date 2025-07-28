{{/*
Expand the name of the chart.
*/}}
{{- define "mina-standard-daemon.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mina-standard-daemon.fullname" -}}
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
{{- define "mina-standard-daemon.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mina-standard-daemon.labels" -}}
helm.sh/chart: {{ include "mina-standard-daemon.chart" . }}
{{ include "mina-standard-daemon.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{/* 
  Labels below are added to keep backwards compatibility 
*/}}
app: {{ .Release.Name }}
version: {{ trunc 6 (.Values.daemon.image.tag) | trimSuffix "-" }}
role: {{ .Values.daemon.role}}
testnet: {{ .Values.daemon.network }}
{{- end }}

{{/*
Mina Network labels
*/}}
{{- define "mina-standard-daemon.mina-labels" -}}
syncStatus: INIT
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mina-standard-daemon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mina-standard-daemon.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mina-standard-daemon.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mina-standard-daemon.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
