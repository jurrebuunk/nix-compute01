{ ... }:

{
  # Keep boot safe on this single/boot GPU host: do not bind the RTX to VFIO
  # during early boot. Libvirt will bind it with managed PCI hostdev attach when
  # a VM starts, after the qemu hook releases firmware/simple framebuffers.
  boot.kernelModules = [ "kvm-amd" ];

  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"
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
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';
}
