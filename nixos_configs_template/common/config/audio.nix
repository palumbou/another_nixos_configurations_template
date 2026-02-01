{ config, pkgs, ... }:
{
  # Enable sound with PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;  # Enables both 32-bit and 64-bit ALSA support
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;

    # Enables wireplumber, a session manager for PipeWire,
    # used to handle audio routing and device management.
    wireplumber.enable = true;
  };

  # Audio utilities
  environment.systemPackages = with pkgs; [
    pulseaudio   # Provides pactl/pacmd commands (works with pipewire-pulse)
    pwvucontrol  # PipeWire Volume Control - Native GUI for PipeWire audio management
  ];
}
