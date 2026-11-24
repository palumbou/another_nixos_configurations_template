# Hosts

> **Available languages**: [English (current)](README.md) | [Italiano](README.it.md)

Host examples are separated by purpose:

```text
hosts/
├── client/ABC/
│   ├── configuration.nix.template
│   ├── hardware-configuration.nix.template
│   ├── external-hardware-configuration.nix.template
│   ├── nm_configurations.nix.template
│   └── syncthing.nix.template
├── server/ABC/
│   ├── configuration.nix.template
│   ├── hardware-configuration.nix.template
│   ├── external-hardware-configuration.nix.template
│   ├── nm_configurations.nix.template
│   └── syncthing.nix.template
├── disk_configurations/
│   ├── btrfs/
│   └── ext4/
└── secure_boot/
```

Copy the relevant `ABC` example within its category and rename it for the host. Prepare selected `.nix.template` files as `.nix` files with the public parameter values described in [`env.conf`](../../env.conf) and the [HOWTO](../../HOWTO.md).

## Imports and public values

The client imports the client role, client administrator customizations, client network/package baseline, the encrypted-boot/Plymouth helper, SOPS and local hardware/network/Syncthing files. The server imports the server role, minimal administrator, separate worker account, SOPS and local files. Keep those required imports in place.

`${HOST_IMPORTS}` holds optional imports only: local desktop, Xfce RDP, package groups, Docker/libvirt, Btrfs maintenance and other selected capabilities. `${HOST_EXTRA_CONFIG}` holds boot settings only. Select these explicitly; editing `env.conf` alone does not change any Nix file.

Paths from either host category are:

| Target | Relative path |
| --- | --- |
| Common modules | `../../../common/` |
| Roles | `../../../roles/` |
| Accounts | `../../../users/ADMIN/` and `../../../users/WORKER/` |
| Encrypted data | `../../../secrets/` |
| Shared Disko recipes | `../../disk_configurations/` |
| Secure Boot | `../../secure_boot/secure_boot.nix` |
| Host-local modules | `./hardware-configuration.nix`, `./nm_configurations.nix`, `./syncthing.nix` |

Render host name and installation `system.stateVersion`, account IDs, limits and feature switches with the correct Nix types. Keep `NIXOS_VERSION` at the release of the first installation. Zram defaults are client `30`/`lz4` or server `50`/`zstd` with priority `100`; resolve empty public values before rendering. `MAX_JOBS` and `BUILD_CORES` control build concurrency.

## Hardware, disks and boot

