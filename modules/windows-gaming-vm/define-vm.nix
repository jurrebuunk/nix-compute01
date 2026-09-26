{
  pkgs,
  vm,
  defaultNetworkXml,
  domainXml,
}:

pkgs.writeShellApplication {
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
}
