# Common modules

> **Available languages**: [English (current)](README.md) | [Italiano](README.it.md)

Reusable NixOS modules are grouped by purpose. [Roles](../roles/README.md) select shared foundations; each host adds optional modules through its import list.

| Directory | Contents |
| --- | --- |
| [`config/`](config/README.md) | System settings, audio, compatibility, optimizations, energy profiles, encrypted boot, Btrfs maintenance, SOPS and sudo. |
| [`gui/`](gui/README.md) | KDE, GNOME, Hyprland, optional Xfce RDP and [themes](gui/themes/README.md). |
| [`network/`](network/README.md) | Client and server NetworkManager settings, Bluetooth and firewall foundations. |
| [`packages/`](packages/README.md) | Independent photo, video, development, recording, Compose, Distrobox and virtualization tools; optional Btrfs Assistant, gaming and hardware packages. |
| [`services/`](services/README.md) | Local Docker and libvirt daemons and server OpenSSH. |

## Composition

A host in `hosts/client/<name>/` or `hosts/server/<name>/` imports modules with `../../../common/<category>/<file>.nix`. Prepare selected `.nix.template` files as `.nix` files and replace documented placeholders using the public values described in [`env.conf`](../../env.conf). See the [HOWTO](../../HOWTO.md) for manual preparation.

Local desktops are optional and independent of application groups and daemons. Distrobox imports its Docker runtime; Compose tools can be selected separately. Virt Manager can manage remote hosts without a local libvirt daemon. The former workstation bundle is represented by seven focused package modules plus Docker and libvirt.

## Host and user boundaries

WiFi profiles, allowed network ranges, Syncthing devices/folders and machine-specific hardware belong in `hosts/client/<name>/` or `hosts/server/<name>/`. Accounts belong in [`users/`](../users/README.md). Keep passwords, hashes, private keys and WiFi PSKs in encrypted secret files; see [SECRETS.md](config/SECRETS.md).

Btrfs snapshots are configured by the filesystem-aware `config/btrfs_snapshots.nix` core. It selects root and home only when each mount is Btrfs and creates the snapshot containers needed by Snapper. Client home ACLs and worker work-directory policy belong to the host; the core has no desktop or user dependency. The optional `packages/btrfs_assistant.nix` module only installs the GUI package; the selected desktop supplies Polkit and its authentication agent. Scrub is a separate Btrfs-only module.

`battery_management.nix` imports `energy_profiles.nix` and provides automatic Performance/Balanced selection plus temporary manual Saver, with dedicated Polkit authorization for active local administrators. Preserve host-specific driver and firmware overrides; see the [energy profile guide](config/README.md#energy-profiles).
