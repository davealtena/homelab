# Home Operations — Agent Guide

Single-cluster home Kubernetes monorepo, GitOps with Flux. Cluster: `valhalla`.
This file is the source of truth for AI agents working in this repo (Claude Code
reads it via `CLAUDE.md`, which imports it). General, stack-agnostic working
standards live in the user's global config and also apply.

## Layout

```
kubernetes/
├── apps/<namespace>/<app>/   # applications (Flux-managed)
├── components/               # reusable kustomize components
├── flux/                     # Flux entrypoint; flux/cluster/ks.yaml defines the
│                             #   `cluster-apps` Kustomization (path ./kubernetes/apps,
│                             #   SOPS-decrypted, dependsOn cluster-secrets)
└── bootstrap/                # bootstrap
talos/                        # Talos Linux machine configs
.taskfiles/ + Taskfile.yaml   # go-task ops (flux, kubernetes, sops, talos, bootstrap)
renovate.json5                # Renovate config
age.key                       # SOPS age key (do not commit secrets in plaintext)
```

## Stack

| Area          | Tool                                                              |
| ------------- | ---------------------------------------------------------------- |
| GitOps        | Flux (OCIRepository-sourced Helm charts)                         |
| CI            | Renovate + GitHub Actions                                       |
| Charts        | bjw-s `app-template` for most apps                              |
| Storage       | Rook/Ceph — `ceph-block` (RWO, default), `ceph-filesystem` (RWX) |
| Backups       | VolSync + Kopia                                                 |
| Secrets       | External Secrets + 1Password (ClusterSecretStore `onepassword-connect`); SOPS (age) for in-git secrets |
| Observability | VictoriaMetrics (vmsingle/vmagent/vmalert/vmalertmanager) + VictoriaLogs; alerts via VMRule → Pushover |
| Network       | Cilium, Envoy Gateway, external-dns                            |

## App conventions

Each app: `kubernetes/apps/<ns>/<app>/ks.yaml` + `.../app/{ocirepository,helmrelease,kustomization}.yaml` (+ `externalsecret.yaml` when secrets are needed; optional `app/resources/`).

- YAML LSP schema header right under `---`, e.g. `# yaml-language-server: $schema=https://k8s-schemas.bjw-s.dev/...`.
- `OCIRepository.spec.ref.tag` pinned to an explicit version (Renovate bumps via PR).
- `HelmRelease.spec.chartRef` → the OCIRepository; app-template apps configure `values.controllers/containers/service/route/persistence`.
- `ExternalSecret` pulls from 1Password (`remoteRef.key: <1pw item>`), consumed via `envFrom: secretRef` or `valueFrom`.
- `ks.yaml`: `metadata.name: &app <name>`, `targetNamespace`, `healthChecks`, `wait: true`, `dependsOn` where ordering matters.
- New app → also add its `ks.yaml` to the namespace `kustomization.yaml`. See the `add-app` skill.

## Common operations

- Reconcile: `flux reconcile source git flux-system` then `flux reconcile kustomization <name>` or `flux reconcile hr <name> -n <ns>`.
- Status: `flux get kustomizations -A`, `flux get hr -A`.
- go-task: `task flux:*`, `task kubernetes:*`, `task sops:*`, `task talos:*`.
- Prefer GitOps over live `kubectl` changes; if a live change is needed for triage, reconcile it back into Git.

## Repo-specific notes

Non-obvious "why is it like this" facts you can't infer from a single file:

- **CSI driver RBAC** comes from the separate `ceph-csi-drivers` HelmRelease (`apps/rook-ceph/ceph-csi-drivers`), not the rook chart — required since rook 1.20. Don't remove it.
- **`downloads/qbittorrent` VPN:** gluetun runs the ProtonVPN provider with *dynamic* server selection — only `WIREGUARD_PRIVATE_KEY` (+ `WIREGUARD_ADDRESSES`) in the secret, plus `SERVER_COUNTRIES` + `PORT_FORWARD_ONLY`. Do **not** pin `WIREGUARD_ENDPOINT_IP`/`WIREGUARD_PUBLIC_KEY` — it breaks on ProtonVPN server rotation (also noted inline).

## Conventions reminder

- Conventional commits + `--signoff` (`-s`).
- When adding/changing an app, copy the structure and schema headers of a nearby existing app rather than inventing fields.
- Verify against authoritative docs / proven references before hand-rolling config; cite the source.
