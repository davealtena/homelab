<div align="center">
  <img src="./docs/assets/talos.svg" alt="Talos Linux logo" width="150" height="150">
  <img src="./docs/assets/kubernetes.png" alt="Kubernetes logo" width="150" height="150">
</div>

<div align="center">

### My Home-ops Repository <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a5/512.gif" alt="⚡" width="16" height="16">

_... powered by Talos Linux and Kubernetes_

</div>

<div align="center">

<a href="https://github.com/kashalls/kromgo/"><img src="https://kromgo.altena.io/talos_version?format=badge" alt="Talos"></a>&nbsp;
<a href="https://github.com/kashalls/kromgo/"><img src="https://kromgo.altena.io/kubernetes_version?format=badge" alt="Kubernetes"></a>&nbsp;
<a href="https://github.com/kashalls/kromgo/"><img src="https://kromgo.altena.io/flux_version?format=badge" alt="Flux"></a>&nbsp;
<img src="https://img.shields.io/github/issues-pr/davealtena/homelab?logo=github&color=f2cdcd&logoColor=fff&style=for-the-badge&labelColor=302d41" alt="Open Pull Requests">

</div>

<div align="center">

<a href="https://github.com/kashalls/kromgo/"><img src="https://kromgo.altena.io/cluster_age_days?format=badge" alt="Age"></a>&nbsp;
<a href="https://github.com/kashalls/kromgo/"><img src="https://kromgo.altena.io/cluster_uptime_days?format=badge" alt="Uptime"></a>&nbsp;
<a href="https://github.com/kashalls/kromgo/"><img src="https://kromgo.altena.io/cluster_node_count?format=badge" alt="Node-Count"></a>&nbsp;
<a href="https://github.com/kashalls/kromgo/"><img src="https://kromgo.altena.io/cluster_pod_count?format=badge" alt="Pod-Count"></a>&nbsp;
<a href="https://github.com/kashalls/kromgo/"><img src="https://kromgo.altena.io/cluster_cpu_usage?format=badge" alt="CPU-Usage"></a>&nbsp;
<a href="https://github.com/kashalls/kromgo/"><img src="https://kromgo.altena.io/cluster_memory_usage?format=badge" alt="Memory-Usage"></a>

</div>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f3d7_fe0f/512.gif" alt="🏗️" width="20" height="20"> Infrastructure

### Hardware
My entire Kubernetes cluster runs as VMs on a single beefy Proxmox machine. Yeah, not the most HA setup, but it gets the job done! The cluster consists of three control plane nodes (Odin, Thor, and Frigg) that handle both control plane and worker duties.

All nodes use a Virtual IP at `192.168.1.101` for high availability access to the Kubernetes API.

### Storage
Currently running everything on NFS until I can afford to buy some proper NUCs (like the cool kids do!). Once I get those NUCs, the plan is to implement rook-ceph for distributed storage.

For now, I maintain a dedicated 24 TB ZFS server that handles NFS/SMB file sharing, large-scale media storage, and backup operations.

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

**Productivity**: Nextcloud for file sync and collaboration, Actual Budget for personal finance tracking, and n8n for workflow automation.

**Infrastructure**: PostgreSQL clusters managed by CloudNative-PG for application databases.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif" alt="🚀" width="20" height="20"> Future Plans

- **Storage**: Migrate from NFS to rook-ceph once I get dedicated NUC hardware
- **Backups**: Properly configure Volsync for automated persistent volume backups
- **High Availability**: Move to proper bare-metal nodes instead of running everything as VMs on one Proxmox host
- **Monitoring**: Expand Grafana dashboards and alerting rules
- **More Services**: Always looking for interesting self-hosted applications to add!

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f38a/512.gif" alt="🎊" width="20" height="20"> Credits

Credits are where credits are due. When I started implementing Talos on my own, a lot of studying went in. Bumping into the cluster-template made life so much easier on many fronts. If you're just like me and like to "FAFO" your way forward, this is a perfect place to start the Talos/Flux journey. You can check out the example setup at [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template).

Also make sure to hop in at the [Home Operations Discord server](https://discord.gg/home-operations) for an amazing community of homelabbers!

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4c4/512.gif" alt="📄" width="20" height="20"> License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
