{ pkgs, ... }:
{
  # Add Hyprland Catppuccin theme packages
  environment.systemPackages = with pkgs; [
    catppuccin-cursors.mochaDark # Catppuccin Mocha Cursor theme for Hyprland
    catppuccin-gtk # GTK theme for Hyprland, providing a Catppuccin Mocha theme
    catppuccin-papirus-folders # Catppuccin Mocha Papirus Folders theme for Hyprland
    papirus-folders # Icon theme for Hyprland, providing a set of icons for various applications
  ];
}