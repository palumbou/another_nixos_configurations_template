# This file configures the default network settings for NixOS
{ config, pkgs, ... }:
{
  # Enable NetworkManager
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  # Enable the firewall
  networking.firewall.enable = true;
}