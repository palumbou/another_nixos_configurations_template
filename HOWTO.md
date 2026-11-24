# How To

> **Available languages**: [English (current)](HOWTO.md) | [Italiano](HOWTO.it.md)

Use the templates for a rebuild of an installed NixOS system or for a new installation with Disko. Complete the same host preparation first.

## Prepare the configuration manually

1. Read [`env.conf`](env.conf) and copy `nixos_configs_template/` to a directory you control, for example `/etc/nixos/nixos_configs/`. Keep its internal structure.
2. Choose `hosts/client/ABC/` for a client or `hosts/server/ABC/` for a server. Copy the example within its category and name the directory after your host.
3. Copy the selected `.nix.template` files to matching `.nix` files. Render shared templates too, including `common/config/system.nix.template`, the account modules and the role's SSH baseline.
4. Replace documented public placeholders with host values. `env.conf` is a reference for those values; editing it alone does not update any Nix file.
5. Obtain the target's `hardware-configuration.nix`, select boot and storage settings, and prepare the encrypted secrets following [SECRETS.md](nixos_configs_template/common/config/SECRETS.md).

The [host guide](nixos_configs_template/hosts/README.md), [roles guide](nixos_configs_template/roles/README.md) and [account guide](nixos_configs_template/users/README.md) explain composition. A host under `hosts/client/<name>/` or `hosts/server/<name>/` uses `../../../common/`, `../../../roles/` and `../../../users/`; shared disk and Secure Boot modules use `../../disk_configurations/` and `../../secure_boot/`.

### Public parameters and Nix syntax

`HOST_ROLE` is `client` or `server`. `DESKTOP` is `none`, `kde`, `gnome` or `hyprland`. Choose application and daemon modules independently; `FEATURES` lists optional module names separated by commas. The [package guide](nixos_configs_template/common/packages/README.md) and [service guide](nixos_configs_template/common/services/README.md) describe the 14 application/daemon groups. Four additional selections are `audio`, `audio_airplay`, `audio_chromecast` ([audio configuration](nixos_configs_template/common/config/README.md)) and `bluetooth`, which maps to `common/network/default_bluetooth.nix` ([networking](nixos_configs_template/common/network/README.md)). `ENABLE_RDP` controls optional remote Xfce independently of a local desktop.

Render placeholders according to the syntax where they appear:

| Placeholder kind | Rendered example |
| --- | --- |
| Numeric values, such as `${SSH_PORT}` | `22`, without quotes. |
| Booleans, such as `${ENABLE_WIFI}` | `true` or `false`, without quotes. |
| Text already inside a Nix string, such as `"${HOSTNAME}"` | Escaped string contents; keep the surrounding quotes. |
| Complete string token `${WIFI_SSID_NIX}` | `"Example WiFi"`, including quotes; use `""` when disabled. |
| CIDR tokens `${SSH_ALLOWED_IPV4_NIX}`, `${SSH_ALLOWED_IPV6_NIX}`, and their `RDP_` counterparts | Lists of quoted networks split by IP family, for example `[ "192.0.2.0/24" ]`, or `[]`. |
| `${HOST_IMPORTS}` | Optional import entries only, or an empty block. |
| `${HOST_EXTRA_CONFIG}` | Boot configuration declarations only, matching the selected disk and bootloader. |

Preserve native Nix interpolation such as `${pkgs.libvirt}` and `${config.sops.placeholder.admin_ssh_publicKey}`. Do not run a global shell-variable substitution across the tree. Escape Nix string contents correctly, including quotes, backslashes and literal interpolation markers.

`HOST_IMPORTS` can contain local desktop modules, RDP, selected package groups, daemons, storage maintenance and other optional modules. Required role, user, network, SOPS and host Syncthing imports are already in the host templates. For example, this optional block selects KDE, photo tools and a separate local Docker daemon:

```nix
    ../../../common/gui/kde.nix
    ../../../common/packages/photo_editing.nix
    ../../../common/services/docker.nix
```

For AirPlay or Chromecast without a local desktop, include `../../../common/config/audio.nix` in the optional imports alongside the selected streaming module. Local desktop modules already import the audio foundation. The `bluetooth` selection remains independent of the desktop.

For `BOOT_LOADER=systemd-boot`, a minimal `HOST_EXTRA_CONFIG` block is:

```nix
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
```

