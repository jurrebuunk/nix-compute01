{ ... }:

{
  imports = [
    ./vfio.nix
    ./libvirt.nix
    ./windows-gaming-vm
    ./ubuntu-gaming-vm
  ];
}
