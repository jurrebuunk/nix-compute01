{ pkgs }:

pkgs.writeShellApplication {
  name = "libvirt-qemu-single-gpu-prepare";

  runtimeInputs = with pkgs; [
    bash
    coreutils
    kmod
  ];

  text = ''
    set -euo pipefail

    operation="''${2:-}"
    suboperation="''${3:-}"

    # Libvirt calls qemu hooks as: <domain> <operation> <suboperation> ...
    # For a single/boot GPU host, keep the GPU usable for firmware/boot, then
    # release Linux framebuffers only when a VM is actually about to start.
    if [ "$operation/$suboperation" != "prepare/begin" ]; then
      exit 0
    fi

    # Unbind framebuffer consoles. This prevents fbcon/simpledrm/efifb from
    # keeping the boot GPU busy when libvirt tries to attach it to vfio-pci.
    for vtcon in /sys/class/vtconsole/vtcon*; do
      [ -e "$vtcon/bind" ] || continue
      if [ -e "$vtcon/name" ] && grep -qi "frame buffer" "$vtcon/name"; then
        echo 0 > "$vtcon/bind" || true
      fi
    done

    # Unbind firmware/simple platform framebuffers if present.
    for driver in efi-framebuffer simple-framebuffer; do
      driver_path="/sys/bus/platform/drivers/$driver"
      [ -d "$driver_path" ] || continue

      for dev in "$driver_path"/*; do
        [ -L "$dev" ] || continue
        dev_name="$(basename "$dev")"
        echo "$dev_name" > "$driver_path/unbind" || true
      done
    done

    # Ensure VFIO modules are available before libvirt performs managed attach.
    modprobe vfio || true
    modprobe vfio_iommu_type1 || true
    modprobe vfio_pci || true

    # The RTX is the firmware boot GPU, and the host can still bind ancillary
    # functions (notably NVIDIA HDA audio) before a VM starts. Make the handoff
    # deterministic without binding the boot GPU in initrd (which can make this
    # single-GPU server unbootable/headless before networking).
    for dev in 0000:07:00.0 0000:07:00.1; do
      dev_path="/sys/bus/pci/devices/$dev"
      [ -e "$dev_path" ] || continue

      # Keep the device out of runtime power-save while it is handed to vfio.
      if [ -w "$dev_path/power/control" ]; then
        echo on > "$dev_path/power/control" || true
      fi

      # Force vfio-pci as the next driver, then unbind any current host driver
      # such as snd_hda_intel on the GPU audio function.
      if [ -w "$dev_path/driver_override" ]; then
        echo vfio-pci > "$dev_path/driver_override" || true
      fi

      if [ -L "$dev_path/driver" ]; then
        current_driver="$(basename "$(readlink -f "$dev_path/driver")")"
        if [ "$current_driver" != "vfio-pci" ]; then
          echo "$dev" > "$dev_path/driver/unbind" || true
        fi
      fi

      if [ -w /sys/bus/pci/drivers/vfio-pci/bind ]; then
        echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind || true
      fi
    done
  '';
}
