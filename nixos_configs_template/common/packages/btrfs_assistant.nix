{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.btrfs-assistant ];
}
