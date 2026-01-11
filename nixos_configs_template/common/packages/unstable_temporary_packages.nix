{ config, pkgs, ... }:
let
  # Import unstable channel automatically
  # No manual channel addition needed - this fetches unstable directly from nixpkgs
  unstable = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  }) { config = config.nixpkgs.config; };
in
{
  # Packages from unstable channel or for temporary testing
  # Use this file for:
  # - Packages not yet available in stable
  # - Packages requiring latest features
  # - Temporary packages for testing/evaluation
  environment.systemPackages = with pkgs; [
    # Unstable packages
    # unstable.package-name   # Example: Add unstable packages here
    
    # Temporary packages for testing
    # Add packages here that you want to test before adding to default_packages_services.nix
    
  ];
}
