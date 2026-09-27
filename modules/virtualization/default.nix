{ ... }:

{
  imports = [
    ./vfio.nix
    ./libvirt.nix
    ./network.nix
    ./storage.nix
    ./windows-gaming-vm
    ./ubuntu-compute-vm
  ];
}
