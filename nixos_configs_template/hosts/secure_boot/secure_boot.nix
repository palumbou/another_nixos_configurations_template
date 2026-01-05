{ pkgs, lib, ... }:
let
  # Import Lanzaboote source definition
  sources = import ./lon.nix;
  lanzaboote = import sources.lanzaboote {
    inherit pkgs;
  };
in
{
  imports = [ lanzaboote.nixosModules.lanzaboote ];

  # Install sbctl for Secure Boot key management and verification
  environment.systemPackages = [
    pkgs.sbctl
  ];

  # Lanzaboote replaces the systemd-boot module.
  # Force disable the standard NixOS systemd-boot module.
  # The actual systemd-boot bootloader is still used, but managed by Lanzaboote.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  # Enable Lanzaboote for automatic Secure Boot signing
  boot.lanzaboote = {
    enable = true;
    # Path to the Secure Boot keys created by sbctl
    pkiBundle = "/var/lib/sbctl";
  };
}