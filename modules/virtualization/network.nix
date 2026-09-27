{ inputs, ... }:

let
  network = import ../../configs/default-network.nix;
  networkXml = inputs.NixVirt.lib.network.writeXML {
    inherit (network) name uuid;

    forward = {
      mode = "nat";
    };

    bridge = {
      name = network.bridge;
      stp = true;
      delay = 0;
    };

    ip = {
      inherit (network.subnet) address netmask;
      dhcp = {
        range = {
          start = network.subnet.dhcpStart;
          end = network.subnet.dhcpEnd;
        };
      };
    };
  };
in
{
  virtualisation.libvirt.connections."qemu:///system".networks = [
    {
      definition = networkXml;
      active = true;
    }
  ];
}
