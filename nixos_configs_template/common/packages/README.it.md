# Pacchetti

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene file di configurazione per diversi gruppi di pacchetti e servizi, organizzati per categoria funzionale.

## File Disponibili

- **`default_packages_services.nix`** - Pacchetti e servizi essenziali predefiniti per la funzionalità di base del sistema
- **`extra_packages_services.nix`** - Pacchetti e servizi aggiuntivi per funzionalità estese
- **`grub.nix`** - Configurazione del bootloader GRUB (deve essere importato quando si utilizza GRUB come bootloader)
- **`kde_packages.nix`** - Pacchetti specifici per l'ambiente KDE Plasma (già importato nel file ../gui/kde.nix)
- **`syncthing.nix`** - Configurazione per il servizio di sincronizzazione file Syncthing
- **`workstation_packages_services.nix`** - Pacchetti e servizi adattati per le configurazioni workstation

## Utilizzo

Importa i file desiderati nel file `configuration.nix` specifico del tuo host:

```nix
imports = [
  # ...altri import...
  ../common/packages/default_packages_services.nix
  ../common/packages/workstation_packages_services.nix
  ../common/packages/syncthing.nix
  # ...altri pacchetti secondo necessità...
];
```

## Personalizzazione

Ogni file è progettato per essere modulare e includere un insieme coerente di pacchetti correlati. Puoi:

- Modificare i file esistenti per aggiungere o rimuovere pacchetti
- Creare nuovi file per gruppi di pacchetti specifici per il tuo caso d'uso
- Utilizzare condizioni per installare pacchetti solo su determinati host

### Esempio di Modifica

Se desideri personalizzare il file `workstation_packages_services.nix` per aggiungere un nuovo pacchetto:

```nix
# Nel file workstation_packages_services.nix
{ config, pkgs, ... }:
{
  # Aggiungi pacchetti per workstation
  environment.systemPackages = with pkgs; [
    gimp        # Editor di immagini
    # Aggiungi il tuo nuovo pacchetto
    vscode      # Editor Visual Studio Code
  ];

  # Altre configurazioni relative alla workstation
}
```

### Considerazioni

- È consigliabile mantenere i file organizzati per categoria per facilitare la manutenzione
- Considera le dipendenze tra pacchetti quando modifichi i file
- I file in questa cartella dovrebbero contenere solo configurazioni che desideri condividere tra più host