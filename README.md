<div align="center">
  <img src="./docs/assets/nixos.svg" alt="NixOS logo" width="150" height="150">
  <img src="./docs/assets/kubernetes.png" alt="Kubernetes logo" width="150" height="150">
</div>

<div align="center">

### My Home-ops Repository <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a5/512.gif" alt="⚡" width="16" height="16">

_... powered by NixOS and Kubernetes_

</div>

<div align="center">

[![NixOS](https://img.shields.io/badge/NixOS-26.05-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)&nbsp;
[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=white&color=blue&label=%20)](https://kubernetes.io)&nbsp;
[![Flux](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fflux_version&style=for-the-badge&logo=flux&logoColor=white&color=blue&label=%20)](https://fluxcd.io)&nbsp;
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/davealtena/homelab?logo=github&color=blue&logoColor=white&style=for-the-badge&label=%20)](https://github.com/davealtena/homelab/pulls)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo)&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo)&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo)&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo)&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo)&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo)

</div>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4d6/512.gif" alt="📖" width="20" height="20"> Overview

This repository is the single source of truth for my home lab. It declaratively
describes an entire self-hosted Kubernetes platform — from the bare-metal host OS
all the way up to the applications — so the whole thing can be rebuilt from Git:

- **Host**: [NixOS](https://nixos.org) defines the machine itself (kernel, drivers,
  networking, k3s) as a reproducible flake under [`nixos/`](./nixos).
- **Cluster**: a single-node [k3s](https://k3s.io) Kubernetes cluster, with the
  in-cluster state managed by [FluxCD](https://fluxcd.io) GitOps under
  [`kubernetes/`](./kubernetes). Everything you see here is deployed and kept in
  sync automatically from this repo.

> [!NOTE]
> This lab is mid-migration from a 3-node Talos cluster (`valhalla`) to the new
> single-node NixOS host (`phobos`, cluster `society`). The Talos tree still lives
> under [`kubernetes/apps/`](./kubernetes/apps) until the old nodes are fully
> decommissioned; the live cluster is defined under
> [`kubernetes/clusters/phobos/`](./kubernetes/clusters/phobos).

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f3d7_fe0f/512.gif" alt="🏗️" width="20" height="20"> Infrastructure

### Hardware

The `society` cluster runs on a single beefy node, **phobos**, doing double duty
as control plane and worker:

| Component | Spec |
|-----------|------|
| **CPU** | AMD Ryzen 9 9900X (12c / 24t) |
| **Memory** | 96 GB DDR5 |
| **Board** | ASRock B850M Pro RS WiFi |
| **Storage** | Samsung 980 1 TB NVMe (Btrfs root, no swap) |
| **GPU** | NVIDIA RTX 5060 Ti 16 GB |
| **OS** | NixOS 26.05 |

> [!NOTE]
> The RTX 5060 Ti is installed for future GPU workloads (local LLM inference and
> transcoding). GPU passthrough / the NVIDIA container stack isn't wired up yet —
> that's a follow-up once the migration settles.

### Storage

Persistent volumes live on a **Synology DS925+** (2x 12TB WD RED, SHR/Btrfs)
exported over NFS and provisioned by **csi-driver-nfs** — this is the default
StorageClass. **OpenEBS** hostpath provides a fast local-NVMe tier for latency-
sensitive workloads (databases, Prometheus). Because the app data physically
lives on the NAS, the Synology's own backups are the primary restore point;
PostgreSQL additionally gets a nightly logical dump onto the NAS.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1fa87/512.gif" alt="🪇" width="20" height="20"> Kubernetes

A single-node [k3s](https://k3s.io) cluster running on **NixOS** and managed with
[FluxCD](https://fluxcd.io/) for GitOps. k3s is stripped of its stock networking
(flannel, kube-proxy, servicelb, traefik, local-storage) so the components below
can take over.

### Core Components

**Networking**: [Cilium](https://cilium.io) provides eBPF-based networking as a
full kube-proxy replacement, with L2 announcements advertising LoadBalancer IPs
on the LAN. Ingress is handled by **Envoy Gateway** (Gateway API) via an internal
and an external gateway. **external-dns** manages Cloudflare and UniFi records,
and **Cloudflare Tunnel** provides secure external access.

**Security**: Certificates are provisioned automatically via cert-manager and
Let's Encrypt. Secrets come from 1Password Connect (via external-secrets), with
SOPS/age encrypting the handful of secrets stored in Git.

**Storage**: csi-driver-nfs backs PVCs on the Synology NAS (default class);
OpenEBS provides local hostpath volumes for the hot path.

**Databases**: PostgreSQL is managed by [CloudNative-PG](https://cloudnative-pg.io),
with a nightly logical backup CronJob dumping to the NAS.

**Observability**: [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts)
handles metrics and alerting (Prometheus + Alertmanager), **VictoriaLogs**
collects logs, and **Grafana** (via grafana-operator) renders the dashboards.
**blackbox-exporter** runs external probes, and **Kromgo** powers the cluster
metrics badges at the top of this README.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4fa/512.gif" alt="📺" width="20" height="20"> What's Running

**Media Automation**: Plex as the streaming platform, with automated downloads via
the *arr stack (Sonarr, Radarr, Prowlarr, Bazarr) and jellyseerr for requests —
both torrent and usenet supported.

**Home Automation**: Home Assistant drives all smart-home devices and automations,
with Zigbee devices connected via Zigbee2MQTT over a Mosquitto MQTT broker, plus
ESPHome for DIY devices.

**Productivity & Self-hosted**: Actual Budget (finance), Mealie (recipes), Forgejo
(Git), Paperless (documents), Bookboss, and n8n for workflow automation.

**AI**: LiteLLM as an LLM gateway plus assorted assistant workloads (destined for
the RTX once GPU support lands).

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif" alt="🚀" width="20" height="20"> Future Plans

- **GPU workloads**: Enable the NVIDIA container stack on the RTX 5060 Ti for local
  LLM inference and hardware transcoding
- **Decommission Talos**: Finish the migration and retire the old `valhalla` nodes
- **Offsite backups**: Sync the Synology backups to cloud object storage as a
  backup-of-the-backup
- **More Services**: Always looking for interesting self-hosted applications to add!

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f38a/512.gif" alt="🎊" width="20" height="20"> Credits

Credits are where credits are due. This lab started life on Talos Linux, and the
[onedr0p/cluster-template](https://github.com/onedr0p/cluster-template) made that
journey enormously easier — its structure still shapes the GitOps layout here even
after the move to NixOS + k3s. If you like to "FAFO" your way forward, it's a
perfect place to start.

Also make sure to hop in at the [Home Operations Discord server](https://discord.gg/home-operations) for an amazing community of homelabbers!

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4c4/512.gif" alt="📄" width="20" height="20"> License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
