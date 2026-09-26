{ vm }:

[
  {
    mode = "subsystem";
    type = "pci";
    managed = true;
    driver.name = "vfio";
    source.address = vm.gpu.video.pci;
    rom.bar = true;
  }
  {
    mode = "subsystem";
    type = "pci";
    managed = true;
    driver.name = "vfio";
    source.address = vm.gpu.audio.pci;
  }
]
