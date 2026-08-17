# Network

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene configurazioni di rete che possono essere condivise tra i tuoi host NixOS.

## Struttura

```bash
network/
├── default_bluetooth.nix   # Configurazione del supporto Bluetooth
└── default_network.nix     # Configurazione principale di NetworkManager + WireGuard
```

## File Disponibili

- **`default_network.nix`** - Configura NetworkManager, gli strumenti WireGuard e il firewall

## Utilizzo

### Configurazione Base della Rete

Per abilitare NetworkManager e gli strumenti WireGuard sul tuo host, importa `default_network.nix` nel tuo `configuration.nix`:

```nix
imports = [
  # ...altri import...
  ../common/network/default_network.nix
];
```

### Connessioni WiFi (dichiarative, con sops-nix)

I profili WiFi si dichiarano per host tramite `ensureProfiles` di NetworkManager: un piccolo servizio systemd genera le connessioni **direttamente dentro NetworkManager** a ogni attivazione - niente file `.nmconnection` da copiare in giro. Le chiavi precondivise non entrano mai nel Nix store: vivono cifrate con sops in `secrets/common.yaml` (una variabile `WIFI_*_PSK` per rete) e vengono sostituite all'attivazione dall'environment file decifrato. Vedi [`SECRETS.it.md`](../config/SECRETS.it.md) per la guida completa e `hosts/ABC/nm_configurations.nix.template` per un esempio già pronto:

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

Poi importa il `nm_configurations.nix` del host nel suo `configuration.nix` come di consueto.

I profili renderizzati (con le PSK vere) vivono in `/run/NetworkManager/system-connections/` - una tmpfs in RAM, accessibile solo a root - e vengono rigenerati a ogni attivazione: nulla di segreto tocca mai il disco persistente in chiaro, e allo spegnimento tutto evapora. Per lo stesso motivo, evita di modificare questi profili dalla GUI o con `nmcli connection modify` (NetworkManager ne salverebbe una copia persistente sotto `/etc/`): la fonte di verità è la configurazione Nix più il file dei segreti sops.

## Note di Sicurezza

- Le credenziali WiFi sono cifrate con sops nel repository e decifrate solo all'attivazione sotto `/run/secrets` (vedi [`SECRETS.it.md`](../config/SECRETS.it.md)); non scrivere mai PSK in chiaro nei file `.nix`.

### WireGuard VPN

`default_network.nix` include `wireguard-tools` per gestire i tunnel VPN WireGuard.
Il modulo kernel WireGuard è integrato da Linux 5.6+, e NetworkManager ha supporto nativo per WireGuard - nessun plugin aggiuntivo è necessario.

Per configurare un'interfaccia WireGuard, puoi:
- Usare `wg-quick` con un file di configurazione in `/etc/wireguard/wg0.conf`
- Usare il tipo di connessione WireGuard nativo di NetworkManager

Se questo host funge da server o listener WireGuard, decommenta `allowedUDPPorts` nella sezione firewall di `default_network.nix`:

```nix
networking.firewall.allowedUDPPorts = [ 51820 ];
```

## Personalizzazione

Puoi estendere la configurazione di rete:

- Dichiarando nuovi profili WiFi negli `nm_configurations.nix` dei host (le PSK vanno in `secrets/common.yaml`)
- Modificando `default_network.nix` per cambiare le impostazioni di default o abilitare la porta firewall WireGuard
- Creando configurazioni alternative per altri sistemi di rete (come systemd-networkd)