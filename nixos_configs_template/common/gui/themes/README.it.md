# Temi

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa directory contiene vari temi disponibili per i software che sono stati considerati nei file di configurazione.

## Temi Disponibili

I temi sono organizzati per software:

- **grub**: temi per il bootloader GRUB
- **hyprland**: temi per il gestore di finestre Hyprland
- **plymouth**: temi per la schermata di avvio Plymouth

## Come Utilizzarli

Per utilizzare questi temi, è necessario abilitarli singolarmente nei rispettivi file di installazione. Ogni file di tema è strutturato come un modulo NixOS che può essere importato nella configurazione del sistema.

### Esempio

Per abilitare un tema, importa il suo file di configurazione nel file specifico del software corrispondente:

```nix
# Nel file ../common/gui/hyprland.nix
{
  imports = [
    # Percorso relativo al tema che vuoi utilizzare
    ./themes/hyprland/hyprland_catppuccin.nix
  ];
}
```

Assicurati di abilitare solo un tema per software alla volta per evitare conflitti.
