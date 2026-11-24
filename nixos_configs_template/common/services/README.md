# Services

> **Available languages**: [English (current)](README.md) | [Italiano](README.it.md)

These reusable modules enable local services independently of graphical clients. Declare user identities, authorized keys and machine-specific access rules in the host or user modules.

## Available modules

| File | Behavior |
| --- | --- |
| `docker.nix` | Rootful Docker daemon, enabled at boot; automatic pruning and rootless Docker disabled. |
| `libvirt.nix` | libvirt daemon with KVM-enabled QEMU, the dedicated `qemu-libvirtd` account, software TPM and Polkit authorization. Starts configured guests at boot and shuts them down at host shutdown. |
| `server_ssh.nix.template` | Server OpenSSH policy: public-key authentication; direct root login, password and keyboard-interactive authentication disabled; `openFirewall = false`. |

## Docker and libvirt

From `hosts/server/<name>/configuration.nix`:

```nix
imports = [
  ../../../common/services/docker.nix
  ../../../common/services/libvirt.nix
];
```

Select each daemon where needed. The [package modules](../packages/README.md) provide independent Compose and virtualization tools. `distrobox.nix` imports `docker.nix` and selects Docker through `DBX_CONTAINER_MANAGER = "docker"`. `virtualization_tools.nix` enables Virt Manager and SPICE USB redirection without enabling a local libvirt daemon, so it can manage remote hosts.

`libvirt.nix` preserves the `libvirt-default-network` oneshot service: after `libvirtd.service`, it marks the `default` network for automatic startup and starts it if it is not already active. The service runs under `multi-user.target` and needs no desktop session. Network definitions and guest definitions belong to the host's virtualization configuration.

The client account module adds relevant hardware/daemon groups conditionally. The worker identity remains outside administrator, Docker and libvirt groups; administrative operations use sudo through the separate administrator account. Keep identities in account modules and key data in the host's configured encrypted values.

## Server OpenSSH

The [server](../../roles/README.md) role imports the server SSH module. To reuse it in another profile:

```nix
imports = [
  ../../../common/services/server_ssh.nix
];
```

Prepare `server_ssh.nix.template` as `server_ssh.nix` and replace `${SSH_PORT}` with a numeric port. Define the user and authorized keys in the host or user modules.

Firewall openings and any subnet filters belong to the host networking configuration, for example `nm_configurations.nix`. Firewall rules must use the OpenSSH port. Adapt the example in the [network guide](../network/README.md) to the selected port and permitted networks.

The client baseline keeps its authentication policy in `../packages/default_packages_services.nix.template`; choose the module matching the host's role.
