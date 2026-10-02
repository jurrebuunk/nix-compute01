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
  '';
}
