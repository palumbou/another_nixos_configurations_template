{ config, pkgs, ... }:
{
  # Add workstation packages
  environment.systemPackages = with pkgs; [
    darktable      # Photo editing software
    davinci-resolve # Professional video editing software
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
    libvirtd = {
      enable = true;               # Enable libvirtd service
      onBoot = "start";            # Start default network on boot
      onShutdown = "shutdown";     # Shutdown VMs on host shutdown
      
      qemu = {
        package = pkgs.qemu_kvm;   # Use KVM-enabled QEMU
        runAsRoot = false;         # Run QEMU as regular user (more secure)
        swtpm.enable = true;       # Enable TPM emulation for Windows 11 and secure boot
        ovmf = {
          enable = true;           # Enable UEFI support for VMs
          packages = [ pkgs.OVMFFull.fd ]; # Full OVMF package with Secure Boot support
        };
      };
    };
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