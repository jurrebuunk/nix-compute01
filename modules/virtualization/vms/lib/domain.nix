{ inputs, pkgs, vm }:

let
  domain = {
    type = "kvm";
    inherit (vm) name uuid;

    metadata = with inputs.NixVirt.lib.xml; [
      (elem "nixos:managed-by" [ (attr "xmlns:nixos" "https://nixos.org") ] "nix-compute01")
    ];
  }
  // import ./boot.nix { inherit pkgs vm; }
  // import ./cpu.nix { inherit vm; }
  // import ./features.nix { inherit vm; }
  // import ./lifecycle.nix { }
  // {
    devices = import ./domain/devices { inherit inputs pkgs vm; };
  };
in
inputs.NixVirt.lib.domain.writeXML domain
