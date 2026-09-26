{ ... }:

{
  boot.kernelParams = [
    # IOMMU passthrough mode: devices stay fast on the host until assigned to VFIO.
    "iommu=pt"
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"
  ];

  boot.kernelModules = [
    "kvm-amd"
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
  ];

  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1 report_ignored_msrs=0
    options vfio-pci disable_vga=1
  '';
}
