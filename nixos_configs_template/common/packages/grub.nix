{ pkgs, ... }:
{
  imports = [
    ../gui/themes/grub/grub_catppuccin.nix
  ];

  # Configure GRUB bootloader
  boot.loader.grub = {
    memtest86.enable = false; # Disable memtest86 memory testing tool during boot
  };
}