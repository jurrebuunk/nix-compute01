{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

  virtualisation.libvirt = {
    enable = true;
    swtpm.enable = true;
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

  # Do not fail the entire NixOS switch if BIOS virtualization/SVM is disabled.
  # NixVirt will define the VMs once /dev/kvm exists.
  systemd.services.nixvirt.unitConfig.ConditionPathExists = "/dev/kvm";
}
