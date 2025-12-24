{ config, pkgs, ... }:
{
  # Nix configuration
  nix = {
    # Enable automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    settings = {
      # Automatically optimize the Nix store
      auto-optimise-store = true;

      # Use all available CPU cores for builds (setting this to 0 means "use all cores")
      cores = 0;

      # Maximum number of parallel build jobs (balanced for stability and speed)
      max-jobs = 4;

      # Enable official NixOS binary cache (avoids building packages from source when possible)
      substituters = [
        "https://cache.nixos.org/"
      ];

      # Trusted public keys for binary caches
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
  };

  # Limit the size and retention of systemd logs
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

  # Enable periodic TRIM for SSDs
  services.fstrim.enable = true;

  # Enable compressed RAM swap (zram)
  zramSwap = {
    enable = true;
    memoryPercent = 30; # Use 30% of RAM for zram (optimal for systems with 16-32GB RAM)
    algorithm = "lz4"; # Compression algorithm (lz4 is fast and efficient)
  };
}