{{/*
Expand the name of the chart.
*/}}
{{- define "request-tracker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "request-tracker.fullname" -}}
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

{{- define "request-tracker.rt.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- printf "%s-rt" .Values.fullnameOverride | trunc -63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s-rt" .Release.Name | trunc -63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-rt" .Release.Name $name | trunc -63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "request-tracker.caddy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- printf "%s-caddy" .Values.fullnameOverride | trunc -63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s-caddy" .Release.Name | trunc -63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-caddy" .Release.Name $name | trunc -63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "request-tracker.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "request-tracker.labels" -}}
helm.sh/chart: {{ include "request-tracker.chart" . }}
{{ include "request-tracker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "request-tracker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "request-tracker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "request-tracker.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "request-tracker.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
