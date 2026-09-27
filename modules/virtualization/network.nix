{ ... }:

let
  network = import ../../configs/default-network.nix;
  slaveName = "${network.bridge}-${network.physicalInterface}";
in
{
  # LAN bridge for VMs. The host gets its LAN address on br0, and enp6s0 is
  # enslaved into that bridge. VMs attach directly to br0 and receive normal
  # LAN DHCP leases from the router.
  networking.networkmanager.ensureProfiles.profiles = {
    ${network.bridge} = {
      connection = {
        id = network.bridge;
        type = "bridge";
        interface-name = network.bridge;
        autoconnect = true;
        autoconnect-priority = 100;
      };

      bridge = {
        stp = false;
      };

      ipv4 = {
        method = "auto";
      };

      ipv6 = {
        method = "auto";
      };
    };

    ${slaveName} = {
      connection = {
        id = slaveName;
        type = "ethernet";
        interface-name = network.physicalInterface;
        master = network.bridge;
        slave-type = "bridge";
        autoconnect = true;
        autoconnect-priority = 100;
      };
    };
  };

  virtualisation.libvirtd.allowedBridges = [ network.bridge ];
}
