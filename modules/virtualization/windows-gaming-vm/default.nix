{
  config,
  inputs,
  pkgs,
  ...
}:

let
  vm = import ../../../configs/gaming-vm.nix;

  domainXml = import ./domain.nix { inherit inputs pkgs vm; };
  networkXml = import ./network.nix { inherit inputs vm; };
  qemuHook = import ./gpu-hook.nix { inherit pkgs vm; };
in
{
  virtualisation.libvirt.connections."qemu:///system" = {
    networks = [
      {
        definition = networkXml;
        active = true;
      }
    ];

    domains = [
      {
        definition = domainXml;
        active = null;
        restart = null;
      }
    ];
  };

  virtualisation.libvirtd.hooks.qemu."${vm.name}-gpu" = "${qemuHook}/bin/libvirt-qemu-hook";

  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/images 0755 root root -"
    "d /var/lib/libvirt/qemu/nvram 0755 root root -"
  ];

  # Do not fail the entire NixOS switch if BIOS virtualization/SVM is disabled.
  # NixVirt will define the KVM VM once /dev/kvm exists.
  systemd.services.nixvirt.unitConfig.ConditionPathExists = "/dev/kvm";

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
