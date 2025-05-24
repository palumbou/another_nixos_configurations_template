# Configurazione del Sistema

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene file di configurazione di base del sistema che definiscono i comportamenti fondamentali del sistema e i privilegi degli utenti.

## File Disponibili

- **`boot_luks.nix`** - Configurazione per il boot con crittografia LUKS e impostazioni Plymouth per la schermata di avvio
- **`sudo.nix`** - Configurazione per i privilegi sudo e le autorizzazioni degli utenti
- **`system.nix`** - Impostazioni di base del sistema, inclusi locale, fuso orario e comportamenti fondamentali

## Utilizzo

Importa questi file di configurazione nel file `configuration.nix` specifico del tuo host:

```nix
imports = [
  # ...altri import...
  ../common/config/boot_luks.nix
  ../common/config/sudo.nix
  ../common/config/system.nix
  # ...altre configurazioni secondo necessità...
];
```

## Personalizzazione

I file di configurazione in questa directory definiscono le impostazioni fondamentali del sistema. Puoi:

- Modificare `boot_luks.nix` per personalizzare le impostazioni di boot crittografato e la configurazione di Plymouth
- Modificare `sudo.nix` per regolare i livelli di privilegio degli utenti e le politiche di sicurezza
- Aggiornare `system.nix` per cambiare le impostazioni locali, i fusi orari o i comportamenti di base del sistema
- Fare riferimento a variabili specifiche dell'host per personalizzare le impostazioni per ogni macchina

### Esempio di Modifica

Se desideri personalizzare le impostazioni di sistema in `system.nix`:

```nix
# Nel file system.nix
{ config, pkgs, ... }:

{
  # Imposta il tuo fuso orario
  time.timeZone = "Europe/Rome";
  
  # Seleziona le proprietà di internazionalizzazione
  i18n.defaultLocale = "it_IT.UTF-8";
  
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };
  
  # Aggiungi qui le tue impostazioni di sistema personalizzate
  system.stateVersion = "25.05"; # NON MODIFICARE QUESTO VALORE
}
```

### Considerazioni

- I file di configurazione in questa directory formano la base della tua configurazione di sistema
- Fai attenzione quando modifichi le impostazioni di base poiché possono influire sulla stabilità del sistema
- Testa sempre le modifiche in un ambiente controllato prima di implementarle sui sistemi di produzione