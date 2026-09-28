{ pkgs, vm }:

let
  gpuVideo = "0000:07:00.0";
  gpuAudio = "0000:07:00.1";
in
pkgs.writeShellApplication {
  name = "libvirt-qemu-gpu-handoff-hook";
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
    LOG_FILE="$LOG_DIR/$VM_NAME-gpu-handoff.log"

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

      for driver in efi-framebuffer simple-framebuffer vesa-framebuffer; do
        driver_dir="/sys/bus/platform/drivers/$driver"
        if [ -d "$driver_dir" ]; then
          for dev in "$driver_dir"/*; do
            [ -e "$dev" ] || continue
            dev_name="$(basename "$dev")"
            case "$dev_name" in
              bind|unbind|module|uevent) continue ;;
            esac
            printf '%s\n' "$dev_name" > "$driver_dir/unbind" || true
          done
        fi
      done
    }

    unload_nvidia() {
      # nvidia_drm/nvidia_modeset can keep the boot VGA device busy even without
      # a display manager. Unload them before binding the card to VFIO.
      timeout 10s modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia || true
    }

    bind_to_vfio() {
      dev="$1"

      if [ ! -e "/sys/bus/pci/devices/$dev" ]; then
        echo "$dev does not exist"
        return 0
      fi

      vendor="$(cat "/sys/bus/pci/devices/$dev/vendor")"
      device="$(cat "/sys/bus/pci/devices/$dev/device")"

      modprobe vfio-pci
      echo vfio-pci > "/sys/bus/pci/devices/$dev/driver_override" || true

      if [ -e "/sys/bus/pci/devices/$dev/driver/unbind" ]; then
        timeout 5s sh -c "printf '%s\\n' '$dev' > '/sys/bus/pci/devices/$dev/driver/unbind'" || true
      fi

      echo "$vendor $device" > /sys/bus/pci/drivers/vfio-pci/new_id || true
      timeout 5s sh -c "printf '%s\\n' '$dev' > /sys/bus/pci/drivers/vfio-pci/bind" || true
    }

    case "$operation/$suboperation" in
      prepare/begin)
        # One-way handoff on VM start only. We intentionally do not reattach the
        # NVIDIA driver on stop, because this machine previously wedged during
        # live NVIDIA reattach.
        systemctl stop display-manager.service || true
        unbind_framebuffer
        unload_nvidia
        bind_to_vfio "$GPU_AUDIO"
        bind_to_vfio "$GPU_VIDEO"
        ;;
      stopped/end|release/end)
        echo "Leaving GPU bound to vfio-pci; reboot to fully reset it for the host."
        ;;
    esac
  '';
}
