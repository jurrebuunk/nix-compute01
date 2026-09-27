{ pkgs, vm }:

{
  emulator = "${pkgs.qemu_kvm}/bin/qemu-system-x86_64";

  disk = [
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

  controller = [
    {
      type = "pci";
      model = "pcie-root";
    }
    {
      type = "pci";
      model = "pcie-root-port";
      target = {
        chassis = 1;
        port = 16;
      };
    }
    {
      type = "usb";
      model = "qemu-xhci";
      ports = 15;
    }
    {
      type = "sata";
      index = 0;
    }
  ];

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

  hostdev = [
    {
      mode = "subsystem";
      type = "pci";
      managed = false;
      driver.name = "vfio";
      source.address = vm.gpu.video.pci;
      rom.bar = true;
    }
    {
      mode = "subsystem";
      type = "pci";
      managed = false;
      driver.name = "vfio";
      source.address = vm.gpu.audio.pci;
    }
  ];

  memballoon.model = "none";
}
