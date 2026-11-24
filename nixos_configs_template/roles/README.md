# Roles

> **Available languages**: [English (current)](README.md) | [Italiano](README.it.md)

Roles compose shared modules. A host selects one role and adds users, hardware, storage, boot and optional capabilities.

| File | Contents |
| --- | --- |
| `base.nix` | Locale, time zone and keyboard settings through `common/config/system.nix`. |
| `client.nix` | Base, binary compatibility, optimizations and client sudo rules. |
| `server.nix` | Base, essential CLI tools, server OpenSSH and server networking. |

## Usage

For a host at `hosts/client/<name>/configuration.nix`:

```nix
imports = [
  ../../../roles/client.nix
  ../../../users/ADMIN/client.nix
];
```

For a host at `hosts/server/<name>/configuration.nix`:

```nix
imports = [
  ../../../roles/server.nix
  ../../../users/ADMIN/admin.nix
  ../../../users/WORKER/worker.nix
];
```

Both roles already import `base.nix`. The client role leaves the desktop, networking and application packages to the host. The client account module imports the essential administrator identity and adds personal client applications. The server administrator remains minimal; the separate worker account has no administrator or local-daemon group privileges.

The server role includes Bash, Python, Git, ripgrep, rsync, curl, jq, GNU file and archive tools, unzip and ACL tools. Project tools, Docker, libvirt, Syncthing, a local desktop and Xfce RDP remain separate host selections. The server role sets `nixpkgs.config.allowUnfree = true;`, matching the client’s `default_packages_services.nix` baseline.

Use the server modules for a server host. `common/packages/default_packages_services.nix` belongs to clients and declares a different SSH policy; do not combine it with the server role.

## Host policy

The examples live in `hosts/client/ABC/` and `hosts/server/ABC/`. Prepare the selected templates manually with public values from [`env.conf`](../../env.conf); see the [HOWTO](../../HOWTO.md). Optional imports and boot settings fill `${HOST_IMPORTS}` and `${HOST_EXTRA_CONFIG}` respectively.

The [server SSH module](../common/services/README.md) uses key authentication and opens no firewall port. Replace `${SSH_PORT}` with the selected numeric port. Allowed CIDRs, WiFi, RDP and Syncthing are host-specific; keep `system.stateVersion` in the host.

The server host disables idle and lid-triggered sleep, suspend and hibernation. Optional battery handling powers off at its action threshold rather than hibernating; `ENABLE_BATTERY=false` disables UPower even if a desktop requests it. Charge-limit settings must match the actual TLP hardware plugin. Build limits, zram, snapshots, work-directory permissions and network access are declared by the host and account modules, rather than by the shared role.
