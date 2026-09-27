{ ... }:

{
  boot.kernelParams = [
    # IOMMU passthrough mode: devices stay fast until assigned to VFIO.
    "iommu=pt"
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"
  ];

  boot.initrd.kernelModules = [
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
  ];

  boot.kernelModules = [
    "kvm-amd"
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
  ];

  # RTX 4060 + NVIDIA HDMI/DP audio are dedicated to VMs.
  # Host will not load NVIDIA for this GPU; reboot returns it to this VFIO state.
  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1 report_ignored_msrs=0
    options vfio-pci ids=10de:2882,10de:22be disable_vga=1
  '';

  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];
}
