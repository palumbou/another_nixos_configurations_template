# GUI

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene configurazioni per diverse interfacce grafiche utente (GUI) che possono essere utilizzate nei tuoi host NixOS.

## File Disponibili

- **`hyprland.nix`** - Configurazione per l'ambiente desktop basato su Wayland Hyprland
- **`kde.nix`** - Configurazione per l'ambiente desktop KDE Plasma

## Utilizzo

Per utilizzare uno di questi ambienti desktop, importa il file corrispondente nel file `configuration.nix` del tuo host:

```nix
# Per KDE Plasma
imports = [
  # ...altri import...
  ../common/gui/kde.nix
];

# OPPURE per Hyprland
imports = [
  # ...altri import...
  ../common/gui/hyprland.nix
];
```

## Personalizzazione

Ogni file contiene sia i pacchetti necessari per l'ambiente desktop che le configurazioni specifiche. Puoi modificare questi file per:

- Aggiungere o rimuovere pacchetti specifici per l'ambiente
- Modificare impostazioni di default
- Abilitare o disabilitare funzionalità specifiche

### Note sull'Utilizzo

- **Evita di importare più file GUI contemporaneamente** in un singolo host per prevenire conflitti.
- Se desideri utilizzare componenti di più ambienti desktop, considera la creazione di un file personalizzato che importi solo pacchetti specifici da ciascun ambiente.
- I file sono organizzati per essere modulari e indipendenti dalle configurazioni utente, permettendoti di condividerli tra più host.