{ inputs, pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  virtualisation.libvirt = {
    enable = true;
    swtpm.enable = true;

    connections."qemu:///system".networks = [
      {
        definition = inputs.NixVirt.lib.network.writeXML (
          inputs.NixVirt.lib.network.templates.bridge {
            name = "default";
            uuid = "70b08691-28dc-4b47-90a1-45bbeac9ab5a";
            bridge_name = "virbr0";
            subnet_byte = 122;
          }
        );
        active = true;
        restart = null;
      }
    ];
  };

  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  networking.firewall.trustedInterfaces = [ "virbr0" ];

  users.users.jurre.extraGroups = [
    "kvm"
    "libvirtd"
  ];

  environment.systemPackages = with pkgs; [
    libvirt
    pciutils
    qemu_kvm
    swtpm
    virt-manager
    virtio-win
  ];

  # Do not fail the entire NixOS switch if BIOS virtualization/SVM is disabled.
  systemd.services.nixvirt.unitConfig.ConditionPathExists = "/dev/kvm";
}
