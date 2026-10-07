{ ... }:

let
  # RTX 4060 + HDMI audio. Keep in sync with configs/hardware/passthrough-gpu.nix.
  vfioIds = "10de:2882,10de:22be";
in
{
  # Bind the RTX to VFIO during early boot. This avoids the host briefly owning
  # the boot GPU/audio before libvirt starts the Windows guest, which can make
  # the NVIDIA Windows driver unstable when it enters accelerated power states.
  boot.initrd.kernelModules = [
    "vfio"
    "vfio_pci"
    "vfio_iommu_type1"
  ];

  boot.kernelModules = [ "kvm-amd" ];

  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"
    "vfio-pci.ids=${vfioIds}"
    "vfio-pci.disable_idle_d3=1"
    "pcie_aspm=off"
    # Prevent the firmware framebuffer/simpledrm from keeping the boot GPU busy.
    "initcall_blacklist=sysfb_init"
  ];

  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidiafb"
    "i2c_nvidia_gpu"
  ];

  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1 report_ignored_msrs=0
    options vfio-pci ids=${vfioIds} disable_idle_d3=1
  '';
}
