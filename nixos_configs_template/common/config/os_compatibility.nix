{ pkgs, ... }:
{
  # Enable nix-ld for running unpatched dynamic binaries on NixOS
  programs.nix-ld = {
    enable = true;
    
    # Additional libraries to make available to non-NixOS binaries
    libraries = with pkgs; [
      # C/C++ standard libraries
      stdenv.cc.cc.lib
      
      # Common system libraries
      zlib
      zstd
      openssl
      curl
      expat
      
      # Graphics and display
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXi
      xorg.libXext
      xorg.libXrender
      xorg.libxcb
      libglvnd
      
      # Audio
      alsa-lib
      pulseaudio
      
      # Other common dependencies
      fontconfig
      freetype
      glib
      gtk3
      pango
      cairo
      gdk-pixbuf
      atk
      
      # Database clients
      sqlite
      
      # Compression
      bzip2
      xz
    ];
  };

  # Enable udev rules for HID devices access (needed for WebHID API in Chrome)
  # Using TAG+="uaccess" allows dynamic permissions for active logged-in users
  # See: https://github.com/systemd/systemd/issues/4288
  services.udev.extraRules = ''
    # WebHID support for Chrome/Chromium - allows access to HID devices (keyboards, mice, etc.)
    # TAG+="uaccess" grants access to the currently active user session
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", TAG+="uaccess"
    
    # Additional USB device access for WebUSB API
    SUBSYSTEM=="usb", ENV{ID_USB_INTERFACES}=="*:03*", TAG+="uaccess"
  '';

  # Ensure hardware support for USB devices
  hardware.enableRedistributableFirmware = true;
}
