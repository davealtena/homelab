<div align="center">
  <img src="./docs/assets/talos.svg" alt="Talos Linux logo" width="150" height="150">
  <img src="./docs/assets/kubernetes.png" alt="Kubernetes logo" width="150" height="150">
</div>

<div align=center>

### My Home-ops Repository <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a5/512.gif" alt="⚡" width="16" height="16">

_... powered by Talos Linux and Kubernetes_

</div>

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

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1fa87/512.gif" alt="🪇" width="20" height="20"> Kubernetes

I'm running a [Talos](https://www.talos.dev)-powered Kubernetes environment on a single beefy Proxmox machine, which hosts all three control planes. The nodes manage the computational workloads, and currently, all configuration is stored on NFS until I can afford to buy some NUCs (like the cool kids do!). Once I get those NUCs, I plan to implement rook-ceph.

For now, I maintain a dedicated 24 TB ZFS server that handles NFS/SMB sharing, large-scale file storage, and backup operations.

### Core Components
- [cert-manager](https://github.com/cert-manager/cert-manager): Automatic SSL certificate provisioning for services in my cluster.
- [cilium](https://github.com/cilium/cilium): eBPF based Container Network Interface.
- [cloudflared](https://github.com/cloudflare/cloudflared): Enables Cloudflare secure access to certain ingresses.
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically syncs ingress DNS records to a DNS provider.
- [external-secrets](https://github.com/external-secrets/external-secrets): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx): Kubernetes ingress controller using NGINX as a reverse proxy and load balancer.
- [sops](https://github.com/getsops/sops): Managed secrets for Kubernetes and Terraform which are commited to Git.
- [volsync](https://github.com/backube/volsync): This is installed, next step is to configure it correctly. Choices on block storage, and _what_ I actually want to back-up still need to be made

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f38a/512.gif" alt="🏅" width="20" height="20"> Credits

Credits are where credits due, when I started implementing Talos on my own, a lot of studying went in, bumping in the cluster-template made life so much easier on many fronts. If you're just like me and like to "FAFO" your way forward, this is a perfect place to start the Talos/Flux journey. You can check out the example setup at [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template).

Also make sure to hop-in at the [home-operations discord server](https://discord.gg/848uFeEv)
