# Come usare i template

> **Lingue disponibili**: [English](HOWTO.md) | [Italiano (corrente)](HOWTO.it.md)

Usa i template per ricostruire un sistema NixOS già installato oppure per una nuova installazione con Disko. In entrambi i casi prepara prima l'host nello stesso modo.

## Preparazione manuale della configurazione

1. Leggi [`env.conf`](env.conf) e copia `nixos_configs_template/` in una directory che controlli, per esempio `/etc/nixos/nixos_configs/`. Mantieni la struttura interna.
2. Scegli `hosts/client/ABC/` per un client oppure `hosts/server/ABC/` per un server. Copia l'esempio nella stessa categoria e dai alla directory il nome dell'host.
3. Copia i file `.nix.template` selezionati nei corrispondenti file `.nix`. Prepara anche i template condivisi, tra cui `common/config/system.nix.template`, i moduli account e la base SSH del ruolo.
4. Sostituisci i segnaposto pubblici documentati con i valori dell'host. `env.conf` è un riferimento per tali valori; modificarlo da solo non aggiorna alcun file Nix.
5. Ottieni `hardware-configuration.nix` della macchina reale, scegli storage e avvio e prepara i segreti cifrati seguendo [SECRETS.it.md](nixos_configs_template/common/config/SECRETS.it.md).

La [guida host](nixos_configs_template/hosts/README.it.md), la [guida ai ruoli](nixos_configs_template/roles/README.it.md) e la [guida account](nixos_configs_template/users/README.it.md) spiegano la composizione. Un host in `hosts/client/<nome>/` o `hosts/server/<nome>/` usa `../../../common/`, `../../../roles/` e `../../../users/`; i moduli condivisi dei dischi e di Secure Boot usano `../../disk_configurations/` e `../../secure_boot/`.

### Parametri pubblici e sintassi Nix

`HOST_ROLE` è `client` o `server`. `DESKTOP` è `none`, `kde`, `gnome` o `hyprland`. Scegli applicazioni e demoni separatamente; `FEATURES` elenca nomi di moduli opzionali separati da virgole. La [guida ai pacchetti](nixos_configs_template/common/packages/README.it.md) e la [guida ai servizi](nixos_configs_template/common/services/README.it.md) descrivono i 14 gruppi applicativi/demoni. Le altre quattro selezioni sono `audio`, `audio_airplay`, `audio_chromecast` ([configurazione audio](nixos_configs_template/common/config/README.it.md)) e `bluetooth`, che corrisponde a `common/network/default_bluetooth.nix` ([rete](nixos_configs_template/common/network/README.it.md)). `ENABLE_RDP` controlla Xfce remoto indipendentemente dal desktop locale.

Sostituisci i segnaposto secondo la sintassi della posizione in cui compaiono:

| Tipo di segnaposto | Esempio risultante |
| --- | --- |
| Numeri, come `${SSH_PORT}` | `22`, senza virgolette. |
| Booleani, come `${ENABLE_WIFI}` | `true` o `false`, senza virgolette. |
| Testo già dentro una stringa Nix, come `"${HOSTNAME}"` | Contenuto della stringa con escape appropriati; conserva le virgolette esterne. |
| Token stringa completo `${WIFI_SSID_NIX}` | `"Example WiFi"`, virgolette incluse; usa `""` se disabilitato. |
| Token CIDR `${SSH_ALLOWED_IPV4_NIX}`, `${SSH_ALLOWED_IPV6_NIX}` e corrispondenti `RDP_` | Liste di reti tra virgolette divise per famiglia IP, per esempio `[ "192.0.2.0/24" ]`, oppure `[]`. |
| `${HOST_IMPORTS}` | Solo voci di import opzionali, oppure un blocco vuoto. |
| `${HOST_EXTRA_CONFIG}` | Solo dichiarazioni di avvio coerenti con disco e bootloader scelti. |

Conserva l'interpolazione Nix nativa, per esempio `${pkgs.libvirt}` e `${config.sops.placeholder.admin_ssh_publicKey}`. Non applicare una sostituzione globale delle variabili di shell all'intero albero. Esegui correttamente l'escape dei contenuti delle stringhe Nix, comprese virgolette, barre inverse e sequenze letterali di interpolazione.

`HOST_IMPORTS` può contenere desktop locale, RDP, gruppi di pacchetti, demoni, manutenzione dello storage e altri moduli opzionali. Gli import obbligatori di ruolo, utenti, rete, SOPS e Syncthing dell'host sono già nei template host. Per esempio, questo blocco opzionale sceglie KDE, strumenti fotografici e un demone Docker locale separato:

```nix
    ../../../common/gui/kde.nix
    ../../../common/packages/photo_editing.nix
    ../../../common/services/docker.nix
```

Per AirPlay o Chromecast senza desktop locale, includi anche `../../../common/config/audio.nix` negli import opzionali insieme al modulo di streaming scelto. I moduli desktop locali importano già la base audio. La selezione `bluetooth` resta indipendente dal desktop.

Per `BOOT_LOADER=systemd-boot`, un blocco `HOST_EXTRA_CONFIG` minimo è:

```nix
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
```

