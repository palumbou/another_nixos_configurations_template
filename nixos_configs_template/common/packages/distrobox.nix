{ pkgs, ... }:
{
  imports = [
    ../services/docker.nix
  ];

  environment.systemPackages = [ pkgs.distrobox ];

  # Use the local Docker runtime enabled by this module.
  environment.variables.DBX_CONTAINER_MANAGER = "docker";

  # Preserve the existing Flatpak integration for opening URLs on the host.
  services.flatpak.enable = true;
}
