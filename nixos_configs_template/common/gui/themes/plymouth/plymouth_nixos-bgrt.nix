{ pkgs, ... }:
{
  # Plymouth boot splash configuration with NixOS BGRT theme
  boot = {
    # Configure Plymouth boot splash screen
    plymouth = {
      # Install the nixos-bgrt-plymouth package, which provides a NixOS-branded theme
      # that utilizes the BGRT (Boot Graphics Resource Table) for a seamless vendor logo experience
      themePackages = with pkgs; [ 
        nixos-bgrt-plymouth  # NixOS BGRT Plymouth theme package
      ];
      
      # Set the theme to nixos-bgrt which shows the NixOS logo during boot
      # with a clean, professional appearance that integrates with firmware boot splash
      theme = "nixos-bgrt";  # NixOS BGRT theme with the NixOS snowflake logo
    };
  };
}