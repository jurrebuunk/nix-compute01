{
  inputs,
  pkgs,
  vm,
}:

let
  domain = {
    type = "kvm";
    inherit (vm) name uuid;

    metadata = with inputs.NixVirt.lib.xml; [
      (elem "nixos:managed-by" [ (attr "xmlns:nixos" "https://nixos.org") ] "nix-compute01")
    ];
  }
  // import ./domain/boot.nix { inherit pkgs vm; }
  // import ./domain/cpu.nix { inherit vm; }
  // import ./domain/features.nix { }
  // import ./domain/lifecycle.nix { }
  // {
    devices = import ./domain/devices { inherit inputs pkgs vm; };

    # Make the passed-through boot VGA GPU behave as the VM VGA device.
    # Without this, OVMF/Windows can initialize but never light up the physical output.
    qemu-override.device = [
      {
        alias = "hostdev0";
        frontend.property = [
          {
            name = "x-vga";
            type = "bool";
            value = "true";
          }
        ];
      }
    ];
  };
in
inputs.NixVirt.lib.domain.writeXML domain
