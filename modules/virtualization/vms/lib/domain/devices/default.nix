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

  # Do not automatically reset the guest when the passed-through GPU driver
  # hangs. Keeping the VM paused/hung makes the failure diagnosable instead of
  # looking like a spontaneous Windows reboot.
  watchdog = {
    model = "itco";
    action = "none";
  };

  memballoon.model = "none";
}