Obtain `hardware-configuration.nix` from `nixos-generate-config` on the target, the original installer output or an appropriate [nixos-hardware](https://github.com/NixOS/nixos-hardware) module. The public template's `CPU_VENDOR` and `PLATFORM` fields are generic inputs; they do not detect storage, modules or firmware.

On an installed machine, preserve working filesystem and bootloader declarations. For a new installation, select a prepared [Disko layout](disk_configurations/README.md), import its pinned Disko module and recipe, and choose the matching bootloader. An empty `DISK_LAYOUT` resolves to `single-disk-ext4` for clients and `btrfs-worker-luks` for servers. These defaults use UEFI; GRUB requires an explicitly selected BIOS recipe. Explicit `DISK_LAYOUT=none` requires a real `hardware-configuration.nix` with the destination filesystems; the generic template is insufficient. [Lanzaboote Secure Boot](secure_boot/README.md) is optional.

The server Btrfs/LUKS layout has a 1 GiB EFI partition, `SWAP_SIZE` random-key encrypted swap (default `16G`), and passphrase-protected LUKS2 with root, home, Nix-store and `WORK_ROOT` subvolumes. The server disables hibernation and resume. Formatting is an explicit installation step, never a consequence of choosing a module during an ordinary rebuild.

Use the optional `external-hardware-configuration.nix` for printers, scanners and other target peripherals. Review its sample declarations before importing it.

## Network, SSH and RDP

`nm_configurations.nix` owns WiFi and service access ranges. Render allowed IPv4/IPv6 lists from the public SSH and RDP CIDRs. Rules use the actual configured service ports; empty server lists open no SSH/RDP ports. The client keeps its baseline SSH policy unless a subnet restriction is configured. See the [network guide](../common/network/README.md).

For WiFi, render `ENABLE_WIFI` and `WIFI_SSID_NIX` and prepare encrypted `wifi_env` containing `WIFI_PSK` in the host secret file. The host SOPS default file is `../../../secrets/<hostname>.yaml`; shared administrator key data comes from `../../../secrets/common.yaml`. Follow the [SOPS guide](../common/config/SECRETS.md).

Local desktop choice and Xfce RDP are independent. The optional [RDP module](../common/gui/README.md) disallows root login and requires a non-empty PAM password. Configure the password and allowed networks before relying on RDP; SSH public keys do not authenticate an RDP session.

## Worker account, work directory and power

The essential administrator belongs to `wheel`. The separate worker identity has its own UID/private GID, no `wheel` or Docker/libvirt privileges, and a private home. Administrator and worker share `WORK_GROUP` for explicit work-data access. `WORK_ROOT` is root-owned with mode `2750`; its `data` directory and selected work directories use worker ownership, group inheritance and default ACLs. Existing trees are not recursively changed. See the [account guide](../users/README.md).

The server continues work with the lid closed, disables suspend/hibernation and has no idle sleep action. Optional UPower battery handling uses PowerOff at its configured action threshold; `ENABLE_BATTERY=false` keeps the daemon disabled even if Xfce requests it. The client battery module uses Hibernate at its 7% action threshold only when `boot.resumeDevice` is non-empty; otherwise it uses PowerOff. Charge limits are host-selected: `CHARGE_LIMIT_MODE` accepts `none` (default, no charge limits set) or `thresholds`, which uses `CHARGE_START_THRESHOLD` and `CHARGE_STOP_THRESHOLD` (public defaults 75/80). Choose values supported by the actual TLP hardware plugin; the shared module imposes no charge threshold.

### Manual example: Lenovo non-ThinkPad

For a supported model, [TLP's Lenovo non-ThinkPad documentation](https://linrunner.de/tlp/settings/bc-vendors.html#lenovo-non-thinkpad-series) describes conservation mode using 0/1 values. The firmware fixes the charge limit according to the model; this is not a guarantee of 80%.

Keep `CHARGE_LIMIT_MODE=none` in `env.conf` so the generic threshold block stays inactive. Add and uncomment this example manually only in the relevant host's `configuration.nix`:

```nix
# Optional host-only settings for a supported Lenovo non-ThinkPad model.
# services.tlp.settings = {
#   START_CHARGE_THRESH_BAT0 = 0;
#   STOP_CHARGE_THRESH_BAT0 = 1;
# };
```

On a server, set `services.tlp.enable = true;` if needed. Set `services.tlp.settings.TLP_DISABLE_DEFAULTS = 1;` only if TLP should apply charge control without its other defaults.

## Btrfs maintenance

The shared snapshot core configures `/` and `/home` independently when each is Btrfs. Clients explicitly grant the selected administrator access to home snapshots. A server with a Btrfs `WORK_ROOT` adds a work snapshot policy with no non-root users/groups or synchronized ACL access.

Scrub and snapshots are independent optional modules. The separate optional Btrfs Assistant module installs only the GUI package; the selected desktop supplies Polkit and its authentication agent. The snapshot core works without the GUI or a desktop. A separate Nix-store subvolume is excluded from parent root/home snapshots, as are EFI and swap. A single-root layout without a separate `/nix` subvolume can include the Nix store in root snapshots. See the [configuration guide](../common/config/README.md).

## Host-specific Syncthing

Keep Syncthing in the host's `syncthing.nix`. Set `ENABLE_SYNCTHING` explicitly. An empty `SYNCTHING_DEVICE_ID` declares neither peer nor folder. A configured peer needs its actual device ID, a fixed reachable TCP endpoint, matching `SYNCTHING_FOLDER_ID` and absolute `SYNCTHING_FOLDER_PATH`. The server’s synchronized data folder must be `WORK_ROOT/data`; a client may choose another absolute data path. Discovery, relays and NAT traversal are disabled, so select an address reachable by your network policy.

Clients run the service under the administrator identity; servers use a dedicated `syncthing` account, with service state outside `WORK_ROOT` and work-group access only when the system service is enabled. Synchronization uses `sendreceive`, preserves Unix permissions, excludes common dependency/cache directories and propagates changes and deletions in both directions.

The listener is `tcp4://:22222`; no default ports are opened. Configure incoming access manually in the host network policy only where needed. The HTTPS GUI binds `127.0.0.1:8843`. Reach it through a tunnel, adapting account, host and SSH port:

```bash
ssh -p 22 -L 8843:127.0.0.1:8843 admin@example-host
```

Then open `https://127.0.0.1:8843` locally. See the account and SOPS guides before activation.
