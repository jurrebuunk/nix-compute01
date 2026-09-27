{ vm }:

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
]
