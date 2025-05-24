# This file configures the default network settings for NixOS
{ config, ... }:
{
  # Enable NetworkManager
  networking.networkmanager.enable = true;

  # Enable the firewall
  networking.firewall.enable = true;
}
