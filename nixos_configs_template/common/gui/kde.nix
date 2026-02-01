{ config, ... }:
{
  imports =
    [
      ../config/audio.nix
      ../../common/packages/kde_packages.nix
    ];

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  #services.xserver.libinput.enable = true;

  # Enable Bluetooth support for KDE Plasma.
  #services.bluedevil.enable = true;
}
