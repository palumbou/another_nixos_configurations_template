# User profiles

[English](README.md) | [Italiano](README.it.md)

The account modules separate administration, a personal client session and work execution. Choose unique account names, UIDs and GIDs before using the files.

| Module | Purpose | Imported by |
| --- | --- | --- |
| `ADMIN/admin.nix.template` | Essential administrator, `wheel`, shared password hash, global shell aliases/history | Server hosts and the client profile |
| `ADMIN/client.nix.template` | Imports `admin.nix`; personal CLI/desktop packages, home folders, dictionaries, client sudo path and Syncthing identity | Client hosts |
| `WORKER/worker.nix.template` | Separate normal account with private home, host password hash, shared work group and directories | Server hosts |

The final layout is `users/<admin>/admin.nix`, `users/<admin>/client.nix` and `users/<worker>/worker.nix`. Keep the two administrator files together so `./admin.nix` resolves. Passwords, hashes and authorized SSH keys belong in encrypted YAML; see [SECRETS.md](../common/config/SECRETS.md).

## Configure manually

1. Copy the configuration tree. Rename `ADMIN` and `WORKER` to the chosen usernames and remove `.template` from the Nix modules you use. Replace uppercase `${...}` markers using the table below. Preserve Nix expressions such as `${lib.makeBinPath [ pkgs.systemd ]}`.
2. Choose `hosts/client/ABC` or `hosts/server/ABC`, rename `ABC` to the hostname and fill the host markers. A client imports `../../../users/<admin>/client.nix`; a server imports `../../../users/<admin>/admin.nix` and `../../../users/<worker>/worker.nix`.
3. Configure and encrypt `secrets/common.yaml` and `secrets/<hostname>.yaml`, and configure runtime SSH key templates. Every host imports `common/config/secrets.nix` and selects `sops.defaultSopsFile = ../../../secrets/<hostname>.yaml`.
4. Review and evaluate/build the intended NixOS host before activation.

| Marker | Generic example / meaning |
| --- | --- |
| `ADMIN_USER`, `ADMIN_UID`, `ADMIN_GID` | `admin`, `1000`, `1000` |
| `WORKER_USER`, `WORKER_UID`, `WORKER_GID` | `worker`, `1001`, `1001` |
| `WORK_GROUP`, `WORK_GID` | `work-data`, `1100`; distinct from both private groups |
| `WORK_ROOT` | `/srv/worker`; absolute path without whitespace |
| `DICTIONARY` | `it_IT`; a `pkgs.hunspellDicts` attribute; `en_US` is also installed |
| `BASEPATHUSER` | Optional dotfiles rule only: absolute parent directory of `nixos_configs` |

The worker module checks that both account names/UIDs and all three group names/GIDs are distinct. Choose positive IDs without collisions with existing users or service groups. Numeric fields are Nix integers, without quotes.

The essential administrator installs no personal applications. The client profile installs its packages even without a graphical desktop; adjust that list for the machine. The client package baseline enables unfree packages for the profile. `zz`, dictionaries and sudo `secure_path` belong to the client. `secure_path` controls command lookup, not which commands are authorized. Client groups `audio`, `input` and `video` are unconditional. Docker, NetworkManager, libvirt, non-root QEMU and I²C groups follow the corresponding enabled features. The client explicitly keeps `users.mutableUsers = true`; the essential profile leaves this policy to the host.

## Worker data

The worker has no `wheel`, Docker or libvirt membership. Its primary group is private and its home mode is `0700`. `WORK_GROUP` includes administrator and worker, plus the Syncthing identity only when the enabled service is a system service.

`WORK_ROOT` is a root-owned `2750` container. `WORK_ROOT/data` and its `workspaces`, `documents` and `results` directories belong to the worker/shared group with mode `2770`. Setgid preserves group ownership. Default ACLs give the owner/group access to new entries and deny others. Explicit application modes such as `0600` can still restrict access. These rules do not recursively repair old files. Keep snapshots/backups of the container separate from synchronization of `data`.

## Syncthing by host

Host modules configure synchronization. The client user module defines the service identity. Server hosts use the dedicated `syncthing` account with state in `/var/lib/syncthing`. Clients use their administrator account, configuration in `/home/<admin>/.config/syncthing` and data root `/home/<admin>/Sync`.

| Marker | Meaning |
| --- | --- |
| `ENABLE_SYNCTHING` | Nix boolean `true` or `false` |
| `SYNCTHING_DEVICE_ID` | Remote ID; empty starts the local service without a remote device/shared folder |
| `SYNCTHING_ADDRESS` | Explicit address, e.g. `tcp4://storage.example.invalid:22222` |
| `SYNCTHING_FOLDER_ID` | Same folder ID on both peers, e.g. `work-data` |
| `SYNCTHING_FOLDER_PATH` | Server default `/srv/worker/data`; client default `/home/admin/Sync/work-data` |

A configured peer shares one `sendreceive` folder with `ignorePerms = false`: changes, deletions and Unix permissions propagate. Common dependency/cache directories are excluded. Keep the server path at `WORK_ROOT/data` to use the worker ACLs; another path requires separately configured permissions.

The GUI uses HTTPS at `127.0.0.1:8843`. Global/local discovery, NAT traversal and relays are disabled. No firewall ports are opened automatically. Add an explicit, scoped TCP rule for port `22222` when peers must initiate inbound connections. An SSH tunnel such as `ssh -L 8843:127.0.0.1:8843 admin@host.example.invalid` gives GUI access at `https://127.0.0.1:8843`; verify the local certificate. Declared devices/folders are authoritative and undeclared entries are removed on restart. Synchronization does not replace backups.

## Optional dotfiles

The client module has a commented tmpfiles `C+` example. Create `users/<admin>/dotfiles`, then uncomment the rule inside `systemd.tmpfiles.rules`. The source is `${BASEPATHUSER}/nixos_configs/users/<admin>/dotfiles`. Review systemd's copy behavior before enabling it on an existing home, or use a dedicated dotfiles tool.
