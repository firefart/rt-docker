{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "request-tracker.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "request-tracker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "request-tracker.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "request-tracker.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "request-tracker.postgresName" -}}{{ include "request-tracker.fullname" . }}-db{{- end }}
{{- define "request-tracker.dbHost" -}}{{ .Values.db.host | default (include "request-tracker.postgresName" .) }}{{- end }}
{{- define "request-tracker.caddyName" -}}{{ include "request-tracker.fullname" . }}-caddy{{- end }}
{{- define "request-tracker.mailgateName" -}}{{ include "request-tracker.fullname" . }}-mailgate{{- end }}
{{- define "request-tracker.configName" -}}{{ include "request-tracker.fullname" . }}-config{{- end }}
{{- define "request-tracker.mailSecretName" -}}
{{- .Values.mail.existingSecret | default (printf "%s-mail" (include "request-tracker.fullname" .)) -}}
{{- end }}

{{- define "request-tracker.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- include "request-tracker.fullname" . -}}
{{- else -}}
{{- required "serviceAccount.name is required when serviceAccount.create is false" .Values.serviceAccount.name -}}
{{- end -}}
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
Name of the Secret holding the database credentials.
Uses db.existingSecret when set, otherwise a release-scoped chart Secret.
*/}}
{{- define "request-tracker.dbSecretName" -}}
{{- if .Values.db.existingSecret -}}
{{- .Values.db.existingSecret -}}
{{- else -}}
{{ include "request-tracker.fullname" . }}-db-creds
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
{{- if ne $name "postgresData" -}}
{{- fail (printf "pvc.%s uses ReadWriteOnce but rt runs with multiple replicas; this volume is mounted by every rt pod and must be ReadWriteMany. Set pvc.%s.accessMode=ReadWriteMany or rt.replicaCount=1." $name $name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}
