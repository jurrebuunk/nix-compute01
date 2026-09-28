{ pkgs, vm }:

pkgs.writeShellApplication {
  name = "libvirt-qemu-hook";
  runtimeInputs = with pkgs; [
    coreutils
    gnugrep
    systemd
  ];
  text = ''
    set -euo pipefail

    VM_NAME="${vm.name}"
    LOG_DIR="/var/log/libvirt/qemu"
    LOG_FILE="$LOG_DIR/$VM_NAME-gpu-hook.log"

    mkdir -p "$LOG_DIR"
    exec >>"$LOG_FILE" 2>&1

    domain="''${1:-}"
    operation="''${2:-}"
    suboperation="''${3:-}"

    if [ "$domain" != "$VM_NAME" ]; then
      exit 0
    fi

    echo "[$(date --iso-8601=seconds)] $domain $operation/$suboperation"

    unbind_framebuffer() {
      for vtconsole in /sys/class/vtconsole/vtcon*; do
        if [ -e "$vtconsole/name" ] && grep -qi "frame buffer" "$vtconsole/name"; then
          echo 0 > "$vtconsole/bind" || true
        fi
      done

      if [ -e /sys/bus/platform/drivers/efi-framebuffer/efi-framebuffer.0 ]; then
        echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind || true
      fi
    }

    case "$operation/$suboperation" in
      prepare/begin)
        # Let libvirt's managed='yes' hostdev handling do the actual PCI detach
        # and vfio-pci bind. The hook only gets the host framebuffer out of the way.
        systemctl stop display-manager.service || true
        unbind_framebuffer
        ;;
      stopped/end|release/end)
        # Do not dynamically reattach the GPU to NVIDIA on this machine; that was
        # the path that wedged nvidia-modeset. Reboot to return GPU to host NVIDIA.
        echo "Leaving GPU handoff cleanup to libvirt; reboot to return GPU to host NVIDIA."
        ;;
    esac
  '';
}
