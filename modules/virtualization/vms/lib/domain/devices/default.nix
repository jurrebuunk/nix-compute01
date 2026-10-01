{ inputs, pkgs, vm }:

let
  networkInterface = if vm.network ? bridge then {
    type = "bridge";
    source.bridge = vm.network.bridge;
    model.type = "virtio";
  } else {
    type = "network";
    source.network = vm.network.network;
    model.type = "virtio";
  };
in
{
  emulator = "${pkgs.qemu_kvm}/bin/qemu-system-x86_64";

  disk = import ./disks.nix { inherit inputs vm; };
  controller = import ./controllers.nix { };
  hostdev = import ./passthrough.nix { inherit vm; };

  interface = networkInterface;

  input = [
    {
      type = "tablet";
      bus = "usb";
    }
    {
      type = "mouse";
      bus = "ps2";
    }
    {
      type = "keyboard";
      bus = "ps2";
    }
  ];

  tpm = {
    model = "tpm-crb";
    backend = {
      type = "emulator";
      version = "2.0";
    };
  };

  memballoon.model = "none";
}
