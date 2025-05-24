{ pkgs, ... }:
{
  # Plymouth boot splash configuration with KDE Breeze theme
  boot = {
    plymouth = {
      # Install the KDE Breeze Plymouth theme package
      themePackages = with pkgs; [ 
        kdePackages.breeze-plymouth  # KDE Breeze Plymouth theme package
      ];
      
      # Set the KDE Breeze theme for Plymouth
      theme = "plymouth-kcm";  # KDE Breeze theme with clean, modern appearance
    };
  };
}