{ pkgs, ... }:
{
  imports =
    [
      #../gui/themes/plymouth/plymouth_breeze-plymouth.nix
      #../gui/themes/plymouth/plymouth_catppucin.nix
      ../gui/themes/plymouth/plymouth_nixos-bgrt.nix
      #../gui/themes/plymouth/plymouth_plymouth-themes.nix
    ];

  # TPM2 support, required for automatic LUKS unlock via the TPM chip.
  # Enrollment and crypttab options: see hosts/disk_configurations/LUKS_KEYS.md
  # security.tpm2.enable = true;

  # Boot configuration with LUKS (Linux Unified Key Setup) encryption support
  boot = {
    # Control verbosity level of kernel messages during boot
    consoleLogLevel = 3;
    
    # Disable verbose output in initrd stage
    initrd.verbose = false;
    
    # Enable systemd in the initial ramdisk for faster boot
    initrd.systemd.enable = true;
    
    # Kernel boot parameters
    kernelParams = [
      # "quiet"  # Uncomment to suppress most kernel messages
      "splash"  # Show splash screen during boot
      "intremap=on"  # Enable interrupt remapping for better hardware compatibility
      "boot.shell_on_fail"  # Drop to shell if boot fails
      "udev.log_priority=3"  # Reduce udev logging verbosity
      "rd.systemd.show_status=auto"  # Show systemd status messages automatically
    ];

    # Plymouth boot splash configuration
    plymouth = {
      enable = true;  # Enable the Plymouth boot splash
      font = "${pkgs.hack-font}/share/fonts/truetype/Hack-Regular.ttf";  # Set Hack as the Plymouth font
      logo = "${pkgs.nixos-icons}/share/icons/hicolor/128x128/apps/nix-snowflake.png";  # Use NixOS snowflake as logo
    };
  };
}