{ pkgs, vm }:

[
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
    boot.order = 2;
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
    boot.order = 1;
  }
  {
    type = "file";
    device = "cdrom";
    driver = {
      name = "qemu";
      type = "raw";
    };
    source.file = "${pkgs.virtio-win}/iso/virtio-win.iso";
    target = {
      dev = "sdb";
      bus = "sata";
    };
    readonly = true;
  }
]
