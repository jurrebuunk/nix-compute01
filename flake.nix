{
  description = "Bare-bones NixOS flake for compute01";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      hardwareConfig = /etc/nixos/hardware-configuration.nix;

      mkHost = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          # Machine-specific and intentionally gitignored.
          # Use `--impure` when rebuilding so flakes can read it from /etc/nixos.
          ({ lib, ... }: {
            imports = lib.optional (builtins.pathExists hardwareConfig) hardwareConfig;
          })
          ./configuration.nix
          ./modules/nvidia.nix
        ];
      };
    in
    {
      nixosConfigurations.compute01 = mkHost;

      # Alias for the first rebuild while the current hostname is still `nixos`.
      nixosConfigurations.nixos = mkHost;
    };
}
