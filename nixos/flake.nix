{
  description = "phobos — single-node Kubernetes homelab (NixOS 26.05 + k3s + Cilium + Flux)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.phobos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/phobos/default.nix
        ];
      };
    };
}
