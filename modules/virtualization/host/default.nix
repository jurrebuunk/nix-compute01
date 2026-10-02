{ ... }:

{
  imports = [
    ./vfio.nix
    ./libvirt.nix
    ./network.nix
    ./storage.nix
  ];
}
