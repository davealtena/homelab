{ config, lib, ... }:
{
  # comin = GitOps for the host (the tuppr equivalent): polls the homelab repo on
  # Forgejo, evaluates nixosConfigurations.phobos from the `nixos/` subdirectory
  # and runs switch-to-configuration when `main` moves. Push to the testing
  # branch `testing-phobos` to try a configuration without making it the boot default.
  services.comin = {
    enable = true;
    hostname = config.networking.hostName;
    repositorySubdir = "nixos";
    remotes = [
      {
        name = "forgejo";
        url = "https://git.altena.io/dave/homelab.git";
        branches.main.name = "main";
        poller.period = 120;
      }
    ];
    exporter = {
      listen_address = "0.0.0.0";
      port = 4243;
      openFirewall = true;
    };
  };
}
