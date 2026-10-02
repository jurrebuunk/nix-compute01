{
  # LAN bridge used by libvirt guests. The host gets DHCP on br0 and enp6s0 is
  # enslaved into it, so VMs attached to br0 get normal LAN DHCP leases.
  bridge = "br0";
  physicalInterface = "enp6s0";
}
