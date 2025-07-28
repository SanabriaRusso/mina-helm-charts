{{/*
  Holds YAML for the container spec in the Mina daemon deployment.
*/}}
{{- define "mina-standard-daemon.container" -}}
- name: {{ .name | default "pod-container" }}
  {{- with .securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  image: {{ .image.repository | default "nginx" }}:{{ .image.tag | default "latest" }}
  imagePullPolicy: {{ .image.pullPolicy | default "IfNotPresent" }}
  {{- with .command }}
  command:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .args }}
  args:
    {{- toYaml . | nindent 4 }}
  {{- end -}}
  {{/*
    Adding extraArgs, if any
  */}}
  {{- with .extraArgs }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .ports }}
  ports:
    {{- toYaml . | nindent 4 }}
  {{- end -}}
  {{/*
    Adding extraPorts, if any
  */}}
  {{- with .extraPorts }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .env }}
  env:
    {{- toYaml . | nindent 4 }}
  {{- end -}}
  {{/*
    Adding extraEnv, if any
  */}}
  {{- with .extraEnv }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .volumeMounts }}
  volumeMounts:
    {{- toYaml . | nindent 4 }}
  {{- end -}}
  {{/*
    Adding extraVolumeMounts, if any
  */}}
  {{- with .extraVolumeMounts }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}