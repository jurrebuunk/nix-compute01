{
  name = "ubuntu-gaming";
  uuid = "8db9fb31-e7e2-48f8-9e88-f83419d74c64";

  storage = {
    diskPath = "/var/lib/libvirt/images/ubuntu-gaming.qcow2";
    diskSize = "250G";
    nvramPath = "/var/lib/libvirt/qemu/nvram/ubuntu-gaming_VARS.fd";
  };

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
  };

  gpu = {
    video = {
      pci = {
        domain = 0;
        bus = 7;
        slot = 0;
        function = 0;
      };
    };

    audio = {
      pci = {
        domain = 0;
        bus = 7;
        slot = 0;
        function = 1;
      };
    };
  };
}
