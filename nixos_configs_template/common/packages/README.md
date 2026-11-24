# Packages

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

These reusable modules group packages by purpose. Choose each optional group in the host configuration; graphical tools and local service daemons can be selected independently.

## Available modules

| File | Packages and behavior |
| --- | --- |
| `default_packages_services.nix.template` | Client baseline: command-line, networking, disk, development and multimedia utilities; firmware updates; unfree packages allowed; client OpenSSH policy described below. |
| `photo_editing.nix` | Darktable and GIMP. |
| `video_editing.nix` | DaVinci Resolve. |
| `development.nix` | Visual Studio Code. |
| `recording.nix` | Enables the NixOS OBS Studio module. |
| `container_tools.nix` | Docker Compose tools. The local Docker daemon is selected separately. |
| `distrobox.nix` | Distrobox, local Docker daemon and Flatpak integration; sets `DBX_CONTAINER_MANAGER = "docker"`. |
| `virtualization_tools.nix` | Virt Manager and SPICE USB redirection. Can manage remote libvirt hosts; does not enable a local libvirt daemon. |
| `btrfs_assistant.nix` | Installs the optional Btrfs Assistant GUI package, separately from the snapshot core. The selected desktop supplies Polkit; graphical prompts need its running authentication agent. |
| `extra_packages_services.nix` | Solaar for Logitech devices. |
| `external_monitor.nix` | Enables I2C and installs `ddcutil` for DDC/CI monitor controls and `v4l-utils` for video devices. The user module assigns the `i2c` group conditionally. |
| `gamestation_packages.nix` | Steam through its NixOS module, including 32-bit graphics support and controller udev rules. Heroic is a commented optional package. Remote Play and dedicated-server firewall openings are disabled. |
| `grub.nix` | Shared GRUB settings and theme; import when the selected boot configuration uses GRUB. |
| `kde_packages.nix` | Filelight, Kate, KCalc, Partition Manager, Print Manager and Konsave; already imported by `../gui/kde.nix`. |
| `unstable_temporary_packages.nix` | Empty package list for temporary additions, with an optional pinned nixos-unstable package set. Using that package set needs no manual channel configuration. |

The former workstation bundle is split across the seven focused package modules and the [Docker and libvirt service modules](../services/README.md). Import all nine to retain the complete workstation selection, or choose the required capabilities.

The client baseline `default_packages_services.nix` and the server role `roles/server.nix` both set `nixpkgs.config.allowUnfree = true;`. Optional applications, fonts and firmware use this profile-wide policy.

## Usage

Prepare `.nix.template` files as `.nix` files and replace their placeholders with host values. In `default_packages_services.nix.template`, replace `${SSH_PORT}` with a numeric port while preserving the client authentication policy.

From `hosts/client/<name>/configuration.nix`:

```nix
imports = [
  ../../../common/packages/default_packages_services.nix
  ../../../common/packages/photo_editing.nix
  ../../../common/packages/video_editing.nix
  ../../../common/packages/development.nix
  ../../../common/packages/recording.nix
  ../../../common/packages/container_tools.nix
  ../../../common/packages/distrobox.nix
  ../../../common/packages/virtualization_tools.nix
  ../../../common/services/docker.nix
  ../../../common/services/libvirt.nix
];
```

`distrobox.nix` already imports `docker.nix`; NixOS supports keeping both imports. To use only Compose, import `container_tools.nix`. For local Docker without Distrobox, import `../services/docker.nix`. A local virtual-machine host needs `../services/libvirt.nix`; graphical management tools remain optional.

Account identities belong in `users/ADMIN/admin.nix` and `users/WORKER/worker.nix`; client customizations and conditional hardware/daemon groups belong in `users/ADMIN/client.nix`. The service modules contain no machine-specific user names, keys or access rules.

## Client OpenSSH policy

The client baseline enables OpenSSH on `${SSH_PORT}`, allows password authentication for regular users, disables keyboard-interactive authentication, and disables direct root login. After verifying key access from every required machine, you can set `PasswordAuthentication = false` explicitly. Server profiles use the separate [server SSH module](../services/README.md).

## Customization

Add or remove packages within a coherent category, or create a module and import it only on relevant hosts. Keep hardware choices, user accounts and host-specific settings in their respective modules. Review dependencies and license requirements when changing a selection.
