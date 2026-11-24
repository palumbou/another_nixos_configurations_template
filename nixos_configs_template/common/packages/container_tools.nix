{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.docker-compose ];
}
