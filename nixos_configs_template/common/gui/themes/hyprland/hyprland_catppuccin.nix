{ pkgs, ... }:
{
  # Add Hyprland Catppuccin theme packages
  environment.systemPackages = with pkgs; [
    # Cursors
    catppuccin-cursors.mochaDark # Catppuccin Mocha Cursor theme for Hyprland
    
    # GTK Theme - Mocha with all accents
    (catppuccin-gtk.override {
      accents = [ "lavender" ]; # Available accent colors
      size = "standard"; # compact or standard
      variant = "mocha"; # latte, frappe, macchiato, or mocha
    })

    # GTK Theme Manager
    nwg-look # GUI tool to manage GTK themes
    glib # Provides gsettings command for GTK configuration

    # Qt Theme - qt6ct for Qt6 configuration
    qt6Packages.qt6ct # Qt6 Configuration Tool
    libsForQt5.qt5ct # Qt5 Configuration Tool (for Qt5 apps)

    # Qt Catppuccin Theme
    catppuccin-qt5ct # Catppuccin theme for qt5ct and qt6ct

    # Icons - Papirus theme (used by GTK apps like VS Code)
    papirus-icon-theme # Papirus icon theme
  ];
  
  # Enable dconf for GTK settings
  programs.dconf.enable = true;
  
  # Qt configuration
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };
}