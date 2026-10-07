{ inputs, pkgs, vm }:

let
  networkModel = vm.network.model or "virtio";

  networkInterface = if vm.network ? bridge then {
    type = "bridge";
    source.bridge = vm.network.bridge;
    model.type = networkModel;
  } else {
    type = "network";
    source.network = vm.network.network;
    model.type = networkModel;
  };
in
{
  emulator = "${pkgs.qemu_kvm}/bin/qemu-system-x86_64";

  disk = import ./disks.nix { inherit inputs vm; };
  controller = import ./controllers.nix { };
  hostdev = import ./passthrough.nix { inherit vm; };

  interface = networkInterface;

  # Fallback console for recovery/debugging when the passed-through GPU output
  # switches to an unsupported mode in the guest.
  graphics = {
    type = "vnc";
    autoport = true;
    listen = {
      type = "address";
      address = "127.0.0.1";
    };
  };

  video.model = {
    type = "vga";
    heads = 1;
    primary = true;
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

  tpm = {
    model = "tpm-crb";
    backend = {
      type = "emulator";
      version = "2.0";
    };
  };

  memballoon.model = "none";
}
