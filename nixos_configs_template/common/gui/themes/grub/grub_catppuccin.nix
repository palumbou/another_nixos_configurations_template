{ pkgs, ... }:
{
  # Configure Catppuccin Mocha theme for GRUB bootloader
  boot.loader.grub = {
    # Install and set Catppuccin theme for GRUB - modern, minimal, and aesthetically pleasing
    theme = pkgs.catppuccin-grub;
  };
}
