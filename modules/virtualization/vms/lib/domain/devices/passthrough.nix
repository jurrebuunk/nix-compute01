{ vm }:

let
  gpu = vm.passthrough.gpu;
  managed = vm.passthrough.managed or false;

  videoRom = { bar = true; } // (
    if (gpu.video ? romFile) && gpu.video.romFile != null then {
      file = gpu.video.romFile;
    } else { }
  );

  mkUsbHostdev = device: {
    mode = "subsystem";
    type = "usb";
    managed = true;
    source = {
      startupPolicy = "optional";
      vendor.id = device.vendor;
      product.id = device.product;
    };
  };
in
[
  {
    mode = "subsystem";
    type = "pci";
    inherit managed;
    driver = {
      name = "vfio";
      "x-vga" = "on";
    };
    source.address = gpu.video.pci;
    rom = videoRom;
  }
  {
    mode = "subsystem";
    type = "pci";
    inherit managed;
    driver.name = "vfio";
    source.address = gpu.audio.pci;
  }
] ++ map mkUsbHostdev (vm.passthrough.usbDevices or [ ])
