{ config, pkgs, ... }:
{
  # Add workstation packages
  environment.systemPackages = with pkgs; [
    darktable      # Photo editing software
    distrobox      # Containerized development environments
    docker-compose # Docker Compose
    gimp           # Image editor
    vscode         # Visual Studio Code editor
  ];

  # Enable OBS Studio
  programs.obs-studio = {
    enable = true;
  };

  # Enable virtualization
  programs.virt-manager.enable = true;
  virtualisation = {
    libvirtd.enable = true;               # Enable libvirtd service
    spiceUSBRedirection.enable = true;    # Enable USB redirection for SPICE
  };

  # Enable Docker
  virtualisation.docker = {
    enable = true;            # Enable Docker
    enableOnBoot = true;      # Enable on boot
    autoPrune.enable = false; # Disable automatic pruning

    # Ensure we don't use rootless
    rootless.enable = false;
  };

  # Tell Distrobox to use Docker as backend
  environment.variables.DISTROBOX_BACKEND = "docker";

  # Enable Flatpak to supply the portal backend required by Distrobox for host-side URL opening
  services.flatpak.enable = true;
}