# GUI

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene configurazioni per diverse interfacce grafiche utente (GUI) che possono essere utilizzate nei tuoi host NixOS.

## File Disponibili

- **`gnome.nix`** - Configurazione per l'ambiente desktop GNOME
- **`hyprland.nix`** - Configurazione per l'ambiente desktop basato su Wayland Hyprland
- **`kde.nix`** - Configurazione per l'ambiente desktop KDE Plasma

## Temi

Questa cartella contiene anche una cartella **`themes`** con vari temi per software considerati nei file di configurazione, organizzati per applicazione:

- **`grub`** - Temi per il bootloader GRUB
- **`hyprland`** - Temi per il gestore di finestre Hyprland
- **`plymouth`** - Temi per la schermata di avvio Plymouth

Per utilizzare questi temi, è necessario abilitarli singolarmente nei rispettivi file di installazione. Vedi il [README.it.md](./themes/README.it.md) nella cartella **`themes`** per maggiori dettagli.

## Utilizzo

Per utilizzare uno di questi ambienti desktop, importa il file corrispondente nel file `configuration.nix` del tuo host:

```nix
# Per GNOME
imports = [
  # ...altri import...
  ../common/gui/gnome.nix
];

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