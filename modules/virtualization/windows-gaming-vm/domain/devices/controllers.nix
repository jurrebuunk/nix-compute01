{ }:

[
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
  {
    type = "virtio-serial";
    index = 0;
  }
]
