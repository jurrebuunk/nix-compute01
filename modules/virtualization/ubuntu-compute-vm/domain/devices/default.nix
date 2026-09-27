{ pkgs, vm }:

{
  emulator = "${pkgs.qemu_kvm}/bin/qemu-system-x86_64";

  disk = import ./disks.nix { inherit vm; };
  controller = import ./controllers.nix { };
  hostdev = import ./passthrough.nix { inherit vm; };

  interface = {
    type = "network";
    source.network = vm.network.name;
    model.type = "virtio";
  };

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

  memballoon.model = "none";
}
