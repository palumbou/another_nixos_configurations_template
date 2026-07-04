# Network

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene configurazioni di rete che possono essere condivise tra i tuoi host NixOS.

## Struttura

```bash
network/
├── default_bluetooth.nix   # Configurazione del supporto Bluetooth
├── default_network.nix     # Configurazione principale di NetworkManager + WireGuard
└── nmconnection_files/     # File di connessione di NetworkManager
    ├── example-wifi.nmconnection
    ├── example-vpn.nmconnection
    └── ...altri file di connessione...
```

## File Disponibili

- **`default_network.nix`** - Configura NetworkManager, gli strumenti WireGuard e il firewall

### Sottocartella `nmconnection_files`

Questa cartella contiene file `.nmconnection` che definiscono connessioni specifiche per NetworkManager. Questi file possono essere generati da NetworkManager stesso o creati manualmente.

## Utilizzo

### Configurazione Base della Rete

Per abilitare NetworkManager e gli strumenti WireGuard sul tuo host, importa `default_network.nix` nel tuo `configuration.nix`:

```nix
imports = [
  # ...altri import...
  ../common/network/default_network.nix
];
```

### Utilizzo dei File di Connessione

I file `.nmconnection` contengono dettagli per configurare connessioni specifiche (WiFi, Ethernet, VPN, ecc.). Per utilizzarli:

1. Crea un file `nm_configurations.nix` nella cartella del tuo host specifico:

```nix
{ config, lib, pkgs, ... }:

{
  # Copia i file di connessione desiderati nella directory di NetworkManager
  environment.etc = {
    "NetworkManager/system-connections/my-home-wifi.nmconnection" = {
      source = ../common/network/nmconnection_files/my-home-wifi.nmconnection;
      mode = "0600"; # Importante: i file .nmconnection richiedono permessi restrittivi
    };
    
    "NetworkManager/system-connections/work-vpn.nmconnection" = {
      source = ../common/network/nmconnection_files/work-vpn.nmconnection;
      mode = "0600";
    };
    
    # Aggiungi altri file di connessione secondo necessità
  };
}
```

2. Importa questo file nel file `configuration.nix` del tuo host:

```nix
imports = [
  # ...altri import...
  ../common/network/default_network.nix
  ./nm_configurations.nix
];
```

## Note di Sicurezza

- I file `.nmconnection` possono contenere password e altre informazioni sensibili. Assicurati di:
  - Impostare permessi appropriati (mode = "0600")
  - Considerare l'utilizzo di metodi più sicuri come Nix Secrets per le credenziali
  - Evitare di commettere informazioni sensibili nel controllo versione

### WireGuard VPN

`default_network.nix` include `wireguard-tools` per gestire i tunnel VPN WireGuard.
Il modulo kernel WireGuard è integrato da Linux 5.6+, e NetworkManager ha supporto nativo per WireGuard — nessun plugin aggiuntivo è necessario.

Per configurare un'interfaccia WireGuard, puoi:
- Usare `wg-quick` con un file di configurazione in `/etc/wireguard/wg0.conf`
- Usare il tipo di connessione WireGuard nativo di NetworkManager

Se questo host funge da server o listener WireGuard, decommenta `allowedUDPPorts` nella sezione firewall di `default_network.nix`:

```nix
networking.firewall.allowedUDPPorts = [ 51820 ];
```

## Personalizzazione

Puoi estendere la configurazione di rete:

- Aggiungendo nuovi file `.nmconnection` nella cartella `nmconnection_files`
- Modificando `default_network.nix` per cambiare le impostazioni di default o abilitare la porta firewall WireGuard
- Creando configurazioni alternative per altri sistemi di rete (come systemd-networkd)