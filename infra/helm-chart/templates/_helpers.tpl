# templates/_helpers.tpl

{{/*
Common labels
*/}}
{{- define "develeap.labels" -}}
app: {{ .Values.app.name }}
{{- end }}

{{/*
Selector labels - keeping them identical to common labels
for your service/deployment matching
*/}}
{{- define "develeap.selectorLabels" -}}
app: {{ .Values.app.name }}
{{- end }}

{{/*
Expand the name of the chart - simple version matching your style
*/}}
{{- define "develeap.name" -}}
{{- .Values.app.name -}}
{{- end }}