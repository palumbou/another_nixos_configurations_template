# Cartella Common

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene file di configurazione NixOS che sono **comuni** a tutte le combinazioni di host e utente. Include tre sottocartelle `gui`, `packages` e `network` e un file `system.nix`.

## Struttura della cartella

```bash
common/
├── config/
│   ├── boot_luks.nix
│   ├── sudo.nix
│   └── system.nix.template
├── gui/
│   ├── gnome.nix.template
│   ├── hyprland.nix.template
│   ├── kde.nix.template
│   └── themes/
│       ├── grub/
│       │   └── grub_catppuccin.nix
│       ├── hyprland/
│       │   └── hyprland_catppuccin.nix
│       └── plymouth/
│           ├── plymouth_breeze-plymouth.nix
│           ├── plymouth_catppucin.nix
│           ├── plymouth_nixos-bgrt.nix
│           └── plymouth_plymouth-themes.nix
├── network/
│   ├── default_network.nix
│   └── nmconnection_files/
└── packages/
    ├── default_packages_services.nix.template
    ├── extra_packages_services.nix
    ├── grub.nix
    ├── kde_packages.nix
    ├── syncthing.nix.template
    └── workstation_packages_services.nix
```

---

### Cartella `config`

Questa cartella archivia configurazioni **relative al Sistema Operativo**:

- **`boot_luks.nix`** per configurare i parametri di boot con supporto alla crittografia LUKS e le impostazioni di Plymouth per la schermata di avvio.
- **`sudo.nix`** per abilitare e gestire sudo, come l’aggiunta di regole personalizzate che consentono agli utenti nel gruppo **`wheel`** (amministratori) di eseguire specifici comandi di sistema **senza richiedere password** (opzione NOPASSWD).
- **`system.nix`** contiene impostazioni relative alla localizzazione e alla versione specifica di NixOS che stai utilizzando. In genere importerai questo file nel `configuration.nix` di ciascun host per garantire impostazioni coerenti a livello di locale e di sistema su tutti gli host.

---

### Cartella `gui`

Questa cartella archivia le configurazioni per gli ambienti grafici che puoi scegliere di abilitare:

- **`gnome.nix`** – Gnome  
- **`hyprland.nix`** – Hyprland  
- **`kde.nix`** – KDE Plasma (versione 6)
- **`themes/`** - Una sottocartella contenente temi per vari software (GRUB, Hyprland, Plymouth, ...)

Le configurazioni di Gnome e KDE provengono dalle installazioni di NixOS, mentre la configurazione Hyprland è personalizzata, includendo pacchetti di base per un setup funzionale (display manager, file manager, terminale, barra di stato e launcher). Tutti i file abilitano anche l’audio con PipeWire.

> **Nota**: Assicurati di modificare le variabili  
> - in **`gnome.nix`** e **`kde.nix`**, sostituisci `${KEY_LAYOUT}` con il codice [ISO 639](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) desiderato per il layout della tastiera  
> - in **`hyprland.nix`**, sostituisci `${FONT}` con il tuo font preferito e seleziona il tema desiderato

---

### Cartella `packages`

Questa cartella include configurazioni per pacchetti e servizi. Ogni file ha il proprio scopo:

- **`default_packages_services.nix`**  
  Pacchetti e servizi di base che dovrebbero essere abilitati su tutti gli host di default.
- **`extra_packages_services.nix`**  
  Pacchetti e servizi per configurazioni specifiche (ad es. l’installazione di **solaar** per dispositivi Logitech).
- **`grub.nix`**  
  Configurazione del boot loader (GRUB) (ad es. abilitare il tema “catppuccin”).
- **`kde_packages.nix`**  
  Programmi aggiuntivi per migliorare l’ambiente KDE Plasma. Questo file viene importato automaticamente se scegli KDE in `gui/kde.nix`.
- **`syncthing.nix`**  
  Configurazione di **Syncthing**. Leggi il file per maggiori informazioni.
- **`workstation_packages_services.nix`**  
  Pacchetti e servizi potenzialmente utili a tutti gli utenti su un host workstation.

> **Nota:** Queste categorie e i pacchetti/servizi inclusi si basano su necessità personali, non su documentazione ufficiale.

---

### Cartella `network`

Questa cartella contiene configurazioni **relative alla rete**:

- **`default_network.nix`**  
  Configurazione di base per NetworkManager.
- **`nmconnection_files`**  
  Una sottocartella per archiviare i file `.nmconnection` che definiscono WiFi, VPN o altre connessioni di rete gestite da NetworkManager.

Se vuoi importare le configurazioni di NetworkManager durante la build (ad es. WiFi, VPN, ecc.), posiziona i file `.nmconnection` qui. Quindi dichiarali nel file `nm_configurations.nix` di ogni host.  
Tali file possono essere copiati direttamente dal tuo sistema (solitamente in `/etc/NetworkManager/system-connections`) o generati da uno script (attualmente in sviluppo).  
Se un file `.nmconnection` viene dichiarato ma non si trova in questa cartella, riceverai un avviso durante la build (anche se non causerà un errore).