{
  description = "phobos — single-node Kubernetes homelab (NixOS 26.05 + k3s + Cilium + Flux)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # GitOps for the host: polls this repo and switches the system (see modules/comin.nix)
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, comin, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.phobos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          comin.nixosModules.comin
          ./hosts/phobos/default.nix
        ];
      };
    };
}
