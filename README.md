<div align="center">
  <img src="./docs/assets/talos.svg" alt="Talos Linux logo" width="150" height="150">
  <img src="./docs/assets/kubernetes.png" alt="Kubernetes logo" width="150" height="150">
</div>

<div align="center">

### My Home-ops Repository <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a5/512.gif" alt="⚡" width="16" height="16">

_... powered by Talos Linux and Kubernetes_

</div>

<div align="center">

[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Ftalos_version&style=for-the-badge&logo=talos&logoColor=white&color=blue&label=%20)](https://talos.dev)&nbsp;
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

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f3d7_fe0f/512.gif" alt="🏗️" width="20" height="20"> Infrastructure

### Hardware

The Valhalla cluster runs on 3 dedicated bare-metal Dell Optiplex nodes, all control planes pulling double duty as workers:

| Node | Role | Hardware |
|------|------|----------|
| **Baldur** | Control Plane | Dell Optiplex (256GB SSD + 1TB storage) |
| **Freya** | Control Plane | Dell Optiplex (256GB SSD + 1TB storage) |
| **Heimdall** | Control Plane | Dell Optiplex (256GB SSD + 1TB storage) |

### Storage

Currently running everything on NFS backed by a dedicated 24 TB ZFS server that handles NFS/SMB file sharing, large-scale media storage, and backup operations. With the bare-metal nodes each having 1TB SSDs, rook-ceph distributed storage is on the roadmap.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1fa87/512.gif" alt="🪇" width="20" height="20"> Kubernetes

This is a [Talos Linux](https://www.talos.dev)-powered Kubernetes cluster managed with [FluxCD](https://fluxcd.io/) for GitOps. Everything you see here is automatically deployed and kept in sync from this Git repository.

### Core Components

**Networking**: Cilium provides eBPF-based networking and security, with ingress handled by NGINX. External DNS automatically manages Cloudflare records, and Cloudflare Tunnel enables secure external access.

**Security**: Certificates are automatically provisioned via cert-manager and Let's Encrypt. Secrets are managed through 1Password Connect (via external-secrets) and SOPS for Git-stored secrets.

**Storage**: OpenEBS provides local persistent volumes. Volsync is installed for backups (configuration in progress).

**Observability**: Complete monitoring stack with Prometheus, Grafana, and Loki. Kromgo powers the cluster metrics badges at the top of this README.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4fa/512.gif" alt="📺" width="20" height="20"> What's Running

**Media Automation**: Complete media management setup with Plex as the streaming platform, automated downloads via the *arr stack (Sonarr, Radarr, Prowlarr, Bazarr), and both torrent and usenet support.

**Home Automation**: Home Assistant handles all smart home devices and automations, with Zigbee devices connected via Zigbee2MQTT and EMQX as the MQTT broker.

**Productivity**: Actual Budget for personal finance tracking, and n8n for workflow automation.

**Infrastructure**: PostgreSQL clusters managed by CloudNative-PG for application databases.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif" alt="🚀" width="20" height="20"> Future Plans

- **Storage**: Migrate from NFS to rook-ceph using the 1TB SSDs on the bare-metal nodes
- **Backups**: Properly configure Volsync for automated persistent volume backups
- **Monitoring**: Expand Grafana dashboards and alerting rules
- **More Services**: Always looking for interesting self-hosted applications to add!

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f38a/512.gif" alt="🎊" width="20" height="20"> Credits

Credits are where credits are due. When I started implementing Talos on my own, a lot of studying went in. Bumping into the cluster-template made life so much easier on many fronts. If you're just like me and like to "FAFO" your way forward, this is a perfect place to start the Talos/Flux journey. You can check out the example setup at [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template).

Also make sure to hop in at the [Home Operations Discord server](https://discord.gg/home-operations) for an amazing community of homelabbers!

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4c4/512.gif" alt="📄" width="20" height="20"> License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
