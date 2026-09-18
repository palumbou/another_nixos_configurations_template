# System Configuration

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

This folder contains core system configuration files that define fundamental system behaviors and user privileges.

## Available Files

- **`audio.nix`** - Centralized audio configuration with PipeWire, wireplumber session manager, rtkit for real-time priority, ALSA support (32-bit and 64-bit), PulseAudio compatibility layer, JACK support for professional audio applications, and audio utilities (pulseaudio CLI tools, pwvucontrol GUI). Automatically imported by desktop environment configurations (Hyprland, GNOME, KDE)
- **`audio_airplay.nix`** - Optional AirPlay/RAOP streaming support for sending audio to AirPlay-compatible devices (Apple HomePod, Denon Home speakers, etc.). Configures PipeWire's libpipewire-module-raop-discover and Avahi mDNS for device discovery. Import this only in host configurations that need AirPlay functionality
- **`audio_chromecast.nix`** - Optional Google Cast (Chromecast) streaming support for sending audio to Cast-compatible devices (Google Home/Nest speakers, Chromecast, etc.). PipeWire has no native Cast module, so this runs pulseaudio-dlna as a systemd user service that creates a virtual audio sink for each device discovered on the LAN (working with PipeWire through the pipewire-pulse compatibility layer). Also configures Avahi mDNS for device discovery and opens the firewall ports needed for streaming (TCP 8080, UDP 1900). Import this only in host configurations that need Google Cast functionality
- **`battery_management.nix`** - Configuration for TLP battery management and power saving features, including battery charge thresholds, CPU scaling governors, and energy performance policies for both AC and battery modes. Also enables UPower as a last-resort protection against battery drain: the system hibernates automatically at 7% while discharging instead of losing power abruptly
- **`boot_luks.nix`** - Configuration for LUKS encryption boot and Plymouth boot splash settings; it also enables the TPM2 userspace stack automatically when a LUKS device is set to unlock via TPM2 (see [LUKS_KEYS.md](../../hosts/disk_configurations/LUKS_KEYS.md))
- **`btrfs_scrub.nix`** - Periodic `btrfs scrub` through `services.btrfs.autoScrub`: it re-reads every allocated block and verifies its checksum, catching silent corruption (bit rot) before you run into it while opening a file. Corrupted metadata is repaired from the second copy whenever the profile is DUP or RAID (DUP is the mkfs default for metadata), while errors inside a single-profile data chunk can only be reported in the journal. Runs monthly at low CPU and I/O priority on every Btrfs mount point, deduplicated per device, so the subvolumes of one disk produce a single unit. Import this only in hosts whose filesystem is Btrfs: elsewhere the filesystem list resolves empty and the build fails on an assertion
- **`btrfs_snapshots.nix`** - Timeline snapshots with [snapper](https://github.com/openSUSE/snapper) on the `/` and `/home` subvolumes, taken hourly and pruned once a day. `/nix` stays out on purpose, since the Nix store is already rolled back through the NixOS generations, and neither `/boot` nor the swap subvolume can end up in a snapshot. Creates the `.snapshots` subvolumes that snapper requires via systemd-tmpfiles (NixOS never runs `snapper create-config`) and grants every normal user access to the `/home` snapshots through ACLs. It also installs [btrfs-assistant](https://gitlab.com/btrfs-assistant/btrfs-assistant), a Qt GUI to browse, compare and restore snapshots and to manage subvolumes, which escalates privileges through pkexec and therefore needs `security.polkit.enable` plus a running authentication agent. The `snapper` CLI and `btrfs-progs` need no declaration, they come from the snapper and btrfs modules. Import this only in hosts where `/` and `/home` are Btrfs subvolumes
- **`os_compatibility.nix`** - Enables compatibility with pre-compiled binaries on NixOS using nix-ld. Provides standard Linux library paths and common shared libraries (libc, libstdc++, X11, OpenGL, audio, etc.) allowing execution of non-NixOS binaries without patching. Includes support for FHS (Filesystem Hierarchy Standard) compatible applications. Also configures udev rules for HID device access (needed for WebHID API in Chrome/Chromium to access keyboards, mice, and other USB/HID devices) using the modern TAG+="uaccess" mechanism. Safe to keep enabled even when not actively using external binaries (automatically imported by `system.nix`)
- **`os_optimization.nix`** - System optimization settings including automatic garbage collection, Nix store optimization, systemd journal limits, SSD TRIM support, and zram configuration (automatically imported by `system.nix`)
- **`secrets.nix`** - Secrets management with [sops-nix](https://github.com/Mic92/sops-nix), pinned by commit: hosts decrypt the files in `secrets/` with the age key derived from their own SSH host key, and the editing tools (`sops`, `age`, `ssh-to-age`) are installed system-wide. Required by every host, since shared modules (user, WiFi) declare `sops.*` secrets. Full guide: [SECRETS.md](SECRETS.md)
- **`sudo.nix`** - Configuration for sudo privileges and user permissions (automatically imported by `system.nix`)
- **`system.nix`** - Core system settings including locale, time zone, basic system behaviors, and imports `sudo.nix`, `os_compatibility.nix` and `os_optimization.nix`

## Usage

Import these configuration files in your host-specific `configuration.nix` file:

```nix
imports = [
  # ...other imports...
  ../common/config/audio_airplay.nix  # Optional: only if you need AirPlay/RAOP streaming
  ../common/config/audio_chromecast.nix  # Optional: only if you need Google Cast streaming
  ../common/config/boot_luks.nix  # Optional: only if using LUKS encryption
  ../common/config/btrfs_scrub.nix  # Optional: only on Btrfs hosts
  ../common/config/btrfs_snapshots.nix  # Optional: only on Btrfs hosts with / and /home as subvolumes
  ../common/config/secrets.nix  # Required: sops-nix secrets management (see SECRETS.md)
  ../common/config/battery_management.nix  # Optional: only for laptops
  ../common/config/system.nix  # Required: imports sudo.nix and os_optimization.nix automatically
  # ...other configurations as needed...
];
```

> **Note**: You don't need to import `sudo.nix`, `os_optimization.nix`, or `audio.nix` separately. The first two are automatically imported by `system.nix`, while `audio.nix` is automatically imported by desktop environment configurations (Hyprland, GNOME, KDE).

## Customization

The configuration files in this directory define foundational system settings. You can:

- Modify `battery_management.nix` to adjust TLP battery thresholds, power management policies, and the UPower low-battery hibernation thresholds
- Modify `boot_luks.nix` to customize encrypted boot settings and Plymouth configuration
- Modify `btrfs_scrub.nix` to change the scrub interval, restrict it to a specific list of filesystems, or cap its throughput with `limit` on slow disks
- Modify `btrfs_snapshots.nix` to change which subvolumes are snapshotted, the snapshot interval, and how many hourly/daily/weekly/monthly snapshots are kept; remember to keep the `systemd.tmpfiles` rules in sync with the subvolumes you configure
- Manage the encrypted secrets themselves with `sops secrets/common.yaml` (see [SECRETS.md](SECRETS.md)); `secrets.nix` only needs editing to update the sops-nix pin
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
  # Note: system.stateVersion is set per host in hosts/<name>/configuration.nix,
  # since it records the NixOS release each host was first installed with.
}
```

### Considerations

- The configuration files in this directory form the foundation of your system setup
- Be careful when modifying core settings as they can affect system stability
- Always test changes in a controlled environment before deploying to production systems