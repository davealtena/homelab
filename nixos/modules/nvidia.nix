{ config, lib, pkgs, ... }:

let
  cfg = config.homelab.nvidia;
in
{
  options.homelab.nvidia.enable =
    lib.mkEnableOption "NVIDIA GPU support (open kernel modules + Container Toolkit) for the RTX 5060 Ti";

  config = lib.mkIf cfg.enable {
    # Load the NVIDIA driver.
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.graphics.enable = true;

    hardware.nvidia = {
      # The RTX 5060 Ti (Blackwell / GB206) requires the open kernel modules.
      open = true;
      modesetting.enable = true;
      nvidiaSettings = false; # headless server
      powerManagement.enable = false;

      # Driver package. `production` should support Blackwell on 26.05; if
      # nvidia-smi reports "GPU not supported", switch to `.beta` or `.latest`.
      package = config.boot.kernelPackages.nvidiaPackages.production;
    };

    # NVIDIA Container Toolkit — exposes the GPU to containerd/k3s via CDI.
    # k3s auto-detects the nvidia container runtime and wires up containerd.
    hardware.nvidia-container-toolkit.enable = true;
  };
}
