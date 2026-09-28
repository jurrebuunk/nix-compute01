{ pkgs, vm }:

let
  gpuVideo = "0000:07:00.0";
  gpuAudio = "0000:07:00.1";
in
pkgs.writeShellApplication {
  name = "libvirt-qemu-hook";
  runtimeInputs = with pkgs; [
    coreutils
    gnugrep
    kmod
    systemd
  ];
  text = ''
    set -euo pipefail

    VM_NAME="${vm.name}"
    GPU_VIDEO="${gpuVideo}"
    GPU_AUDIO="${gpuAudio}"
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

    bind_to_vfio() {
      dev="$1"
      vendor="$(cat "/sys/bus/pci/devices/$dev/vendor")"
      device="$(cat "/sys/bus/pci/devices/$dev/device")"

      modprobe vfio-pci

      if [ -e "/sys/bus/pci/devices/$dev/driver/unbind" ]; then
        echo "$dev" > "/sys/bus/pci/devices/$dev/driver/unbind" || true
      fi

      echo "$vendor $device" > /sys/bus/pci/drivers/vfio-pci/new_id || true
      echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind || true
    }

    case "$operation/$suboperation" in
      prepare/begin)
        # One-way handoff: host owns GPU after boot; VM owns GPU after first VM start.
        # We intentionally do not reattach to NVIDIA on VM stop because this machine
        # wedges in nvidia-modeset during dynamic single-GPU reattach.
        systemctl stop display-manager.service || true
        unbind_framebuffer
        bind_to_vfio "$GPU_AUDIO"
        bind_to_vfio "$GPU_VIDEO"
        ;;
      stopped/end|release/end)
        echo "Leaving GPU bound to vfio-pci; reboot to return it to the host NVIDIA driver."
        ;;
    esac
  '';
}
