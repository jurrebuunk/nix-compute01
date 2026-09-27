{
  name = "default";
  bridge = "virbr0";
  uuid = "f5f1c6d0-07c6-4990-b88f-d344e31f979b";

  subnet = {
    address = "192.168.122.1";
    netmask = "255.255.255.0";
    dhcpStart = "192.168.122.2";
    dhcpEnd = "192.168.122.254";
  };
}
