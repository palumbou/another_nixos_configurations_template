{ pkgs, ... }:
{
  # Plymouth boot splash configuration with Catppuccin theme
  boot = {
    plymouth = {
      # Install the Catppuccin Plymouth theme package
      themePackages = with pkgs; [ 
        catppuccin-plymouth  # Catppuccin Plymouth themes package
      ];
      
      # Set the Catppuccin theme for Plymouth (available flavors: mocha, macchiato, frappe, latte)
      theme = "catppuccin-mocha";  # Using the darker Mocha variant of Catppuccin
    };
  };
}