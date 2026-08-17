{ config, lib, pkgs, ... }:
{
  imports =
    [
      #../gui/themes/plymouth/plymouth_breeze-plymouth.nix
      #../gui/themes/plymouth/plymouth_catppucin.nix
      ../gui/themes/plymouth/plymouth_nixos-bgrt.nix
      #../gui/themes/plymouth/plymouth_plymouth-themes.nix
    ];

  # TPM2 userspace stack (tss libraries, udev rules), enabled automatically as
  # soon as any LUKS device is configured to unlock via TPM2 - i.e. when the
  # host's Disko file sets crypttabExtraOpts = [ "tpm2-device=auto" ]. The Disko
  # file stays the single source of truth: no per-host option is needed, and a
  # host can still override this (it is only a mkDefault).
  # Enrollment and crypttab options: see hosts/disk_configurations/LUKS_KEYS.md
  security.tpm2.enable = lib.mkDefault (
    lib.any
      (dev: lib.any (opt: lib.hasPrefix "tpm2-" opt) dev.crypttabExtraOpts)
      (lib.attrValues config.boot.initrd.luks.devices)
  );

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