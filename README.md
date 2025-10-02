<div align="center">
  <img src="./docs/assets/talos.svg" alt="Talos Linux logo" width="150" height="150">
  <img src="./docs/assets/kubernetes.png" alt="Kubernetes logo" width="150" height="150">
</div>

<div align=center>

### My Home-ops Repository <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a5/512.gif" alt="⚡" width="16" height="16">

_... powered by Talos Linux and Kubernetes_

</div>

<div align="center">
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Ftalos_version&style=for-the-badge&logo=talos&logoColor=fff&label=Talos&labelColor=302d41&color=cba6f7" alt="Talos version">
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=fff&label=Kubernetes&labelColor=302d41&color=cba6f7" alt="Kubernetes version">
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fflux_version&style=for-the-badge&logo=flux&logoColor=fff&label=Fluxcd&labelColor=302d41&color=cba6f7" alt="Fluxcd version">
  <img src="https://img.shields.io/github/issues-pr/davealtena/homelab?logo=github&color=f2cdcd&logoColor=fff&style=for-the-badge&labelColor=302d41" alt="Open Pull Requests">
</div>

<div align="center">
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_age_days&style=for-the-badge&label=Age&labelColor=302d41" alt="Cluster Age">
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_uptime_days&style=for-the-badge&label=Up&labelColor=302d41" alt="Cluster Up Time">
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_node_count&style=for-the-badge&label=Nodes&labelColor=302d41" alt="Cluster Nodes">
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_pod_count&style=for-the-badge&label=Pods&labelColor=302d41" alt="Cluster Pods">
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_cpu_usage&style=for-the-badge&label=Cpu&labelColor=302d41" alt="Cluster CPU">
  <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.altena.io%2Fcluster_memory_usage&style=for-the-badge&label=Memory&labelColor=302d41" alt="Cluster Memory">
</div>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f3d7_fe0f/512.gif" alt="🏗️" width="20" height="20"> Infrastructure

### Hardware
My entire Kubernetes cluster runs as VMs on a single beefy Proxmox machine. Yeah, not the most HA setup, but it gets the job done! The cluster consists of three control plane nodes that handle both the control plane and worker duties.


All nodes use a Virtual IP (VIP) at `192.168.1.101` for high availability access to the Kubernetes API.

### Storage
Currently running everything on NFS until I can afford to buy some proper NUCs (like the cool kids do!). Once I get those NUCs, the plan is to implement rook-ceph for distributed storage.

For now, I maintain a dedicated 24 TB ZFS server that handles:
- NFS/SMB file sharing
- Large-scale media storage
- Backup operations

The cluster uses OpenEBS for local storage provisioning on the nodes.

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1fa87/512.gif" alt="🪇" width="20" height="20"> Kubernetes

This is a [Talos Linux](https://www.talos.dev)-powered Kubernetes cluster managed with [FluxCD](https://fluxcd.io/) for GitOps. Everything you see here is automatically deployed and kept in sync from this Git repository.

### Core Components

#### Networking & Ingress
- [cilium](https://github.com/cilium/cilium): eBPF-based Container Network Interface providing networking, load balancing, and security
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx): Kubernetes ingress controller using NGINX as a reverse proxy and load balancer
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically syncs ingress DNS records to Cloudflare
- [cloudflared](https://github.com/cloudflare/cloudflared): Enables Cloudflare Tunnel for secure access to select services

#### Security & Secrets
- [cert-manager](https://github.com/cert-manager/cert-manager): Automatic SSL/TLS certificate provisioning via Let's Encrypt
- [external-secrets](https://github.com/external-secrets/external-secrets): Syncs secrets from 1Password Connect to Kubernetes
- [sops](https://github.com/getsops/sops): Encrypts secrets for safe storage in Git (both Kubernetes and Terraform)

#### Storage & Backup
- [openebs](https://openebs.io/): Provides local persistent volumes for stateful applications
- [volsync](https://github.com/backube/volsync): Installed and ready for configuration - next step is setting up backups once I finalize block storage strategy

#### Observability
- [kube-prometheus-stack](https://github.com/prometheus-operator/kube-prometheus-stack): Complete monitoring stack with Prometheus, Alertmanager, and Grafana
- [grafana](https://grafana.com/): Dashboards and visualization for all metrics
- [loki](https://grafana.com/oss/loki/): Log aggregation system
- [kromgo](https://github.com/kashalls/kromgo): Powers those nice status badges you see at the top of this README
- [node-exporter](https://github.com/prometheus/node_exporter): Hardware and OS metrics
- [blackbox-exporter](https://github.com/prometheus/blackbox_exporter): Endpoint monitoring and alerting

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4fa/512.gif" alt="📺" width="20" height="20"> Applications

### Media Stack
The full *arr stack for automated media management:
- [plex](https://www.plex.tv/): Media server for streaming movies and TV shows
- [jellyseerr](https://github.com/Fallenbagel/jellyseerr): Request management for Plex media
- [sonarr](https://sonarr.tv/): TV show management and automation
- [radarr](https://radarr.video/): Movie management and automation
- [prowlarr](https://prowlarr.com/): Indexer manager for Sonarr and Radarr
- [bazarr](https://www.bazarr.media/): Subtitle management for movies and TV shows
- [recyclarr](https://recyclarr.dev/): Automatically syncs TRaSH guides to Sonarr/Radarr for optimal quality profiles
- [qbittorrent](https://www.qbittorrent.org/): BitTorrent client with VPN integration
- [sabnzbd](https://sabnzbd.org/): Usenet download client
- [cross-seed](https://github.com/cross-seed/cross-seed): Automatically finds and adds cross-seeds for existing torrents

### Home Automation
- [home-assistant](https://www.home-assistant.io/): Central hub for all smart home devices and automations
- [zigbee2mqtt](https://www.zigbee2mqtt.io/): Zigbee to MQTT bridge for Zigbee devices
- [emqx](https://www.emqx.io/): MQTT broker for IoT device communication

### Self-Hosted Services
- [nextcloud](https://nextcloud.com/): Self-hosted file sync and share platform with office suite
- [actual-finance](https://actualbudget.org/): Privacy-focused budgeting and personal finance management
- [n8n](https://n8n.io/): Workflow automation platform (self-hosted alternative to Zapier)

### Databases
- [cloudnative-pg](https://cloudnative-pg.io/): PostgreSQL operator for Kubernetes, providing HA PostgreSQL clusters

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f6e0_fe0f/512.gif" alt="🛠️" width="20" height="20"> Tools & Automation

### GitOps
Everything is managed through Git using FluxCD. When I push changes to this repository, Flux automatically applies them to the cluster. Configuration is organized by namespace and application.

### Secret Management
Secrets are handled in two ways:
- Sensitive configuration files are encrypted with SOPS and can be safely committed to Git
- Application secrets are stored in 1Password and synced to the cluster via External Secrets Operator

### Task Automation
Using [Taskfile](https://taskfile.dev/) for common cluster operations. Check out the `Taskfile.yaml` and `.taskfiles/` directory for available commands.

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
