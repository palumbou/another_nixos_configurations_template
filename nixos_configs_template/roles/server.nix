{ pkgs, ... }:
{
  imports = [
    ./base.nix
    ../common/services/server_ssh.nix
    ../common/network/server_network.nix
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    bashInteractive
    python3
    git
    ripgrep
    rsync
    curl
    jq
    coreutils
    findutils
    gnutar
    gzip
    unzip
    acl
  ];
}