For GRUB or Lanzaboote, use settings matching the selected storage layout and the [Secure Boot guide](nixos_configs_template/hosts/secure_boot/README.md). Resolve an empty `DISK_LAYOUT` to `single-disk-ext4` for clients or `btrfs-worker-luks` for servers; both defaults use UEFI. For GRUB, explicitly choose a BIOS recipe. With a selected layout, import both the pinned Disko module and the prepared recipe. Explicit `DISK_LAYOUT=none` requires a real `hardware-configuration.nix` with the destination filesystem declarations; the generic hardware template does not supply them. `DISK_DEVICE` is the part after `/dev/` in recipes containing `"/dev/${DISK_DEVICE}"`; use a stable `disk/by-id/...` value where appropriate.

Resolve empty derived values before rendering: `MAX_JOBS`/`BUILD_CORES` use `4`/`0` for clients and `2`/`4` for servers; zram defaults are `30`/`lz4` for clients and `50`/`zstd` for servers; an empty Syncthing folder path resolves to `/home/<admin>/Sync/work-data` on a client or `<WORK_ROOT>/data` on a server. Keep UID/GID values explicit and distinct. Set `NIXOS_VERSION` to the original installation release, not the release being upgraded to. CPU/platform fields must match the actual hardware declaration.

### Optional services and secrets

Set WiFi SSIDs and allowed CIDRs only for the target host. If `RDP_ALLOWED_CIDRS` is empty, resolve it to the SSH CIDRs before splitting IP families. WiFi PSKs belong in encrypted `wifi_env` with the `WIFI_PSK` variable; public SSH-key data and credentials follow the [SOPS guide](nixos_configs_template/common/config/SECRETS.md). Never put passwords, password hashes, PSKs or private keys in `env.conf`.

A server opens no SSH or RDP port until its allowed CIDRs are set. The client retains its existing SSH policy unless a subnet restriction is configured. RDP also requires a non-root account with a usable PAM password; SSH keys alone do not provide an RDP password.

Syncthing is configured in each host's `syncthing.nix`. With an empty remote device ID, no remote device or folder is declared. When enabling synchronization, supply a real peer ID, shared folder ID, folder path and a fixed reachable TCP endpoint. Discovery, relays, NAT traversal and automatic firewall openings are disabled. See the [host guide](nixos_configs_template/hosts/README.md).

## Rebuild an installed system

Install NixOS from an [official ISO](https://nixos.org/download/), preserve its detected hardware and existing filesystem/boot declarations, and prepare the configuration above. For an installed host, do not re-run Disko formatting.

Review evaluation before activation, using the actual host path:

```bash
sudo nixos-rebuild dry-build -I nixos-config=/etc/nixos/nixos_configs/hosts/client/example/configuration.nix
sudo nixos-rebuild switch -I nixos-config=/etc/nixos/nixos_configs/hosts/client/example/configuration.nix
```

For a server, use `hosts/server/example/configuration.nix`. Add `--show-trace` when investigating an evaluation failure. Keep an existing login session until remote access has been verified.

## Direct installation

Follow the [Disko guide](nixos_configs_template/hosts/disk_configurations/README.md) for the selected recipe. The commands below assume that a complete prepared tree is available at `/tmp/nixos_configs` and the chosen recipe is `/tmp/disk-config.nix`.

**Disko's destroy/format operation erases the selected target disk. Confirm the device and backups before running it.**

1. Boot the official NixOS installer and copy the prepared files into its environment.
2. Apply the prepared recipe:

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/v1.13.0 -- --mode destroy,format,mount /tmp/disk-config.nix
```

3. Copy the configuration tree onto the mounted system and detect hardware without duplicating Disko filesystem declarations:

```bash
sudo mkdir -p /mnt/etc/nixos
sudo cp -a /tmp/nixos_configs /mnt/etc/nixos/
sudo nixos-generate-config --no-filesystems --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos_configs/hosts/server/example/
```

4. Keep the selected prepared disk recipe in the tree and import it together with the matching pinned Disko module. Check that EFI/BIOS and bootloader settings agree.
5. Bootstrap the host SSH key and add its age recipient before the first build, following [SECRETS.md](nixos_configs_template/common/config/SECRETS.md). The host's encrypted file and shared encrypted values must be accessible to the host key.
6. Install using the selected host:

```bash
sudo nixos-install -I nixos-config=/mnt/etc/nixos/nixos_configs/hosts/server/example/configuration.nix
```

7. Reboot after installation and verify user login, storage, networking and any selected services.

Keep the configuration root owned and writable only by administrators. Optional dotfile copying uses `BASEPATHUSER`; set its source location explicitly in the client account module. See [UPGRADE_SYSTEM.md](UPGRADE_SYSTEM.md) for later upgrades.
