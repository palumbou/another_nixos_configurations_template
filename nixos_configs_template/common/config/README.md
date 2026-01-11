# System Configuration

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

This folder contains core system configuration files that define fundamental system behaviors and user privileges.

## Available Files

- **`battery_management.nix`** - Configuration for TLP battery management and power saving features, including battery charge thresholds, CPU scaling governors, and energy performance policies for both AC and battery modes
- **`boot_luks.nix`** - Configuration for LUKS encryption boot and Plymouth boot splash settings
- **`os_compatibility.nix`** - Enables compatibility with pre-compiled binaries on NixOS using nix-ld. Provides standard Linux library paths and common shared libraries (libc, libstdc++, X11, OpenGL, audio, etc.) allowing execution of non-NixOS binaries without patching. Includes support for FHS (Filesystem Hierarchy Standard) compatible applications. Also configures udev rules for HID device access (needed for WebHID API in Chrome/Chromium to access keyboards, mice, and other USB/HID devices) using the modern TAG+="uaccess" mechanism. Safe to keep enabled even when not actively using external binaries (automatically imported by `system.nix`)
- **`os_optimization.nix`** - System optimization settings including automatic garbage collection, Nix store optimization, systemd journal limits, SSD TRIM support, and zram configuration (automatically imported by `system.nix`)
- **`sudo.nix`** - Configuration for sudo privileges and user permissions (automatically imported by `system.nix`)
- **`system.nix`** - Core system settings including locale, time zone, basic system behaviors, and imports `sudo.nix`, `os_compatibility.nix` and `os_optimization.nix`

## Usage

Import these configuration files in your host-specific `configuration.nix` file:

```nix
imports = [
  # ...other imports...
  ../common/config/boot_luks.nix  # Optional: only if using LUKS encryption
  ../common/config/battery_management.nix  # Optional: only for laptops
  ../common/config/system.nix  # Required: imports sudo.nix and os_optimization.nix automatically
  # ...other configurations as needed...
];
```

> **Note**: You don't need to import `sudo.nix` and `os_optimization.nix` separately, as they are automatically imported by `system.nix`.

## Customization

The configuration files in this directory define foundational system settings. You can:

- Modify `battery_management.nix` to adjust TLP battery thresholds and power management policies
- Modify `boot_luks.nix` to customize encrypted boot settings and Plymouth configuration
- Modify `sudo.nix` to adjust user privilege levels and security policies (note: imported automatically by `system.nix`)
- Modify `os_optimization.nix` to tune Nix garbage collection, store optimization, and system resource management (note: imported automatically by `system.nix`)
- Update `system.nix` to change locale settings, time zones, or core system behaviors
- Reference host-specific variables to customize settings per machine

### Example Modification

If you want to customize the system settings in `system.nix`:

```nix
# In system.nix
{ config, pkgs, ... }:

{
  # Set your time zone
  time.timeZone = "Europe/Rome";
  
  # Select internationalization properties
  i18n.defaultLocale = "it_IT.UTF-8";
  
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };
  
  # Add your custom system settings here
  system.stateVersion = "25.11"; # DO NOT CHANGE THIS
}
```

### Considerations

- The configuration files in this directory form the foundation of your system setup
- Be careful when modifying core settings as they can affect system stability
- Always test changes in a controlled environment before deploying to production systems