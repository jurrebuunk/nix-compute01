{ inputs, vm }:

let
  systemDisks = [
    {
      type = "file";
      device = "disk";
      driver = {
        name = "qemu";
        type = "qcow2";
        cache = "none";
        io = "native";
        discard = "unmap";
      };
      source.file = vm.storage.diskPath;
      target = {
        dev = "vda";
        bus = "virtio";
      };
    }
    {
      type = "file";
      device = "cdrom";
      driver = {
        name = "qemu";
        type = "raw";
      };
      target = {
        dev = "sda";
        bus = "sata";
      };
      readonly = true;
    }
  ];

  windowsDisks = [
    {
      type = "file";
      device = "cdrom";
      driver = {
        name = "qemu";
        type = "raw";
      };
      source.file = "${inputs.NixVirt.lib.guest-install.virtio-win.iso}";
      target = {
        dev = "sdb";
        bus = "sata";
      };
      readonly = true;
    }
  ];
in
systemDisks ++ (if (vm.type or "linux") == "windows" then windowsDisks else [ ])
