{ config, pkgs, ... }:
{
  # Steam via the NixOS module (instead of the bare package): it also enables
  # 32-bit graphics libraries and the steam-hardware udev rules, required by
  # Steam Input to access controllers (e.g. 8BitDo and Xbox gamepads).
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;      # Set to true to open ports for Steam Remote Play
    dedicatedServer.openFirewall = false; # Set to true to open ports for Source dedicated servers
  };

  # Add gamestation packages
  environment.systemPackages = with pkgs; [
    heroic            # Launcher for Epic Games Store, GOG and Amazon Prime games
  ];
}
