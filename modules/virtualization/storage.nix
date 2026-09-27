{ ... }:

{
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/images 0755 root root -"
    "d /var/lib/libvirt/qemu/nvram 0755 root root -"
  ];
}
