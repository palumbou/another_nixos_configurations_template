# Network

> **Available languages**: [English (current)](README.md) | [Italiano](README.it.md)

Shared modules provide network foundations; profiles and permitted service networks belong to each host.

| Module | Purpose |
| --- | --- |
| `default_network.nix` | Client NetworkManager, firewall and WireGuard tools. |
| `server_network.nix` | Server NetworkManager, nftables and firewall; imported by the server role. |
| `default_bluetooth.nix` | Bluetooth hardware and firmware configuration. A graphical manager is selected separately. |

From a host under `hosts/client/<name>/` or `hosts/server/<name>/`, common imports use `../../../common/network/`. The server role already imports its server network module. See [roles](../../roles/README.md) and [services](../services/README.md).

## Host profiles and access rules

Both host categories contain `nm_configurations.nix.template`. Prepare it as `nm_configurations.nix` and keep its local import in the host's `configuration.nix`. It owns WiFi and SSH/RDP CIDR filters.

If `RDP_ALLOWED_CIDRS` is empty, use the SSH CIDRs for RDP. Then split `SSH_ALLOWED_CIDRS` and the effective RDP CIDRs into their IPv4 and IPv6 families and render their `*_ALLOWED_IPV4_NIX`/`*_ALLOWED_IPV6_NIX` tokens as Nix lists. For example, documentation-only networks render as:

```nix
  ssh4 = [ "192.0.2.0/24" ];
  ssh6 = [ "2001:db8::/32" ];
  rdp4 = [];
  rdp6 = [];
```

Use networks appropriate to the actual host. The module builds nftables rules from these lists and reads the actual OpenSSH ports and xrdp port from NixOS configuration, so changing `SSH_PORT` or `RDP_PORT` keeps the filter aligned.

A configured SSH subnet filter disables OpenSSH's automatic firewall opening. Keep the same service ports out of global/interface `allowedTCPPorts`, port ranges and trusted interfaces, which could bypass a source restriction. IPv4 and IPv6 are handled separately.

The server's SSH and RDP modules open no ports automatically. Empty CIDR lists add no accept rules. The client baseline retains its existing OpenSSH firewall policy unless a subnet filter is supplied. RDP needs an allowed range, supplied directly or inherited from SSH.

## WiFi with encrypted credentials

Set `ENABLE_WIFI=true` and render `WIFI_SSID_NIX` as a complete escaped Nix string. SSIDs are public host configuration. The host file `../../../secrets/<hostname>.yaml` holds the encrypted `wifi_env` value containing `WIFI_PSK`; follow [SECRETS.md](../config/SECRETS.md). Disabled WiFi needs `ENABLE_WIFI=false` and `WIFI_SSID_NIX=""`.

NetworkManager's `ensureProfiles` reads the decrypted environment file at activation. The template keeps IPv4 and IPv6 automatic and uses `"$WIFI_PSK"` for the PSK; leave that runtime variable intact. Host-key recipients must be prepared before activation.

The declarative profiles are applied under `/run/NetworkManager/system-connections/`. Keep the Nix host configuration and encrypted secret as the source of truth. Editing profiles with the GUI or `nmcli connection modify` can persist additional copies under `/etc/`.

## Syncthing and VPN

Syncthing lives in each host's `syncthing.nix` and disables automatic port openings. Permit its selected TCP listener only from the intended peer networks in the host's network policy; its HTTPS GUI listens on loopback and can be reached through SSH tunneling. See the [host guide](../../hosts/README.md).

The client module includes `wireguard-tools`. NetworkManager supports WireGuard connections directly; alternatively use `wg-quick`. Add an explicit UDP firewall rule only on a host that listens for incoming VPN traffic.
