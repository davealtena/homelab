{ config, lib, pkgs, ... }:

{
  # NetworkManager stays in charge while WiFi is the (temporary) uplink. The
  # existing WiFi profile (with its PSK) lives statefully under
  # /etc/NetworkManager/system-connections and is intentionally kept out of Git.
  #
  # The Realtek NIC (enp5s0) is not cabled yet; once connected it comes up
  # automatically via NetworkManager DHCP. Set a DHCP reservation on the router
  # for a stable k3s API address (MACs are documented in docs/architecture.md).
  networking.networkmanager.enable = true;

  # ---------------------------------------------------------------------------
  # Firewall: only the ports we actually need. CNI (Cilium) traffic must not be
  # filtered, and reverse-path filtering is loosened for pod/service routing.
  # ---------------------------------------------------------------------------
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22   # SSH
      6443 # Kubernetes API (kubectl from the LAN)
    ];
    trustedInterfaces = [ "cilium_host" "cilium_net" "cilium_vxlan" "lxc+" "cni0" ];
    checkReversePath = "loose";
  };
}
