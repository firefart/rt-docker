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
app.kubernetes.io/name: rt
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
