# System Configuration

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

This folder contains core system configuration files that define fundamental system behaviors and user privileges.

## Available Files

- **`audio.nix`** - Centralized audio configuration with PipeWire, wireplumber session manager, rtkit for real-time priority, ALSA support (32-bit and 64-bit), PulseAudio compatibility layer, JACK support for professional audio applications, and audio utilities (pulseaudio CLI tools, pwvucontrol GUI). Automatically imported by desktop environment configurations (Hyprland, GNOME, KDE)
- **`audio_airplay.nix`** - Optional AirPlay/RAOP streaming support for sending audio to AirPlay-compatible devices (Apple HomePod, Denon Home speakers, etc.). Configures PipeWire's libpipewire-module-raop-discover and Avahi mDNS for device discovery. Import this only in host configurations that need AirPlay functionality
- **`audio_chromecast.nix`** - Optional Google Cast (Chromecast) streaming support for sending audio to Cast-compatible devices (Google Home/Nest speakers, Chromecast, etc.). PipeWire has no native Cast module, so this runs pulseaudio-dlna as a systemd user service that creates a virtual audio sink for each device discovered on the LAN (working with PipeWire through the pipewire-pulse compatibility layer). Also configures Avahi mDNS for device discovery and opens the firewall ports needed for streaming (TCP 8080, UDP 1900). Import this only in host configurations that need Google Cast functionality
- **[`battery_management.nix`](battery_management.nix)** - Three TLP energy profiles: Performance on AC, Balanced on battery and manually selected Saver. Imports `energy_profiles.nix` automatically and also supports desktops. Charge limits belong to the host and its TLP hardware plugin, with no shared charge thresholds imposed. UPower uses percentages: low at 15%, critical at 10% and action at 7% while discharging. The action is `Hibernate` only with a non-empty `boot.resumeDevice`; otherwise it is `PowerOff`. Verify that the host’s resume configuration actually works
- **`boot_luks.nix`** - Configuration for LUKS encryption boot and Plymouth boot splash settings; it also enables the TPM2 userspace stack automatically when a LUKS device is set to unlock via TPM2 (see [LUKS_KEYS.md](../../hosts/disk_configurations/LUKS_KEYS.md))
- **`btrfs_scrub.nix`** - Periodic `btrfs scrub` through `services.btrfs.autoScrub`: it re-reads every allocated block and verifies its checksum, catching silent corruption (bit rot) before you run into it while opening a file. Corrupted metadata is repaired from the second copy whenever the profile is DUP or RAID (DUP is the mkfs default for metadata), while errors inside a single-profile data chunk can only be reported in the journal. Runs monthly at low CPU and I/O priority on every Btrfs mount point, deduplicated per device, so the subvolumes of one disk produce a single unit. Import this only in hosts whose filesystem is Btrfs: elsewhere the filesystem list resolves empty and the build fails on an assertion
- **`btrfs_snapshots.nix`** - Hourly Snapper timeline snapshots and daily cleanup, selecting `/` and `/home` independently only when each mount is Btrfs. The module creates the required `.snapshots` containers automatically from Snapper configurations, with no desktop or user dependency. A separate Nix-store subvolume, EFI and swap remain outside root/home snapshots; a single-root layout can include `/nix` if it is not a separate subvolume. Client home ACLs are declared in the host for the selected administrator; servers add their work-subvolume policy in the host and manage snapshots through sudo. The [Btrfs Assistant GUI](../packages/README.md) is in the separate optional `common/packages/btrfs_assistant.nix` module, which only installs the GUI package. The selected desktop supplies Polkit; graphical prompts need its running authentication agent. The `snapper` and `btrfs-progs` CLIs come from their respective NixOS modules
- **[`disko.nix`](disko.nix)** - Shared Disko module pinned to the selected release. Import it with a prepared disk recipe when selecting a layout; declarations do not format storage during an ordinary rebuild
- **[`energy_profiles.nix`](energy_profiles.nix)** - The `energy-profile` CLI and dedicated Polkit action for temporary manual profile selection. Requires TLP 1.9 or newer; imported automatically by `battery_management.nix`. Active local users in `wheel` can select profiles, while `energy-profile status` returns JSON without elevated privileges
- **`os_compatibility.nix`** - Enables compatibility with pre-compiled binaries on NixOS using nix-ld. Provides standard Linux library paths and common shared libraries (libc, libstdc++, X11, OpenGL, audio, etc.) allowing execution of non-NixOS binaries without patching. Includes support for FHS (Filesystem Hierarchy Standard) compatible applications. Also configures udev rules for HID device access (needed for WebHID API in Chrome/Chromium to access keyboards, mice, and other USB/HID devices) using the modern TAG+="uaccess" mechanism. Safe to keep enabled even when not actively using external binaries (automatically imported by `roles/client.nix`)
- **`os_optimization.nix`** - System optimization settings including automatic garbage collection, Nix store optimization, systemd journal limits, SSD TRIM support, and zram configuration (automatically imported by `roles/client.nix`)
- **`secrets.nix`** - Secrets management with [sops-nix](https://github.com/Mic92/sops-nix), pinned by commit: hosts decrypt the files in `secrets/` with the age key derived from their own SSH host key, and the editing tools (`sops`, `age`, `ssh-to-age`) are installed system-wide. Required when the host imports modules that declare `sops.*` secrets, since shared modules (user, WiFi) declare `sops.*` secrets. Full guide: [SECRETS.md](SECRETS.md)
- **`sudo.nix`** - Configuration for sudo privileges and user permissions (automatically imported by `roles/client.nix`)
- **`system.nix`** configures locale, time zone and keyboard settings. It is imported by `roles/base.nix`; `system.stateVersion` remains in each host configuration.

## Usage

For a client at `hosts/client/<name>/configuration.nix`, import the client role and select optional modules. For a server, see the [roles guide](../../roles/README.md):

```nix
imports = [
  # Other imports...
  ../../../common/config/audio_airplay.nix  # Optional: AirPlay/RAOP streaming.
  ../../../common/config/audio_chromecast.nix  # Optional: Google Cast streaming.
  ../../../common/config/boot_luks.nix  # Optional: encrypted boot and Plymouth.
  ../../../common/config/btrfs_scrub.nix  # Optional: Btrfs hosts.
  ../../../common/config/btrfs_snapshots.nix  # Optional: Btrfs root/home subvolumes.
  ../../../common/config/secrets.nix  # For modules declaring SOPS secrets.
  ../../../common/config/battery_management.nix  # Optional: TLP power profiles.
  ../../../roles/client.nix  # Base settings, compatibility, optimizations and sudo.
  # Other optional modules...
];
```

> **Note**: `roles/client.nix` imports `os_compatibility.nix`, `os_optimization.nix` and `sudo.nix`; `roles/base.nix` imports the shared locale, time zone and keyboard settings. Desktop environment modules (Hyprland, GNOME, KDE) import `audio.nix`.

Optional selections `audio`, `audio_airplay` and `audio_chromecast` map to their respective modules. Without a local desktop, also import `audio.nix` when selecting a streaming module; GNOME/KDE/Hyprland already import it.

`battery_management.nix` also imports `energy_profiles.nix`, so hosts already importing battery management need no additional import.

### Snapshot profile selection

`btrfs_snapshots.nix` checks the `fileSystems."/".fsType` and `fileSystems."/home".fsType` declarations independently. It creates the `root` or `home` profile only when the corresponding mount is declared as `btrfs`. These conditions support both separate root/home layouts and layouts with only a root subvolume; they do not inspect the actual disk filesystems or subvolumes during evaluation.

When both `/` and `/home` are declared as Btrfs, both profiles remain active. If `/home` is an ordinary directory within the root subvolume, root snapshots already include it and no separate home profile is created. A separate home subvolume is not included in its parent's snapshots: declare it as a Btrfs mount or add its Snapper profile explicitly in the host to protect it.

## Energy Profiles

Automatic operation selects Performance on AC and Balanced on battery. A desktop without a system battery uses Performance automatically. Saver is selected manually.

| Setting | Performance (`AC`) | Balanced (`BAT`) | Saver (`SAV`) |
|---|---|---|---|
| CPU governor | `performance` | `powersave` | `powersave` |
| Energy preference | `performance` | `balance_performance` | `balance_power` |
| Turbo allowed | Yes | Yes | No |
| Firmware profile | `performance` | `balanced` | `balanced` |

These governor defaults target active `intel_pstate`/`amd-pstate` drivers. Override `services.tlp.settings` in the host configuration when its driver or firmware requires different values; `tlp-stat -p` reports the supported values. For example, a host using `acpi-cpufreq` may use `schedutil` instead of `powersave`.

After rebuilding NixOS, use:

```bash
energy-profile auto         # Restore automatic selection from the power source
energy-profile performance  # Force Performance, including on battery
energy-profile balanced     # Force Balanced, including on AC
energy-profile saver        # Select Saver manually
energy-profile status       # Read the current profile, mode and source as JSON
```

Manual choices survive charger changes and suspend, and end when you select Automatic or reboot. This uses only TLP's native temporary state; no additional state file is created. Changing profiles is authorized through a dedicated Polkit action for users in `wheel` with an active local session. The module requires TLP 1.9 or newer and checks the native switching settings needed for this behavior.

## Customization

The configuration files in this directory define foundational system settings. You can:

- Override `services.tlp.settings` per host to adjust the profiles declared by `battery_management.nix`; the common defaults remain reusable. Select charge-limit mode and hardware-supported thresholds in the host; the module provides percentage-based UPower action thresholds and chooses Hibernate only when a resume device is configured
- Modify `boot_luks.nix` to customize encrypted boot settings and Plymouth configuration
- Modify `btrfs_scrub.nix` to change the scrub interval, restrict it to a specific list of filesystems, or cap its throughput with `limit` on slow disks
- Modify `btrfs_snapshots.nix` to change which subvolumes are snapshotted, the snapshot interval, and how many hourly/daily/weekly/monthly snapshots are kept; snapshot containers follow the configured Btrfs subvolumes automatically
- Manage the encrypted secrets themselves with `sops secrets/common.yaml` (see [SECRETS.md](SECRETS.md)); `secrets.nix` only needs editing to update the sops-nix pin
- Modify `sudo.nix` to adjust user privilege levels and security policies (note: imported automatically by `roles/client.nix`)
- Modify `os_optimization.nix` to tune Nix garbage collection, store optimization, and system resource management (note: imported automatically by `roles/client.nix`)
- Update `system.nix` to change locale, time zone and keyboard settings
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
  # Note: system.stateVersion is set per host in hosts/client/<name>/configuration.nix,
  # since it records the NixOS release each host was first installed with.
}
```

### Considerations

- The configuration files in this directory form the foundation of your system setup
- Be careful when modifying core settings as they can affect system stability
- Always test changes in a controlled environment before deploying to production systems
