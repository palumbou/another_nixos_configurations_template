{ pkgs, ... }:
{
  # Add Hyprland Catppuccin theme packages
  environment.systemPackages = with pkgs; [
    # Cursors
    catppuccin-cursors.mochaDark # Catppuccin Mocha Cursor theme for Hyprland
    
    # GTK Theme - Mocha with all accents
    (catppuccin-gtk.override {
      accents = [ "lavender" "blue" "pink" "mauve" ]; # Available accent colors
      size = "standard"; # compact or standard
      variant = "mocha"; # latte, frappe, macchiato, or mocha
    })
    
    # Qt Theme (Kvantum)
    catppuccin-kvantum # Kvantum theme with Catppuccin themes
    libsForQt5.qtstyleplugin-kvantum # Kvantum style plugin for Qt5
    kdePackages.qtstyleplugin-kvantum # Kvantum style plugin for Qt6
    
    # Icons - Papirus theme (used by GTK apps like VS Code)
    papirus-icon-theme # Papirus icon theme
  ];
  
  # Enable dconf for GTK settings
  programs.dconf.enable = true;
  
  # Qt configuration
  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "kvantum";
  };
}