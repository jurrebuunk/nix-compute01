{ pkgs, vm }:

let
  memory = {
    count = vm.memoryGiB;
    unit = "GiB";
  };
in
{
  inherit memory;
  currentMemory = memory;

  vcpu = {
    placement = "static";
    count = vm.cpu.vcpus;
  };

  os = {
    type = "hvm";
    arch = "x86_64";
    machine = "q35";
    loader = {
      readonly = true;
      type = "pflash";
      path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.fd";
    };
    nvram = {
      template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.fd";
      path = vm.storage.nvramPath;
    };
    boot = [
      { dev = "cdrom"; }
      { dev = "hd"; }
    ];
  };
}
