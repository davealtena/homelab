---
name: flux-gitops
description: "Inspect and troubleshoot Flux (Kustomizations, HelmReleases, sources) and the workloads behind them on this cluster with the read-only kubectl-mcp tools. Inspired by rohitg00/k8s-gitops (MIT-0), trimmed to Flux and this cluster's tool names."
version: 1.0.0
author: dave
license: MIT-0
metadata:
  hermes:
    tags: [flux, gitops, kubernetes, troubleshooting]
    related_skills: [homelab-pr, add-app]
---

# Flux GitOps on this cluster

Tools come from the ToolHive gateway with prefix `kubectl-mcp_` and are **read-only** for you. Write tools (`kubectl_patch`, `gitops_app_sync_tool`, `delete_resource`, `exec_in_pod`) are not available; if a reconcile, suspend or restart is needed, put it in the PR description or ask Dave.

Cluster facts: one node `phobos`; Flux Kustomizations live in their app namespace (bjw-s layout) and the root one is `phobos-apps` in `flux-system`; the Git source `flux-system` points at Forgejo; HelmReleases use `chartRef` to an OCIRepository in the same namespace.

## Triage order

1. Sources: `kubectl-mcp_gitops_sources_list_tool(namespace="flux-system")` and per namespace for OCIRepositories. A source that is not Ready blocks everything downstream.
2. Apps: `kubectl-mcp_gitops_apps_list_tool(namespace="<ns>")` lists Kustomizations and HelmReleases with Ready, Suspended and the last message. `kubectl-mcp_gitops_app_get_tool(kind="kustomization"|"helmrelease", name, namespace)` gives conditions, applied revision and `dependsOn`.
3. Workload: `kubectl-mcp_get_pods(namespace)`, `kubectl-mcp_get_events(namespace)`, `kubectl-mcp_get_logs(pod, namespace, container)`, `kubectl-mcp_get_previous_logs` after a restart, `kubectl-mcp_diagnose_pod_crash(pod, namespace)`, `kubectl-mcp_detect_pending_pods(namespace)`.
4. Specifics: `kubectl-mcp_certs_list_tool` / `certs_status_explain_tool` for TLS, `kubectl-mcp_cilium_status_tool` and `hubble_flows_query_tool` for network drops, `kubectl-mcp_get_pvcs` for storage, `kubectl-mcp_helm_status` / `helm_get_values` for what Helm actually rendered.

## Reading Flux messages

| Message | Meaning | Usual fix (via PR) |
|---------|---------|--------------------|
| `dependency '<ns>/<name>' is not ready` | a `dependsOn` target is failing or suspended | fix that target first |
| `health check failed ... stalled resources` | a `healthChecks`/`healthCheckExprs` target never became ready | look at the workload, or the expression is wrong (case of status values) |
| `dry-run failed ... field not declared in schema` | manifest uses a field the installed CRD lacks | CRD too old (chart `crds: CreateReplace`) or typo |
| `variable substitution failed ... not set (strict mode)` | `${VAR}` in a manifest that Flux envsubst cannot resolve | escape as `$${VAR}` or add the substitute |
| HelmRelease `upgrade retries exhausted` / `rollback` | chart values or image broke the release | read `helm_history` + pod logs, fix values |
| `Reconciliation in progress` for long | waiting on `wait: true` health | check pods/PVC/populator (kopiur restore) |

## Where things live in the repo

- App: `kubernetes/apps/<ns>/<app>/ks.yaml` + `app/{ocirepository,helmrelease,kustomization,externalsecret}.yaml`.
- Namespace wiring: `kubernetes/apps/<ns>/kustomization.yaml`.
- Backups: kopiur components under `kubernetes/components/kopiur/`; a restore-on-deploy PVC shows as a `Restore` object.
- Cluster-wide substitutions (`CLUSTER_DOMAIN`, NFS vars): `kubernetes/flux/ks.yaml`.
