{
  # RTX 4060 and its HDMI/DP audio function.
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
