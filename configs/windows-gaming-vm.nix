let
  gpu = import ./passthrough-gpu.nix;
  defaultNetwork = import ./default-network.nix;
in
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
    inherit (defaultNetwork) bridge;
  };

  inherit gpu;
}
