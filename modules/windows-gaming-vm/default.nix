{ config, pkgs, ... }:

let
  vm = import ../../configs/gaming-vm.nix;

  defaultNetworkXml = import ./network-xml.nix { inherit pkgs; };
  domainXml = import ./domain-xml.nix { inherit pkgs vm; };
  qemuHook = import ./gpu-hook.nix { inherit pkgs vm; };
  defineVm = import ./define-vm.nix {
    inherit
      pkgs
      vm
      defaultNetworkXml
      domainXml
      ;
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
