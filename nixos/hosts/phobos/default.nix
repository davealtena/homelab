{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/networking.nix
    ../../modules/ssh.nix
    ../../modules/nvidia.nix
    ../../modules/k3s.nix
  ];

  networking.hostName = "phobos";

  # NVIDIA: currently DISABLED — the RTX 5060 Ti is not yet visible on the PCIe
  # bus (only the AMD iGPU enumerates). Once `lspci | grep -i nvidia` shows the
  # card, flip this to true and rebuild (Phase 3). See docs/architecture.md.
  homelab.nvidia.enable = false;

  # Primary user. The SSH public key below is public by design (safe in Git).
  users.users.dave = {
    isNormalUser = true;
    description = "Dave";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxyL/1vlp8WlpEnPLz3YMtd/8/VGCtIR4gOuxzD4Hg7 dave@macbook"
    ];
  };

  # First release installed on this machine. Never change after install.
  system.stateVersion = "26.05";
}
