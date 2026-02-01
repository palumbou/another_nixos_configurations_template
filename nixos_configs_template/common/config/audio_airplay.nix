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

  # mDNS/Zeroconf: necessary to discover AirPlay (RAOP) devices in LAN
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true; # Opens mDNS (5353/udp) automatically
  };
}
