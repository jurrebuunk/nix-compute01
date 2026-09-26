{
  name = "win11-gaming";
  uuid = "c59b4c32-6f1a-4f51-91e8-8d9d27cb4db1";

  storage = {
    # Sparse qcow2, so this is a max size, not immediate disk usage.
    diskPath = "/var/lib/libvirt/images/win11-gaming.qcow2";
    diskSize = "500G";

    # Per-VM UEFI vars file. Libvirt creates this from the OVMF template.
    nvramPath = "/var/lib/libvirt/qemu/nvram/win11-gaming_VARS.fd";
  };

  # Ryzen 7 5700X: pass the whole 8c/16t CPU through to the VM.
  cpu = {
    vcpus = 16;
    topology = {
      sockets = 1;
      cores = 8;
      threads = 2;
    };
  };

  memoryGiB = 32;

  network = {
    name = "default";
    bridge = "virbr0";
    uuid = "f5f1c6d0-07c6-4990-b88f-d344e31f979b";
    subnet = {
      address = "192.168.122.1";
      netmask = "255.255.255.0";
      dhcpStart = "192.168.122.2";
      dhcpEnd = "192.168.122.254";
    };
  };

  # RTX 4060 and its HDMI/DP audio function.
  gpu = {
    video = {
      nodeDevice = "pci_0000_07_00_0";
      pci = {
        domain = 0;
        bus = 7;
        slot = 0;
        function = 0;
      };
    };

    audio = {
      nodeDevice = "pci_0000_07_00_1";
      pci = {
        domain = 0;
        bus = 7;
        slot = 0;
        function = 1;
      };
    };
  };
}
