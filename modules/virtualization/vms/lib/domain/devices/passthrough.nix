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
    # Present the GPU and its HDMI-audio function as one multifunction PCIe
    # device to the guest, matching the physical device layout. Some Windows /
    # NVIDIA driver combinations are unstable when the functions appear on
    # separate guest root ports.
    address = {
      type = "pci";
      domain = 0;
      bus = 4;
      slot = 0;
      function = 0;
      multifunction = true;
    };
    rom = videoRom;
  }
  {
    mode = "subsystem";
    type = "pci";
    inherit managed;
    driver.name = "vfio";
    source.address = gpu.audio.pci;
    address = {
      type = "pci";
      domain = 0;
      bus = 4;
      slot = 0;
      function = 1;
    };
  }
] ++ map mkUsbHostdev (vm.passthrough.usbDevices or [ ])
