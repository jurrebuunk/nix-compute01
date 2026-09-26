{
  inputs,
  pkgs,
  vm,
}:

{
  emulator = "${pkgs.qemu_kvm}/bin/qemu-system-x86_64";

  disk = import ./disks.nix { inherit inputs vm; };
  controller = import ./controllers.nix { };
  hostdev = import ./passthrough.nix { inherit vm; };

  interface = {
    type = "network";
    source.network = vm.network.name;
    model.type = "virtio";
  };

  channel = {
    type = "spicevmc";
    target = {
      type = "virtio";
      name = "com.redhat.spice.0";
    };
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

  graphics = {
    type = "spice";
    autoport = true;
    listen = {
      type = "address";
      address = "127.0.0.1";
    };
    image.compression = false;
  };

  video.model = {
    type = "virtio";
    heads = 1;
    primary = true;
  };

  tpm = {
    model = "tpm-crb";
    backend = {
      type = "emulator";
      version = "2.0";
    };
  };

  memballoon.model = "none";
}
