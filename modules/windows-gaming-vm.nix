{ config, pkgs, ... }:

let
  vm = import ../configs/gaming-vm.nix;

  defaultNetworkXml = pkgs.writeText "libvirt-default-network.xml" ''
    <network>
      <name>default</name>
      <forward mode='nat'/>
      <bridge name='virbr0' stp='on' delay='0'/>
      <ip address='192.168.122.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.122.2' end='192.168.122.254'/>
        </dhcp>
      </ip>
    </network>
  '';

  domainXml = pkgs.writeText "${vm.name}.xml" ''
    <domain type='kvm'>
      <name>${vm.name}</name>
      <metadata>
        <nixos:managed-by xmlns:nixos='https://nixos.org'>nix-compute01</nixos:managed-by>
      </metadata>

      <memory unit='GiB'>${toString vm.memoryGiB}</memory>
      <currentMemory unit='GiB'>${toString vm.memoryGiB}</currentMemory>
      <vcpu placement='static'>${toString vm.vcpus}</vcpu>
      <iothreads>1</iothreads>

      <os firmware='efi'>
        <type arch='x86_64' machine='q35'>hvm</type>
        <firmware>
          <feature enabled='no' name='secure-boot'/>
        </firmware>
        <boot dev='cdrom'/>
        <boot dev='hd'/>
      </os>

      <features>
        <acpi/>
        <apic/>
        <hyperv mode='custom'>
          <relaxed state='on'/>
          <vapic state='on'/>
          <spinlocks state='on' retries='8191'/>
          <vpindex state='on'/>
          <runtime state='on'/>
          <synic state='on'/>
          <stimer state='on'/>
          <frequencies state='on'/>
          <tlbflush state='on'/>
          <ipi state='on'/>
          <vendor_id state='on' value='compute01'/>
        </hyperv>
        <kvm>
          <hidden state='on'/>
        </kvm>
        <vmport state='off'/>
        <ioapic driver='kvm'/>
      </features>

      <cpu mode='host-passthrough' check='none' migratable='off'>
        <topology sockets='${toString vm.cpuTopology.sockets}' dies='1' cores='${toString vm.cpuTopology.cores}' threads='${toString vm.cpuTopology.threads}'/>
        <cache mode='passthrough'/>
        <feature policy='require' name='topoext'/>
      </cpu>

      <clock offset='localtime'>
        <timer name='rtc' tickpolicy='catchup'/>
        <timer name='pit' tickpolicy='delay'/>
        <timer name='hpet' present='no'/>
        <timer name='hypervclock' present='yes'/>
      </clock>

      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>restart</on_crash>

      <pm>
        <suspend-to-mem enabled='no'/>
        <suspend-to-disk enabled='no'/>
      </pm>

      <devices>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
          <source file='${vm.diskPath}'/>
          <target dev='vda' bus='virtio'/>
          <boot order='2'/>
        </disk>

        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <target dev='sda' bus='sata'/>
          <readonly/>
          <boot order='1'/>
        </disk>

        <disk type='file' device='cdrom'>
          <driver name='qemu' type='raw'/>
          <source file='${pkgs.virtio-win}/iso/virtio-win.iso'/>
          <target dev='sdb' bus='sata'/>
          <readonly/>
        </disk>

        <controller type='pci' model='pcie-root'/>
        <controller type='pci' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='1' port='0x10'/>
        </controller>
        <controller type='usb' model='qemu-xhci' ports='15'/>
        <controller type='sata' index='0'/>
        <controller type='virtio-serial' index='0'/>

        <interface type='network'>
          <source network='default'/>
          <model type='virtio'/>
        </interface>

        <input type='tablet' bus='usb'/>
        <input type='mouse' bus='ps2'/>
        <input type='keyboard' bus='ps2'/>

        <graphics type='spice' autoport='yes' listen='127.0.0.1'>
          <listen type='address' address='127.0.0.1'/>
          <image compression='off'/>
        </graphics>
        <channel type='spicevmc'>
          <target type='virtio' name='com.redhat.spice.0'/>
        </channel>
        <video>
          <model type='virtio' heads='1' primary='yes'/>
        </video>

        <hostdev mode='subsystem' type='pci' managed='yes'>
          <driver name='vfio'/>
          <source>
            <address domain='${vm.gpu.video.domain}' bus='${vm.gpu.video.bus}' slot='${vm.gpu.video.slot}' function='${vm.gpu.video.function}'/>
          </source>
          <rom bar='on'/>
        </hostdev>

        <hostdev mode='subsystem' type='pci' managed='yes'>
          <driver name='vfio'/>
          <source>
            <address domain='${vm.gpu.audio.domain}' bus='${vm.gpu.audio.bus}' slot='${vm.gpu.audio.slot}' function='${vm.gpu.audio.function}'/>
          </source>
        </hostdev>

        <tpm model='tpm-crb'>
          <backend type='emulator' version='2.0'/>
        </tpm>

        <memballoon model='none'/>
      </devices>
    </domain>
  '';

  qemuHook = pkgs.writeShellApplication {
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
  };

  defineVm = pkgs.writeShellApplication {
    name = "define-${vm.name}";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      libvirt
      qemu_kvm
    ];
    text = ''
      set -euo pipefail

      mkdir -p "$(dirname "${vm.diskPath}")"
      if [ ! -e "${vm.diskPath}" ]; then
        qemu-img create -f qcow2 "${vm.diskPath}" "${vm.diskSize}"
      fi

      if ! virsh net-info default >/dev/null 2>&1; then
        virsh net-define "${defaultNetworkXml}"
      fi
      virsh net-autostart default >/dev/null || true
      virsh net-start default >/dev/null || true

      if virsh domstate "${vm.name}" >/dev/null 2>&1 && virsh domstate "${vm.name}" | grep -qi running; then
        echo "${vm.name} is running; leaving existing libvirt definition unchanged"
      else
        virsh define "${domainXml}"
      fi
    '';
  };
in
{
  boot.kernelParams = [
    "amd_iommu=on"
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

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;

  users.users.jurre.extraGroups = [
    "kvm"
    "libvirtd"
    "render"
    "video"
  ];

  environment.systemPackages = with pkgs; [
    libvirt
    qemu_kvm
    swtpm
    virt-manager
    virtio-win
  ];

  environment.etc."libvirt/hooks/qemu" = {
    source = "${qemuHook}/bin/libvirt-qemu-hook";
    mode = "0755";
  };

  systemd.services."libvirt-define-${vm.name}" = {
    description = "Define ${vm.name} libvirt VM";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${defineVm}/bin/define-${vm.name}
    '';
  };
}
