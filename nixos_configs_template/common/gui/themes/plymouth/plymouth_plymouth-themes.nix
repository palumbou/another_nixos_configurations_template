{ pkgs, ... }:
{
  # Boot configuration with LUKS (Linux Unified Key Setup) encryption support
  boot = {
    # Plymouth boot splash configuration
    plymouth = {
      # Install the adi1090x-plymouth-themes package which contains multiple beautiful Plymouth themes
      themePackages = with pkgs; [ 
        adi1090x-plymouth-themes  # Collection of 30+ Plymouth themes by adi1090x
      ];
      
      # Select which theme to use from the installed adi1090x themes
      # Available themes include: "colorful_sliced", "cuts", "dns", "hexa_retro", "pixels", "rings_2", "sphere", "square"
      theme = "colorful_sliced";  # Set the default Plymouth theme to display during boot
    };
  };
}