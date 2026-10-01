{ vm }:

let
  gpu = vm.passthrough.gpu;
  managed = vm.passthrough.managed or false;
in
[
  {
    mode = "subsystem";
    type = "pci";
    inherit managed;
    driver.name = "vfio";
    source.address = gpu.video.pci;
    rom.bar = true;
  }
  {
    mode = "subsystem";
    type = "pci";
    inherit managed;
    driver.name = "vfio";
    source.address = gpu.audio.pci;
  }
]
