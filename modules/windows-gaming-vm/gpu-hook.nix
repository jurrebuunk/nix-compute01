{ pkgs, vm }:

pkgs.writeShellApplication {
  name = "libvirt-qemu-hook";
  runtimeInputs = with pkgs; [
    coreutils
    gnugrep
    kmod
    libvirt
    systemd
  ];
  text = ''
    set -euo pipefail

    VM_NAME="${vm.name}"
    GPU_VIDEO="${vm.gpu.video.nodeDevice}"
    GPU_AUDIO="${vm.gpu.audio.nodeDevice}"
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

    bind_framebuffer() {
      if [ -e /sys/bus/platform/drivers/efi-framebuffer/bind ]; then
        echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind || true
      fi

      for vtconsole in /sys/class/vtconsole/vtcon*; do
        if [ -e "$vtconsole/name" ] && grep -qi "frame buffer" "$vtconsole/name"; then
          echo 1 > "$vtconsole/bind" || true
        fi
      done
    }

    detach_gpu() {
      systemctl stop display-manager.service || true
      unbind_framebuffer
      sleep 1

      modprobe -r nvidia_drm || true
      modprobe -r nvidia_modeset || true
      modprobe -r nvidia_uvm || true
      modprobe -r nvidia || true

      modprobe vfio-pci
      virsh nodedev-detach "$GPU_AUDIO" || true
      virsh nodedev-detach "$GPU_VIDEO" || true
    }

    reattach_gpu() {
      virsh nodedev-reattach "$GPU_VIDEO" || true
      virsh nodedev-reattach "$GPU_AUDIO" || true

      modprobe nvidia || true
      modprobe nvidia_uvm || true
      modprobe nvidia_modeset || true
      modprobe nvidia_drm || true

      bind_framebuffer
      systemctl start display-manager.service || true
    }

    case "$operation/$suboperation" in
      prepare/begin)
        detach_gpu
        ;;
      release/end)
        reattach_gpu
        ;;
    esac
  '';
}
