{ vm }:

let
  windowsFeatures = {
    features = {
      acpi = { };
      apic = { };

      hyperv = {
        mode = "custom";
        relaxed.state = true;
        vapic.state = true;
        spinlocks = {
          state = true;
          retries = 8191;
        };
        vpindex.state = true;
        runtime.state = true;
        synic.state = true;
        stimer.state = true;
        frequencies.state = true;
        tlbflush.state = true;
        ipi.state = true;
        vendor_id = {
          state = true;
          value = "compute01";
        };
      };

      kvm.hidden.state = true;
      vmport.state = false;
      ioapic.driver = "kvm";
    };

    clock = {
      offset = "localtime";
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
        {
          name = "hypervclock";
          present = true;
        }
      ];
    };
  };

  linuxFeatures = {
    features = {
      acpi = { };
      apic = { };
      kvm.hidden.state = true;
      vmport.state = false;
      ioapic.driver = "kvm";
    };
  };
in
if (vm.type or "linux") == "windows" then windowsFeatures else linuxFeatures
