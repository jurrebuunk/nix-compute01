{ inputs, vm }:

inputs.NixVirt.lib.network.writeXML {
  inherit (vm.network) name uuid;

  forward = {
    mode = "nat";
  };

  bridge = {
    name = vm.network.bridge;
    stp = true;
    delay = 0;
  };

  ip = {
    inherit (vm.network.subnet) address netmask;
    dhcp = {
      range = {
        start = vm.network.subnet.dhcpStart;
        end = vm.network.subnet.dhcpEnd;
      };
    };
  };
}
