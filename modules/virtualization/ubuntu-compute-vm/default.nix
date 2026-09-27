{ inputs, pkgs, ... }:

let
  vm = import ../../../configs/ubuntu-compute-vm.nix;
  domainXml = import ./domain.nix { inherit inputs pkgs vm; };
in
{
  virtualisation.libvirt.connections."qemu:///system".domains = [
    {
      definition = domainXml;
      active = null;
      restart = null;
    }
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/images 0755 root root -"
    "d /var/lib/libvirt/qemu/nvram 0755 root root -"
  ];

  systemd.services."libvirt-create-${vm.name}-disk" = {
    description = "Create sparse qcow2 disk for ${vm.name}";
    before = [ "nixvirt.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.qemu_kvm ];
    script = ''
      mkdir -p "$(dirname "${vm.storage.diskPath}")"
      if [ ! -e "${vm.storage.diskPath}" ]; then
        qemu-img create -f qcow2 "${vm.storage.diskPath}" "${vm.storage.diskSize}"
      fi
    '';
  };
}
