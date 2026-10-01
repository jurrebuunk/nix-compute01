{
  # RTX 4060 dedicated to VFIO/libvirt guests.
  # Keep these in sync with `lspci -nn` on compute01.
  vfioIds = [
    "10de:2882" # AD107 [GeForce RTX 4060]
    "10de:22be" # AD107 High Definition Audio Controller
  ];

  video = {
    pci = {
      domain = 0;
      bus = 7;
      slot = 0;
      function = 0;
    };
  };

  audio = {
    pci = {
      domain = 0;
      bus = 7;
      slot = 0;
      function = 1;
    };
  };
}
