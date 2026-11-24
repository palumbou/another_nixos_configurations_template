# Pacchetti

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questi moduli riutilizzabili raggruppano i pacchetti per funzione. Scegli ogni gruppo opzionale nella configurazione dell'host; gli strumenti grafici e i demoni locali si possono selezionare separatamente.

## Moduli disponibili

| File | Pacchetti e comportamento |
| --- | --- |
| `default_packages_services.nix.template` | Base client: utilità da terminale, rete, dischi, sviluppo e multimedia; aggiornamenti firmware; pacchetti non liberi consentiti; policy OpenSSH client descritta sotto. |
| `photo_editing.nix` | Darktable e GIMP. |
| `video_editing.nix` | DaVinci Resolve. |
| `development.nix` | Visual Studio Code. |
| `recording.nix` | Abilita il modulo NixOS di OBS Studio. |
| `container_tools.nix` | Strumenti Docker Compose. Il demone Docker locale si seleziona separatamente. |
| `distrobox.nix` | Distrobox, demone Docker locale e integrazione Flatpak; imposta `DBX_CONTAINER_MANAGER = "docker"`. |
| `virtualization_tools.nix` | Virt Manager e reindirizzamento USB SPICE. Gestisce anche host libvirt remoti; non abilita un demone libvirt locale. |
| `btrfs_assistant.nix` | Installa il pacchetto della GUI Btrfs Assistant opzionale, separatamente dal modulo snapshot. Il desktop selezionato fornisce Polkit; i prompt grafici richiedono il relativo agent di autenticazione attivo. |
| `extra_packages_services.nix` | Solaar per i dispositivi Logitech. |
| `external_monitor.nix` | Abilita I2C e installa `ddcutil` per i controlli DDC/CI dei monitor e `v4l-utils` per i dispositivi video. Il modulo utente assegna il gruppo `i2c` in modo condizionale. |
| `gamestation_packages.nix` | Steam tramite il modulo NixOS, con supporto grafico a 32 bit e regole udev dei controller. Heroic è un pacchetto opzionale commentato. Le aperture firewall per Remote Play e server dedicati sono disabilitate. |
| `grub.nix` | Impostazioni e tema GRUB condivisi; da importare quando la configurazione di avvio selezionata usa GRUB. |
| `kde_packages.nix` | Filelight, Kate, KCalc, Partition Manager, Print Manager e Konsave; già importato da `../gui/kde.nix`. |
| `unstable_temporary_packages.nix` | Elenco vuoto per aggiunte temporanee, con un insieme opzionale di pacchetti nixos-unstable fissato a una revisione. Per usarlo non serve configurare manualmente il canale. |

Il precedente modulo workstation è suddiviso nei sette moduli di pacchetti dedicati e nei [moduli di servizio Docker e libvirt](../services/README.it.md). Importali tutti e nove per mantenere la selezione workstation completa, oppure scegli le funzioni necessarie.

La base client `default_packages_services.nix` e il ruolo server `roles/server.nix` impostano entrambi `nixpkgs.config.allowUnfree = true;`. Applicazioni, font e firmware opzionali usano questa policy per l’intero profilo.

## Utilizzo

Prepara i file `.nix.template` come file `.nix` e sostituisci i segnaposto con i valori dell'host. In `default_packages_services.nix.template`, sostituisci `${SSH_PORT}` con una porta numerica mantenendo la policy di autenticazione client.

Da `hosts/client/<nome>/configuration.nix`:

```nix
imports = [
  ../../../common/packages/default_packages_services.nix
  ../../../common/packages/photo_editing.nix
  ../../../common/packages/video_editing.nix
  ../../../common/packages/development.nix
  ../../../common/packages/recording.nix
  ../../../common/packages/container_tools.nix
  ../../../common/packages/distrobox.nix
  ../../../common/packages/virtualization_tools.nix
  ../../../common/services/docker.nix
  ../../../common/services/libvirt.nix
];
```

`distrobox.nix` importa già `docker.nix`; NixOS supporta entrambi gli import. Per usare soltanto Compose importa `container_tools.nix`. Per Docker locale senza Distrobox importa `../services/docker.nix`. Un host di macchine virtuali locali richiede `../services/libvirt.nix`; gli strumenti grafici di gestione restano opzionali.

Le identità degli account si definiscono in `users/ADMIN/admin.nix` e `users/WORKER/worker.nix`; personalizzazioni client e gruppi condizionali per hardware/demoni appartengono a `users/ADMIN/client.nix`. I moduli di servizio non contengono nomi utente, chiavi o regole di accesso specifici di una macchina.

## Policy OpenSSH client

La base client abilita OpenSSH su `${SSH_PORT}`, consente l'autenticazione con password agli utenti ordinari, disabilita quella keyboard-interactive e impedisce il login diretto di root. Dopo aver verificato l'accesso con chiave da tutte le macchine necessarie puoi impostare esplicitamente `PasswordAuthentication = false`. I profili server usano il [modulo SSH server](../services/README.it.md) separato.

## Personalizzazione

Aggiungi o rimuovi pacchetti all'interno di una categoria coerente, oppure crea un modulo e importalo soltanto sugli host interessati. Mantieni le scelte hardware, gli account e le impostazioni specifiche dell'host nei rispettivi moduli. Controlla dipendenze e requisiti di licenza quando modifichi la selezione.
