# Interfacce grafiche

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Desktop locale e sessioni Xfce remote sono scelte indipendenti. Scegli `none`, KDE, GNOME o Hyprland per il desktop locale. Un host senza desktop non richiede un modulo grafico locale.

| File | Funzione |
| --- | --- |
| `gnome.nix` | Desktop GNOME e relativo display manager. |
| `kde.nix` | KDE Plasma, relativo display manager e gruppo di pacchetti KDE. |
| `hyprland.nix.template` | Ambiente Wayland Hyprland, strumenti di sessione e tema; sostituisci `${FONT}`. |
| `xfce-rdp.nix` | Sessioni Xfce tramite xrdp, senza avviare un display manager locale. |

## Utilizzo

Da `hosts/client/<nome>/configuration.nix` o `hosts/server/<nome>/configuration.nix`, scegli un desktop locale con un import opzionale:

```nix
imports = [
  ../../../common/gui/kde.nix
];
```

Per Xfce remoto opzionale aggiungi `../../../common/gui/xfce-rdp.nix` indipendentemente dal desktop locale. L'host imposta `RDP_PORT`; i CIDR IPv4/IPv6 consentiti appartengono a `nm_configurations.nix` dell'host. Il modulo RDP non apre automaticamente porte firewall, impedisce il login diretto di root e richiede una password PAM non vuota. Configura separatamente la password dell'account non root desiderato; le chiavi SSH non sono credenziali RDP.

`xfce-rdp.nix` usa una sessione D-Bus dedicata e lascia il server X locale disabilitato per impostazione predefinita. Un eventuale desktop locale selezionato può comunque abilitare il proprio servizio grafico locale.

## Temi e configurazione locale

[`themes/`](themes/README.it.md) contiene temi GRUB, Hyprland e Plymouth. Scegli un tema per applicazione e controlla pacchetti e valori predefiniti di ogni desktop. Il layout tastiera proviene da `system.nix.template` condiviso tramite `KEY_LAYOUT`.

Evita di selezionare più moduli desktop locali completi senza verificarne display manager e impostazioni di sessione. La scelta del desktop non seleziona gruppi di applicazioni opzionali, Docker o libvirt.

Per Hyprland includi la configurazione di avvio dell'agent Polkit di sistema in `~/.config/hypr/hyprland.conf`:

```conf
# Import NixOS system-wide configuration.
source = /etc/hyprland/hyprland.d/polkit.conf
```

Posizionala vicino alle altre direttive `source`. Un agent di autenticazione serve per le richieste di privilegi del desktop, come Virt Manager, mount dei dischi e Btrfs Assistant.
