{
  inputs,
  pkgs,
  vm,
}:

let
  memory = {
    count = vm.memoryGiB;
    unit = "GiB";
  };

  domain = {
    type = "kvm";
    inherit (vm) name uuid;

    metadata = with inputs.NixVirt.lib.xml; [
      (elem "nixos:managed-by" [ (attr "xmlns:nixos" "https://nixos.org") ] "nix-compute01")
    ];

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

    features = {
      acpi = { };
      apic = { };
      kvm.hidden.state = true;
      vmport.state = false;
      ioapic.driver = "kvm";
    };

    cpu = {
      mode = "host-passthrough";
      check = "none";
      migratable = false;
      topology = vm.cpu.topology // {
        dies = 1;
      };
      cache.mode = "passthrough";
      feature = {
        policy = "require";
        name = "topoext";
      };
    };

    clock = {
      offset = "utc";
      timer = [
        {
          name = "rtc";
          tickpolicy = "catchup";
        }
        {
          name = "pit";
          tickpolicy = "delay";
        }
        {
          name = "hpet";
          present = false;
        }
      ];
    };

    on_poweroff = "destroy";
    on_reboot = "restart";
    on_crash = "restart";

    pm = {
      suspend-to-mem.enabled = false;
      suspend-to-disk.enabled = false;
    };

    devices = import ./domain/devices { inherit pkgs vm; };
  };
in
inputs.NixVirt.lib.domain.writeXML domain
