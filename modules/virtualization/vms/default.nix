{ inputs, lib, pkgs, ... }:

let
  vmFiles = import ../../../configs/vms;
  vms = map import vmFiles;

  mkDomain = vm: {
    definition = import ./lib/domain.nix { inherit inputs pkgs vm; };
    active = null;
    restart = null;
  };

  mkDiskService = vm: {
    name = "libvirt-create-${vm.name}-disk";
    value = {
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
  };
in
{
  virtualisation.libvirt.connections."qemu:///system".domains = map mkDomain vms;
  systemd.services = lib.listToAttrs (map mkDiskService vms);
}
