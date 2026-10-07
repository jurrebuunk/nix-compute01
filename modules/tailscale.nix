{ pkgs, ... }:

{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--accept-routes"
      "--exit-node-allow-lan-access"
    ];
  };

  environment.systemPackages = with pkgs; [
    tailscale
  ];

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
