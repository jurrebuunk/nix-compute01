{ ... }:

{
  boot.kernelParams = [
    # IOMMU passthrough mode: devices stay fast until assigned to VFIO.
    "iommu=pt"
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"
  ];

  # Keep host boot safe: do not bind the single NVIDIA GPU to vfio-pci during
  # boot. NVIDIA/nouveau are blacklisted below, so the host will not use the GPU
  # as a normal graphics device. Libvirt uses managed hostdev passthrough and
  # binds the GPU/audio functions to VFIO on VM start instead.
  boot.kernelModules = [ "kvm-amd" ];

  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';

  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];
}
