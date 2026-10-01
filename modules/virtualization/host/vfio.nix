{ lib, ... }:

let
  gpu = import ../../../configs/hardware/passthrough-gpu.nix;
in
{
  # Bind the dedicated GPU to VFIO at boot. The host is managed headlessly over SSH.
  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  boot.kernelModules = [ "kvm-amd" ];

  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=${lib.concatStringsSep "," gpu.vfioIds}"
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"

    # If the boot framebuffer keeps the RTX BARs busy, uncomment this later:
    # "video=efifb:off"
  ];

  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];

  boot.extraModprobeConfig = ''
    options vfio-pci ids=${lib.concatStringsSep "," gpu.vfioIds}
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';
}
