{ }:

{
  features = {
    acpi = { };
    apic = { };
    kvm.hidden.state = true;
    vmport.state = false;
    ioapic.driver = "kvm";
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
}
