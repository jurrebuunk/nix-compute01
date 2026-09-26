{
  name = "win11-gaming";

  # Sparse qcow2, so this is a max size, not immediate disk usage.
  diskPath = "/var/lib/libvirt/images/win11-gaming.qcow2";
  diskSize = "500G";

  # Ryzen 7 5700X: pass the whole 8c/16t CPU through to the VM.
  memoryGiB = 32;
  vcpus = 16;
  cpuTopology = {
    sockets = 1;
    cores = 8;
    threads = 2;
  };

  # RTX 4060 and its HDMI/DP audio function.
  gpu = {
    video = {
      domain = "0x0000";
      bus = "0x07";
      slot = "0x00";
      function = "0x0";
      nodeDevice = "pci_0000_07_00_0";
    };

    audio = {
      domain = "0x0000";
      bus = "0x07";
      slot = "0x00";
      function = "0x1";
      nodeDevice = "pci_0000_07_00_1";
    };
  };
}
