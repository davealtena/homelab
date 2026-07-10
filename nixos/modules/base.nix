{ config, lib, pkgs, ... }:

{
  # ---------------------------------------------------------------------------
  # Nix daemon: flakes + automatic maintenance
  # ---------------------------------------------------------------------------
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "dave" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Unfree needed for the NVIDIA driver / CUDA later on.
  nixpkgs.config.allowUnfree = true;

  # ---------------------------------------------------------------------------
  # Boot loader (systemd-boot / UEFI). Keep a bounded number of generations.
  # ---------------------------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---------------------------------------------------------------------------
  # Localisation — English system messages, Dutch regional formats.
  # ---------------------------------------------------------------------------
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
  };
  console.keyMap = "us";

  # ---------------------------------------------------------------------------
  # Shell
  # ---------------------------------------------------------------------------
  programs.zsh.enable = true;

  # Passwordless sudo for the wheel group. Deliberate homelab choice: SSH is
  # key-only and root login is disabled, so the attack surface is the SSH key.
  security.sudo.wheelNeedsPassword = false;

  # ---------------------------------------------------------------------------
  # Time synchronisation
  # ---------------------------------------------------------------------------
  services.chrony.enable = true;

  # ---------------------------------------------------------------------------
  # CPU / power management for a 24/7 server.
  # This host uses amd-pstate-epp in "active" mode, which only exposes the
  # "performance" and "powersave" governors. "performance" is chosen for
  # deterministic latency under Kubernetes/GPU workloads. Switch to "powersave"
  # (still boosts on demand under amd-pstate) for a lower idle-power profile.
  # ---------------------------------------------------------------------------
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  # ---------------------------------------------------------------------------
  # Storage health
  # ---------------------------------------------------------------------------
  services.fstrim.enable = true;
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.wall.enable = true;
  };

  # ---------------------------------------------------------------------------
  # Logging: bounded journald retention + logrotate.
  # ---------------------------------------------------------------------------
  services.journald.extraConfig = ''
    SystemMaxUse=2G
    SystemKeepFree=1G
    MaxRetentionSec=1month
  '';
  services.logrotate.enable = true;

  # ---------------------------------------------------------------------------
  # Host packages (minimal: diagnostics + Kubernetes toolchain + secrets/backup)
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # editors & basics
    neovim
    vim
    git
    curl
    wget
    # shell / tui
    tmux
    btop
    htop
    tree
    # data wrangling / search
    jq
    yq-go
    ripgrep
    fd
    # hardware & diagnostics
    pciutils
    usbutils
    nvme-cli
    smartmontools
    ethtool
    lm_sensors
    iproute2
    dnsutils
    # kubernetes toolchain
    kubectl
    kubernetes-helm
    fluxcd
    cilium-cli
    # secrets management
    age
    sops
    # backup
    kopia
  ];

  environment.variables.EDITOR = "nvim";
}
