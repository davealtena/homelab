# Architecture

A system-level overview of this home lab: what it is, what runs it, and how a
change gets from a Git commit to the running cluster. This describes intent and
structure — the manifests under `kubernetes/` and `nixos/` remain the source of
truth for exact configuration.

## High-Level Overview

This repository is the single source of truth for a **single-node home
Kubernetes cluster**. Everything from the host operating system up to the
applications is declared in Git and reconciled automatically, so the whole
system can be rebuilt from this repo.

| Layer   | Technology                     | Defined in      |
| ------- | ------------------------------ | --------------- |
| Host    | NixOS 26.05 (flake)            | `nixos/`        |
| Cluster | k3s (single node)              | `nixos/modules/k3s.nix` |
| GitOps  | Flux                           | `kubernetes/flux/` |
| Apps    | Helm releases via Flux         | `kubernetes/apps/` |

- **Node:** `phobos` — one machine acting as both control plane and worker.
- **Cluster:** `society`.

## Hardware

| Component | Spec |
| --------- | ---- |
| CPU       | AMD Ryzen 9 9900X (12c / 24t) |
| Memory    | 96 GB DDR5 |
| Storage   | Samsung 980 1 TB NVMe (Btrfs root) |
| GPU       | NVIDIA RTX 5060 Ti 16 GB (intended for local LLM inference and transcoding) |
| NAS       | Synology DS925+ (2x 12 TB WD RED, SHR/Btrfs) — persistent volumes over NFS |

Application data physically lives on the Synology and is exported over NFS, so
the NAS's own snapshots/backups are the primary restore point. PostgreSQL also
gets a nightly logical dump onto the NAS.

## Why single-node

This lab previously ran as a multi-node cluster. It was consolidated onto one
capable machine with a GPU because the workload that matters most going forward
is **local AI/GPU inference**, which benefits from one strong node rather than
several weak ones. See `docs/adr/` for the host-OS decision record.

## GitOps Flow

```
Git push → Flux Git source sync → Kustomization → HelmRelease → k8s resources
```

1. A change is committed and pushed to this repo.
2. **Renovate** opens PRs for dependency/image updates; routine bumps auto-merge.
3. **Flux** detects the change via its Git source.
4. Flux applies the `phobos-apps` Kustomization (`kubernetes/flux/ks.yaml`),
   which recursively applies everything under `kubernetes/apps/`.
5. Each app's `HelmRelease` renders and installs the workload.

Host-level (OS) changes are **not** GitOps — they are applied by editing
`nixos/` and running the NixOS rebuild task (see `AGENTS.md` → Common
operations).

## Repository Layout

```
kubernetes/
├── apps/<namespace>/<app>/   # applications, Flux-managed
└── flux/                     # Flux entrypoint (phobos-apps Kustomization)
kubernetes/components/        # reusable manifests (e.g. kanidm-oauth2)
nixos/                        # NixOS flake for the phobos host
.mise.toml                    # mise: pinned tools + operational tasks
.sops.yaml                    # SOPS age encryption rules
docs/                         # this documentation
```

Application namespaces: `ai`, `cert-manager`, `databases`, `downloads`,
`home-automation`, `kube-system`, `media`, `network`, `observability`,
`openebs-system`, `security`, `selfhosted`.

## Core Components

**Networking** — Cilium provides eBPF networking as a full kube-proxy
replacement, with L2 announcements advertising LoadBalancer IPs on the LAN.
Ingress is handled by Envoy Gateway (Gateway API). external-dns manages
Cloudflare and UniFi records, and Cloudflare Tunnel provides external access.

**Security** — Certificates via cert-manager + Let's Encrypt. Secrets come from
1Password Connect (via External Secrets); SOPS/age encrypts the few secrets
stored in Git. Single sign-on is provided by Kanidm (OIDC).

**Storage** — csi-driver-nfs backs PVCs on the Synology NAS (default class);
OpenEBS hostpath provides a fast local-NVMe tier for latency-sensitive
workloads (databases, Prometheus).

**Databases** — PostgreSQL managed by CloudNative-PG, with a nightly logical
backup CronJob dumping to the NAS.

**Observability** — kube-prometheus-stack (Prometheus + Alertmanager) for
metrics, VictoriaLogs for logs, and Grafana (via grafana-operator) for
dashboards.

## What's Running

- **Media** — Plex plus the *arr stack (Sonarr, Radarr, Prowlarr, Bazarr) and
  jellyseerr for requests.
- **Home automation** — Home Assistant, Zigbee2MQTT over Mosquitto, ESPHome.
- **Productivity / self-hosted** — Actual Budget, Mealie, Forgejo, Paperless,
  Bookboss, n8n.
- **AI** — LiteLLM as an LLM gateway, with GPU-backed inference workloads
  planned on the RTX.

## Where to Look Next

- **Working in the repo (conventions, gotchas, operations):** `AGENTS.md`
- **Why key decisions were made:** `docs/adr/`
- **When something breaks:** `docs/runbook.md` *(planned)*
