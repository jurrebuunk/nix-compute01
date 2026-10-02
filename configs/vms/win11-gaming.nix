let
  gpu = import ../hardware/passthrough-gpu.nix;
  lan = import ../hardware/network.nix;
in
{
  name = "win11-gaming";
  uuid = "c59b4c32-6f1a-4f51-91e8-8d9d27cb4db1";
  type = "windows";

  storage = {
    diskPath = "/var/lib/libvirt/images/win11-gaming.qcow2";
    diskSize = "500G";
    nvramPath = "/var/lib/libvirt/qemu/nvram/win11-gaming_VARS.fd";

    installIso = "/home/jurre/ISO/microwin11.iso";
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
    inherit (lan) bridge;
    # Windows has an inbox Intel e1000e driver, so networking works during install/OOBE.
    model = "e1000e";
  };

  passthrough = {
    inherit gpu;
    # Let libvirt bind/unbind the PCI devices to vfio-pci when the VM starts.
    managed = true;

    usbDevices = [
      {
        name = "rk-keyboard-wired";
        vendor = 9610; # 0x258a
        product = 73; # 0x0049
      }
    ];
  };
}
