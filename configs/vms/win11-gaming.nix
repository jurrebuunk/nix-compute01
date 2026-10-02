let
  gpu = import ../hardware/passthrough-gpu.nix;
in
{
  name = "win11-gaming";
  uuid = "c59b4c32-6f1a-4f51-91e8-8d9d27cb4db1";
  type = "windows";

  storage = {
    diskPath = "/var/lib/libvirt/images/win11-gaming.qcow2";
    diskSize = "500G";
    nvramPath = "/var/lib/libvirt/qemu/nvram/win11-gaming_VARS.fd";
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
    # Use libvirt's default NAT network first. This avoids host bridge complexity.
    network = "default";
  };

  passthrough = {
    inherit gpu;
    # Let libvirt bind/unbind the PCI devices to vfio-pci when the VM starts.
    managed = true;
  };
}