Per GRUB o Lanzaboote usa impostazioni coerenti con il layout di storage scelto e con la [guida Secure Boot](nixos_configs_template/hosts/secure_boot/README.it.md). Risolvi `DISK_LAYOUT` vuoto a `single-disk-ext4` per i client oppure `btrfs-worker-luks` per i server; entrambi i layout predefiniti usano UEFI. Per GRUB scegli esplicitamente una ricetta BIOS. Con un layout selezionato importa sia il modulo Disko fissato alla revisione prevista sia la ricetta preparata. `DISK_LAYOUT=none` esplicito richiede un vero `hardware-configuration.nix` con le dichiarazioni dei filesystem della destinazione; il template hardware generico non le fornisce. `DISK_DEVICE` è la parte successiva a `/dev/` nelle ricette contenenti `"/dev/${DISK_DEVICE}"`; quando opportuno usa un valore stabile `disk/by-id/...`.

Risolvi i valori derivati vuoti prima di preparare i file: `MAX_JOBS`/`BUILD_CORES` usano `4`/`0` sui client e `2`/`4` sui server; i valori zram predefiniti sono `30`/`lz4` per i client e `50`/`zstd` per i server; un percorso Syncthing vuoto si risolve in `/home/<admin>/Sync/work-data` su un client o `<WORK_ROOT>/data` su un server. Mantieni UID/GID espliciti e distinti. Imposta `NIXOS_VERSION` alla versione della prima installazione, non a quella verso cui stai aggiornando. I campi CPU/piattaforma devono corrispondere alla dichiarazione hardware reale.

### Servizi opzionali e segreti

Imposta SSID WiFi e CIDR consentiti soltanto per l’host di destinazione. Se `RDP_ALLOWED_CIDRS` è vuoto, usa i CIDR SSH come valori effettivi RDP prima di dividere le famiglie IP. Le PSK WiFi appartengono a `wifi_env` cifrato con la variabile `WIFI_PSK`; i dati delle chiavi SSH pubbliche e le credenziali seguono la [guida SOPS](nixos_configs_template/common/config/SECRETS.it.md). Non mettere password, hash, PSK o chiavi private in `env.conf`.

Un server non apre porte SSH o RDP finché non imposti i CIDR consentiti. Il client mantiene la policy SSH esistente salvo configurazione di una restrizione per subnet. RDP richiede inoltre un account non root con una password PAM utilizzabile; le sole chiavi SSH non forniscono una password RDP.

Syncthing si configura nel file `syncthing.nix` di ogni host. Con ID del dispositivo remoto vuoto non viene dichiarato alcun dispositivo remoto o cartella. Per abilitare la sincronizzazione fornisci ID reale del peer, ID condiviso della cartella, percorso e un endpoint TCP fisso raggiungibile. Discovery, relay, NAT traversal e aperture firewall automatiche sono disabilitati. Vedi la [guida host](nixos_configs_template/hosts/README.it.md).

## Ricostruzione di un sistema installato

Installa NixOS da una [ISO ufficiale](https://nixos.org/download/), conserva hardware rilevato e dichiarazioni esistenti di filesystem/avvio e prepara la configurazione sopra. Su un host installato non rieseguire la formattazione Disko.

Controlla la valutazione prima dell'attivazione, usando il percorso dell'host reale:

```bash
sudo nixos-rebuild dry-build -I nixos-config=/etc/nixos/nixos_configs/hosts/client/example/configuration.nix
sudo nixos-rebuild switch -I nixos-config=/etc/nixos/nixos_configs/hosts/client/example/configuration.nix
```

Per un server usa `hosts/server/example/configuration.nix`. Aggiungi `--show-trace` per analizzare un errore di valutazione. Mantieni una sessione di accesso esistente finché non hai verificato l'accesso remoto.

## Installazione diretta

Segui la [guida Disko](nixos_configs_template/hosts/disk_configurations/README.it.md) per la ricetta scelta. I comandi seguenti assumono un albero completo preparato in `/tmp/nixos_configs` e la ricetta scelta in `/tmp/disk-config.nix`.

**L'operazione destroy/format di Disko cancella il disco di destinazione selezionato. Controlla dispositivo e backup prima di eseguirla.**

1. Avvia l'installer NixOS ufficiale e copia i file preparati nel suo ambiente.
2. Applica la ricetta preparata:

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/v1.13.0 -- --mode destroy,format,mount /tmp/disk-config.nix
```

3. Copia l'albero di configurazione sul sistema montato e rileva l'hardware senza duplicare le dichiarazioni dei filesystem Disko:

```bash
sudo mkdir -p /mnt/etc/nixos
sudo cp -a /tmp/nixos_configs /mnt/etc/nixos/
sudo nixos-generate-config --no-filesystems --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos_configs/hosts/server/example/
```

4. Mantieni la ricetta disco preparata nell'albero e importala insieme al modulo Disko corrispondente fissato alla stessa revisione. Controlla la coerenza di EFI/BIOS e bootloader.
5. Prepara la chiave SSH dell'host e aggiungi il destinatario age prima della prima build, seguendo [SECRETS.it.md](nixos_configs_template/common/config/SECRETS.it.md). La chiave host deve poter accedere al file cifrato dell'host e ai valori cifrati condivisi.
6. Installa usando l'host selezionato:

```bash
sudo nixos-install -I nixos-config=/mnt/etc/nixos/nixos_configs/hosts/server/example/configuration.nix
```

7. Riavvia dopo l'installazione e verifica accesso utente, storage, rete ed eventuali servizi selezionati.

Mantieni la configurazione di proprietà di root e scrivibile solo dagli amministratori. La copia opzionale dei dotfile usa `BASEPATHUSER`; imposta esplicitamente la posizione sorgente nel modulo account client. Vedi [UPGRADE_SYSTEM.it.md](UPGRADE_SYSTEM.it.md) per gli aggiornamenti successivi.
