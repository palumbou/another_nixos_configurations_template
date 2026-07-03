{ config, pkgs, ... }:
let
  # Import unstable channel automatically
  # No manual channel addition needed - this fetches unstable directly from nixpkgs.
  # Pinned to a specific snapshot for reproducibility and supply-chain safety.
  # To update:
  #   1. git ls-remote https://github.com/NixOS/nixpkgs nixos-unstable   -> new rev
  #   2. nix-prefetch-url --unpack https://github.com/NixOS/nixpkgs/archive/<rev>.tar.gz -> new sha256
  unstable = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/b5aa0fbd538984f6e3d201be0005b4463d8b09f8.tar.gz";
    sha256 = "1r0ixj83k41mmkl6xzdcgxgq2l0vkdw10ld234f8jlljyi9w5xd0";
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
