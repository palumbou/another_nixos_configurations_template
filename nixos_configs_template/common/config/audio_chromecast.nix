{ config, pkgs, ... }:
{
  # Google Cast (Chromecast) support
  # Allows streaming audio to Cast devices like Google Home speakers, Nest Audio, Chromecast, etc.
  #
  # Unlike AirPlay (RAOP), PipeWire has no native Google Cast module.
  # pulseaudio-dlna bridges the gap: it discovers Chromecast and DLNA devices
  # on the LAN and creates a virtual audio sink for each one, selectable from
  # the normal audio output list. It works with PipeWire through the
  # pipewire-pulse compatibility layer.

  environment.systemPackages = [ pkgs.pulseaudio-dlna ];

  # Run pulseaudio-dlna as a user service (it needs the user's audio session)
  systemd.user.services.pulseaudio-dlna = {
    description = "Virtual audio sinks for Chromecast and DLNA devices";
    after = [ "pipewire-pulse.service" ];
    wants = [ "pipewire-pulse.service" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      # --codec flac gives lossless quality; Google Home/Nest speakers support it.
      # Use "--codec mp3" instead if you have older/flaky Cast devices.
      ExecStart = "${pkgs.pulseaudio-dlna}/bin/pulseaudio-dlna --port 8080 --codec flac";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # mDNS/Zeroconf: necessary to discover Google Cast devices in LAN
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true; # Opens mDNS (5353/udp) automatically
  };

  # The Cast device fetches the audio stream over HTTP from this machine,
  # so the streaming port must be reachable from the LAN
  networking.firewall.allowedTCPPorts = [ 8080 ];
  # SSDP discovery, only needed for DLNA renderers (harmless for Cast-only use)
  networking.firewall.allowedUDPPorts = [ 1900 ];
}
