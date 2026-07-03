{ config, pkgs, ... }:
{
  # AirPlay (RAOP) support for PipeWire
  # Allows streaming audio to AirPlay devices like Denon Home 150, HomePod, etc.
  services.pipewire.extraConfig.pipewire = {
    "99-raop-discover" = {
      "context.modules" = [
        { name = "libpipewire-module-raop-discover"; }
      ];
    };
  };

  # Enable RAOP (AirPlay) support in WirePlumber
  services.pipewire.wireplumber = {
    extraConfig = {
      "10-raop-policy" = {
        "monitor.raop" = {
          "enabled" = true;
        };
      };
    };
  };

  # mDNS/Zeroconf: necessary to discover AirPlay (RAOP) devices in LAN
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true; # Opens mDNS (5353/udp) automatically
  };

  # (optional) Open firewall for RAOP streaming (UDP 6001-6002) if not handled by your firewall
  services.pipewire.raopOpenFirewall = true;
}
