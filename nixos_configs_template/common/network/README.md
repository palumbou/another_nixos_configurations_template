# Network

This folder contains network configurations that can be shared across your NixOS hosts.

> **Available languages**: [English (current)](README.md) | [Italiano](README.it.md)

## Structure

```bash
network/
├── default_bluetooth.nix   # Bluetooth support configuration
└── default_network.nix     # Main NetworkManager + WireGuard configuration
```

## Available Files

- **`default_network.nix`** - Configures NetworkManager, WireGuard tools, and the firewall

## Usage

### Base Network Configuration

To enable NetworkManager and WireGuard tools on your host, import `default_network.nix` in your `configuration.nix`:

```nix
imports = [
  # ...other imports...
  ../common/network/default_network.nix
];
```

### WiFi Connections (declarative, with sops-nix)

WiFi profiles are declared per host through NetworkManager's `ensureProfiles`: a small systemd service generates the connections **directly inside NetworkManager** at every activation - no `.nmconnection` files to copy around. The pre-shared keys never enter the Nix store: they live sops-encrypted in `secrets/common.yaml` (one `WIFI_*_PSK` variable per network) and get substituted at activation from the decrypted environment file. See [`SECRETS.md`](../config/SECRETS.md) for the full guide and `hosts/ABC/nm_configurations.nix.template` for a ready-made example:

```nix
{ config, ... }:

{
  sops.secrets.wifi_env = {
    sopsFile = ../../secrets/common.yaml;
  };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets.wifi_env.path ];
    profiles = {
      "HomeWiFi" = {
        connection = { id = "HomeWiFi"; type = "wifi"; };
        wifi = { mode = "infrastructure"; ssid = "HomeWiFi"; };
        wifi-security = { key-mgmt = "wpa-psk"; psk = "$WIFI_HOME_PSK"; };
        ipv4.method = "auto";
        ipv6.method = "disabled";
      };
    };
  };
}
```

Then import the host's `nm_configurations.nix` in its `configuration.nix` as usual.

The rendered profiles (with the real PSKs) live in `/run/NetworkManager/system-connections/` - a RAM-backed tmpfs, root-only - and are regenerated at every activation: nothing secret ever touches the persistent disk in cleartext, and everything evaporates at shutdown. For the same reason, avoid editing these profiles via GUI or `nmcli connection modify` (NetworkManager would persist a copy under `/etc/`): the source of truth is the Nix configuration plus the sops secrets file.

## Security Notes

- WiFi credentials are sops-encrypted in the repository and decrypted only at activation under `/run/secrets` (see [`SECRETS.md`](../config/SECRETS.md)); never write PSKs in cleartext in `.nix` files.

### WireGuard VPN

`default_network.nix` includes `wireguard-tools` for managing WireGuard VPN tunnels.
The WireGuard kernel module is built-in since Linux 5.6+, and NetworkManager has native WireGuard support - no extra plugin is required.

To configure a WireGuard interface, you can either:
- Use `wg-quick` with a config file in `/etc/wireguard/wg0.conf`
- Use NetworkManager's native WireGuard connection type

If this host acts as a WireGuard server or listener, uncomment `allowedUDPPorts` in the firewall section of `default_network.nix`:

```nix
networking.firewall.allowedUDPPorts = [ 51820 ];
```

## Customization

You can extend the network configuration by:

- Declaring new WiFi profiles in the hosts' `nm_configurations.nix` (PSKs go in `secrets/common.yaml`)
- Modifying `default_network.nix` to change default settings or enable the WireGuard firewall port
- Creating alternative configurations for other networking systems (like systemd-networkd)