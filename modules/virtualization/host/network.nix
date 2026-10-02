{ ... }:

let
  network = import ../../../configs/hardware/network.nix;
  slaveName = "${network.bridge}-${network.physicalInterface}";
in
{
  networking.networkmanager.ensureProfiles.profiles = {
    ${network.bridge} = {
      connection = {
        id = network.bridge;
        type = "bridge";
        interface-name = network.bridge;
        autoconnect = true;
        autoconnect-priority = 200;
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
        autoconnect-priority = 200;
      };
    };
  };

  virtualisation.libvirtd.allowedBridges = [ network.bridge ];
}
