# This file configures the default network settings for NixOS
{ config, pkgs, ... }:
{
  # Enable NetworkManager with VPN plugins
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  # WireGuard: CLI tools for managing VPN tunnels (wg, wg-quick)
  # The kernel module is built-in since Linux 5.6+
  # NetworkManager has native WireGuard support — no extra plugin needed
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  # Firewall configuration
  networking.firewall = {
    enable = true;
    # Uncomment to allow incoming WireGuard traffic (e.g. when acting as a server/peer)
    # allowedUDPPorts = [ 51820 ];
  };
}