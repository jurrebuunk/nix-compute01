{ config, pkgs, ... }:

let
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.stable;
in
{
  # RTX 4060 / Ada Lovelace support.
  # Use the proprietary NVIDIA userspace with the open NVIDIA kernel module.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = nvidiaPackage;

    # Keep these off for a desktop/server-style discrete GPU unless we later
    # specifically tune suspend/resume power behavior.
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  # Make sure nouveau does not bind the RTX 4060 before the NVIDIA driver.
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Useful for checking/benchmarking after rebuild: nvidia-smi, vulkaninfo, nvtop.
  environment.systemPackages = with pkgs; [
    nvidiaPackage
    nvtopPackages.nvidia
    vulkan-tools
  ];
}
