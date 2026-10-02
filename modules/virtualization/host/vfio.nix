{ lib, ... }:

let
  gpu = import ../../../configs/hardware/passthrough-gpu.nix;
in
{
  # Bind the dedicated GPU to VFIO, but do not load VFIO in the initrd.
  # Loading VFIO in the initrd on a single/boot GPU can leave the machine stuck
  # at a black framebuffer before the normal userspace boot has completed.
  boot.kernelModules = [
    "kvm-amd"
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=${lib.concatStringsSep "," gpu.vfioIds}"
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"

    # Single/boot GPU passthrough: keep EFI/simple framebuffer drivers from
    # owning the RTX during Linux boot. This avoids the common vfio-pci vgaarb /
    # black-screen boot hang documented by the Arch PCI passthrough guide.
    "video=efifb:off"
    "video=vesafb:off"
    "initcall_blacklist=sysfb_init"
  ];

  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "i2c_nvidia_gpu"
  ];

  boot.extraModprobeConfig = ''
    options vfio-pci ids=${lib.concatStringsSep "," gpu.vfioIds}
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';
}
