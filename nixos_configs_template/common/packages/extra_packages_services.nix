{ pkgs, ... }:
{
  # Add extra system packages
  environment.systemPackages = with pkgs; [
    solaar  # Utility to manage Logitech devices
  ];
}
