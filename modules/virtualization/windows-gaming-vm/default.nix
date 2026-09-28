{ inputs, pkgs, ... }:

let
  vm = import ../../../configs/windows-gaming-vm.nix;
  domainXml = import ./domain.nix { inherit inputs pkgs vm; };
  gpuHandoffHook = import ../gpu-handoff-hook.nix { inherit pkgs vm; };
in
{
  virtualisation.libvirt.connections."qemu:///system".domains = [
    {
      definition = domainXml;
      active = null;
      restart = null;
    }
  ];

  virtualisation.libvirtd.hooks.qemu."${vm.name}-gpu-handoff" =
    "${gpuHandoffHook}/bin/libvirt-qemu-gpu-handoff-hook";

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
