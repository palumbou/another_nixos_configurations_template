# Pacchetti

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene file di configurazione per diversi gruppi di pacchetti e servizi, organizzati per categoria funzionale.

## File Disponibili

- **`desktop.nix`** - Pacchetti generici per ambienti desktop
- **`development.nix`** - Strumenti di sviluppo, IDE, compilatori, ecc.
- **`firmware.nix`** - Driver e firmware per vari dispositivi
- **`fonts.nix`** - Font e configurazioni correlate
- **`gnome.nix`** - Pacchetti specifici per l'ambiente GNOME
- **`impresarial.nix`** - Software per uso aziendale
- **`management.nix`** - Strumenti di gestione del sistema
- **`multimedia.nix`** - Lettori audio/video, editor multimediali, ecc.
- **`network.nix`** - Strumenti di rete, browser, client email, ecc.
- **`printing.nix`** - CUPS e altri pacchetti per la stampa
- **`reading.nix`** - Lettori PDF e altri lettori di documenti
- **`ssh.nix`** - Configurazione SSH client/server
- **`system.nix`** - Pacchetti di sistema essenziali

## Utilizzo

Importa i file desiderati nel file `configuration.nix` del tuo host specifico:

```nix
imports = [
  # ...altri import...
  ../common/packages/desktop.nix
  ../common/packages/development.nix
  ../common/packages/multimedia.nix
  # ...altri pacchetti secondo le tue necessità...
];
```

## Personalizzazione

Ogni file è progettato per essere modulare e includere un insieme coerente di pacchetti correlati. Puoi:

- Modificare i file esistenti per aggiungere o rimuovere pacchetti
- Creare nuovi file per gruppi di pacchetti specifici per il tuo caso d'uso
- Utilizzare condizioni per installare pacchetti solo in determinati host

### Esempio di Modifica

Se desideri personalizzare il file `multimedia.nix` per aggiungere un nuovo pacchetto:

```nix
# Nel file multimedia.nix
{ config, pkgs, ... }:

{
  # Pacchetti multimediali
  environment.systemPackages = with pkgs; [
    # I pacchetti esistenti
    vlc
    mpv
    audacity
    # Aggiungi il tuo nuovo pacchetto
    obs-studio
  ];

  # Altre configurazioni relative ai multimedia
}
```

### Considerazioni

- È consigliabile mantenere i file organizzati per categoria per facilitare la manutenzione
- Considera le dipendenze tra pacchetti quando modifichi i file
- I file in questa cartella dovrebbero contenere solo configurazioni che desideri condividere tra più host