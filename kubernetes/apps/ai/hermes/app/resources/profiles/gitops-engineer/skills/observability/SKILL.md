---
name: observability
description: "Metrics, alerts, dashboards and logs of this cluster through the grafana-mcp tools: what to query for firing alerts, GPU/AI, backups, Flux and app health, and how to read VictoriaLogs."
version: 1.0.0
author: dave
license: MIT
metadata:
  hermes:
    tags: [grafana, prometheus, alertmanager, victorialogs, observability]
    related_skills: [flux-gitops, homelab-pr]
---

# Observability via grafana-mcp

Grafana (`grafana.altena.io`) fronts three datasources: **Prometheus** (default; kube-prometheus-stack, 30d), **Alertmanager** and **VictoriaLogs** (all pod logs). You hold a Viewer service account; write tools are disabled.

## Firing alerts

`grafana-mcp_query_prometheus(expr='ALERTS{alertstate="firing", alertname!~"Watchdog|InfoInhibitor"}')` lists what fires now (labels: alertname, severity, namespace, pod). For "since when": `ALERTS_FOR_STATE`. Rule definitions: `grafana-mcp_alerting_rules_read` (Grafana-managed) and the PrometheusRule objects via `kubectl-mcp_get_*`; the rule files live in `kubernetes/apps/observability/kube-prometheus-stack/app/alerts/` (ai-rules, media-rules, flux, dcgm, smartctl, blackbox, gatus).

## Metric families worth knowing

| Area | Metrics |
|------|---------|
| GPU | `DCGM_FI_DEV_GPU_UTIL`, `DCGM_FI_DEV_FB_USED/FREE` (MiB), `DCGM_FI_DEV_GPU_TEMP`, `DCGM_FI_DEV_POWER_USAGE` |
| LiteLLM | `litellm_requests_metric_total`, `litellm_input/output_tokens_metric_total`, `litellm_llm_api_failed_requests_metric_total`, `litellm_llm_api_time_to_first_token_metric_bucket`, `litellm_spend_metric_total` (by `model`) |
| Ollama | `container_cpu_usage_seconds_total{namespace="ai",pod=~"ollama-.*"}`, `container_memory_working_set_bytes` |
| Flux | `gotk_reconcile_condition`, `gotk_reconcile_duration_seconds` (kind, name, namespace) |
| Backups (kopiur) | `kopiur_*` (snapshot age/size/failures per policy) |
| Disks | `smartctl_device_temperature`, `node_filesystem_avail_bytes`, `node_disk_*` |
| Pods | `kube_pod_container_status_restarts_total`, `kube_pod_container_status_last_terminated_reason`, `kube_deployment_status_replicas_available` |
| Host (phobos) | `node_*` (one node), `comin_*` on :4243 if scraped |

Use `grafana-mcp_list_prometheus_metric_names(regex=...)` when unsure of a name, and `grafana-mcp_query_prometheus` with `stepSeconds`/`startTime` for ranges. Dashboards: `grafana-mcp_search_dashboards` then `grafana-mcp_get_dashboard_summary` and `grafana-mcp_run_panel_query` to reuse a panel's query instead of writing PromQL from scratch (folders: AI, Media, Databases, Flux, Kubernetes, Observability, Network, Security).

## Logs (VictoriaLogs, LogsQL)

Use the Loki tools with the `VictoriaLogs` datasource. Streams are keyed by `kubernetes.pod_namespace`, `kubernetes.pod_name`, `kubernetes.container_name`; useful fields: `_msg`, `_time`, `kubernetes.pod_labels.app.kubernetes.io/name`, `output_stream` (stdout/stderr). Examples:

- `{kubernetes.pod_namespace="ai", kubernetes.container_name="litellm"} error` last 1h
- `kubernetes.pod_labels.app.kubernetes.io/name:"hermes" AND _msg:"Traceback"`
- `{kubernetes.pod_namespace="flux-system"} "reconciliation failed"`

Always set a time range (`start`/`end`) and a stream selector; LogsQL is not LogQL, so do not use `|= ` pipes, use plain words or `_msg:"..."` filters.

## Reporting

Give the number, the unit and the time window. For an alert, add the rule's intent (file above) and the first evidence from logs or metrics, then the likely cause. Fixes still go through a PR (`/homelab-pr`).
