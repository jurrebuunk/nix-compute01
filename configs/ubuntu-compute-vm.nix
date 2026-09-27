let
  gpu = import ./passthrough-gpu.nix;
  defaultNetwork = import ./default-network.nix;
in
{
  name = "ubuntu-compute-vm";
  uuid = "8db9fb31-e7e2-48f8-9e88-f83419d74c64";

  storage = {
    diskPath = "/var/lib/libvirt/images/ubuntu-compute-vm.qcow2";
    diskSize = "250G";
    nvramPath = "/var/lib/libvirt/qemu/nvram/ubuntu-compute-vm_VARS.fd";
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
    inherit (defaultNetwork) bridge;
  };

  inherit gpu;
}
