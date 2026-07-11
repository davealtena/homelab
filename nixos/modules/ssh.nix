{ config, lib, pkgs, ... }:

{
  # Key-only SSH. Password + keyboard-interactive auth disabled; root login off.
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
