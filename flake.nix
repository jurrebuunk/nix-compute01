{
  description = "Bare-bones NixOS flake for compute01";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    NixVirt = {
      # Pinned because NixVirt's GitHub master can break; update deliberately.
      url = "github:AshleyYakeley/NixVirt/6d213ab42f72ba41c2eb4e6bdb97581c0642d942";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      hardwareConfig = /etc/nixos/hardware-configuration.nix;

      mkHost = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          inputs.NixVirt.nixosModules.default

          # Machine-specific and intentionally gitignored.
          # Use `--impure` when rebuilding so flakes can read it from /etc/nixos.
          (
            { lib, ... }:
            {
              imports = lib.optional (builtins.pathExists hardwareConfig) hardwareConfig;
            }
          )
          ./configuration.nix
          ./modules/hardware-sensors.nix
          ./modules/virtualization
        ];
      };
    in
    {
      nixosConfigurations.compute01 = mkHost;

      # Alias for the first rebuild while the current hostname is still `nixos`.
      nixosConfigurations.nixos = mkHost;
    };
}
