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

{{/*
Name of the Secret holding the database credentials.
Uses db.existingSecret when set, otherwise the chart-managed "rt-db-creds".
*/}}
{{- define "request-tracker.dbSecretName" -}}
{{- if .Values.db.existingSecret -}}
{{- .Values.db.existingSecret -}}
{{- else -}}
rt-db-creds
{{- end -}}
{{- end }}

{{/*
The container image tag for the rt image, defaulting to the chart appVersion.
*/}}
{{- define "request-tracker.rtImageTag" -}}
{{- .Values.rt.image.tag | default .Chart.AppVersion -}}
{{- end }}

{{/*
Validate value combinations that would otherwise fail silently at runtime.
*/}}
{{- define "request-tracker.validateValues" -}}
{{- $multiReplica := or .Values.rt.autoscaling.enabled (gt (int .Values.rt.replicaCount) 1) -}}
{{- if $multiReplica -}}
{{- range $name, $pvc := .Values.pvc -}}
{{- if and $pvc.enabled (eq $pvc.accessMode "ReadWriteOnce") -}}
{{- if not (or (eq $name "postgresData") (eq $name "caddyData") (eq $name "caddyConfig")) -}}
{{- fail (printf "pvc.%s uses ReadWriteOnce but rt runs with multiple replicas; this volume is mounted by every rt pod and must be ReadWriteMany. Set pvc.%s.accessMode=ReadWriteMany or rt.replicaCount=1." $name $name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}
