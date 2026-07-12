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

  # NVIDIA RTX 5060 Ti (Blackwell/GB206) — now seated and enumerating on the
  # PCIe bus (01:00.0 [10de:2d04]). Enables the open kernel modules + Container
  # Toolkit (see modules/nvidia.nix). Adding the card shifted PCI addressing:
  # WiFi is now wlp5s0 (was wlp4s0), ethernet enp6s0 (was enp5s0).
  homelab.nvidia.enable = true;

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
