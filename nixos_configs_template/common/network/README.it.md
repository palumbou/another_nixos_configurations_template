# Network

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene configurazioni di rete che possono essere condivise tra i tuoi host NixOS.

## Struttura

```bash
network/
├── networkmanager.nix      # Configurazione principale di NetworkManager
└── nmconnection_files/     # File di connessione di NetworkManager
    ├── example-wifi.nmconnection
    ├── example-vpn.nmconnection
    └── ...altri file di connessione...
```

## File Disponibili

- **`networkmanager.nix`** - Configura NetworkManager come gestore delle connessioni di rete

### Sottocartella `nmconnection_files`

Questa cartella contiene file `.nmconnection` che definiscono connessioni specifiche per NetworkManager. Questi file possono essere generati da NetworkManager stesso o creati manualmente.

## Utilizzo

### Configurazione Base di NetworkManager

Per abilitare NetworkManager sul tuo host, importa il file `networkmanager.nix` nel tuo file `configuration.nix`:

```nix
imports = [
  # ...altri import...
  ../common/network/networkmanager.nix
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
  ../common/network/networkmanager.nix
  ./nm_configurations.nix
];
```

## Note di Sicurezza

- I file `.nmconnection` possono contenere password e altre informazioni sensibili. Assicurati di:
  - Impostare permessi appropriati (mode = "0600")
  - Considerare l'utilizzo di metodi più sicuri come Nix Secrets per le credenziali
  - Evitare di commettere informazioni sensibili nel controllo versione

## Personalizzazione

Puoi estendere la configurazione di rete:

- Aggiungendo nuovi file `.nmconnection` nella cartella `nmconnection_files`
- Modificando il file `networkmanager.nix` per cambiare le impostazioni di default
- Creando configurazioni alternative per altri sistemi di rete (come systemd-networkd)