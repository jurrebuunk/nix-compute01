{ pkgs, ... }:

let
  gpuDevices = [
    "0000:07:00.0"
    "0000:07:00.1"
  ];
in
{
  boot.kernelParams = [
    # IOMMU passthrough mode: devices stay fast until assigned to VFIO.
    "iommu=pt"
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"
  ];

  # Do not bind the single NVIDIA GPU to vfio-pci in the initrd/early udev path.
  # On this machine that can make host boot appear to hang around systemd-udevd.
  # Instead, keep host NVIDIA drivers blacklisted and bind the GPU to VFIO from a
  # normal systemd service once userspace is up.
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

  systemd.services.bind-passthrough-gpu-to-vfio = {
    description = "Bind dedicated passthrough GPU to vfio-pci after host userspace is up";
    wantedBy = [ "multi-user.target" ];
    after = [
      "systemd-udev-settle.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    before = [ "libvirtd.service" ];
    path = [ pkgs.kmod ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 20;
    };
    script = ''
      set -u

      modprobe vfio-pci

      for dev in ${builtins.concatStringsSep " " gpuDevices}; do
        if [ ! -e "/sys/bus/pci/devices/$dev" ]; then
          echo "PCI device $dev not found; skipping"
          continue
        fi

        echo vfio-pci > "/sys/bus/pci/devices/$dev/driver_override"

        if [ -e "/sys/bus/pci/devices/$dev/driver/unbind" ]; then
          echo "$dev" > "/sys/bus/pci/devices/$dev/driver/unbind" || true
        fi
      done

      for dev in ${builtins.concatStringsSep " " gpuDevices}; do
        if [ -e "/sys/bus/pci/devices/$dev" ]; then
          echo "$dev" > /sys/bus/pci/drivers_probe || true
        fi
      done

      for dev in ${builtins.concatStringsSep " " gpuDevices}; do
        if [ -L "/sys/bus/pci/devices/$dev/driver" ]; then
          echo "$dev bound to $(basename "$(readlink -f "/sys/bus/pci/devices/$dev/driver")")"
        else
          echo "$dev is not bound to a driver yet"
        fi
      done
    '';
  };
}
