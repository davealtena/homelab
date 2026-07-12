{ config, lib, pkgs, ... }:

{
  # ---------------------------------------------------------------------------
  # Kernel modules + sysctls required by Kubernetes / Cilium.
  # ---------------------------------------------------------------------------
  boot.kernelModules = [ "br_netfilter" "overlay" ];
  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    # Controllers (Flux, Cilium, Prometheus, ...) are hungry for inotify watches.
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_user_watches" = 524288;
  };

  # This host has no swap (see hardware-configuration.nix), which keeps the
  # kubelet happy without extra flags.

  # ---------------------------------------------------------------------------
  # Pod DNS: give the kubelet a clean resolv.conf WITHOUT the DHCP-provided
  # "search altena.io". That domain has a catch-all wildcard upstream
  # (*.altena.io -> Cloudflare), so appending it to pod queries makes external
  # names like github.com resolve to the wildcard and breaks egress. CoreDNS
  # keeps forwarding via the host /etc/resolv.conf; only the search list that
  # kubelet merges into pods is affected.
  # ---------------------------------------------------------------------------
  environment.etc."rancher/k3s/resolv.conf".text = ''
    nameserver 192.168.1.1
    options edns0
  '';

  # Base directory for OpenEBS LocalPV hostpath (local NVMe cache/scratch tier;
  # the default StorageClass is Synology NFS). The provisioner creates per-PV
  # subdirectories here.
  systemd.tmpfiles.rules = [
    "d /var/mnt/local-hostpath 0755 root root -"
  ];

  # NFS client support (mount.nfs + kernel modules) so csi-driver-nfs can mount
  # the Synology exports via the host mount namespace.
  boot.supportedFilesystems = [ "nfs" ];

  # ---------------------------------------------------------------------------
  # k3s — single combined control-plane + worker node.
  #
  # Stripped of the components we replace:
  #   - flannel        -> Cilium is the CNI
  #   - kube-proxy     -> Cilium kube-proxy replacement
  #   - network policy -> Cilium
  #   - traefik        -> (Cilium Gateway API later)
  #   - servicelb      -> (Cilium L2/LB later)
  #   - local-storage  -> local-path-provisioner via Flux
  # ---------------------------------------------------------------------------
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--flannel-backend=none"
      "--disable-network-policy"
      "--disable-kube-proxy"
      "--disable=traefik"
      "--disable=servicelb"
      "--disable=local-storage"
      "--write-kubeconfig-mode=0644"
      "--tls-san=phobos"
      "--tls-san=phobos.altena.io"
      "--tls-san=192.168.1.100"
      "--tls-san=192.168.1.246"
      "--cluster-cidr=10.42.0.0/16"
      "--service-cidr=10.43.0.0/16"
      "--kubelet-arg=resolv-conf=/etc/rancher/k3s/resolv.conf"
    ];
  };

  # Put the NVIDIA Container Toolkit on k3s's PATH so k3s auto-detects the
  # nvidia-container-runtime at startup and wires it into its managed containerd
  # config (+ creates the `nvidia` RuntimeClass). Avoids hand-crafting a
  # containerd config.toml.tmpl. GPU pods then use runtimeClassName: nvidia.
  # `.tools` holds nvidia-container-runtime (the main output only ships nvidia-ctk).
  systemd.services.k3s.path = [ pkgs.nvidia-container-toolkit pkgs.nvidia-container-toolkit.tools ];

  # k3s CLI helpers (crictl, ctr) alongside the standalone kubectl in base.nix.
  environment.systemPackages = [ pkgs.k3s ];

  # Point root/dave at the k3s kubeconfig (world-readable via write-kubeconfig-mode).
  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
}
