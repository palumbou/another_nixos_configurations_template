# Configurazioni Disco per Disko

> **Lingue disponibili**: [English](README.md) | [Italiano (corrente)](README.it.md)

Questa cartella contiene **template per partizionamento e filesystem** pensati per l’utilizzo con [Disko](https://github.com/nix-community/disko), uno strumento che consente di **configurare in modo dichiarativo** la struttura dei dischi in installazioni NixOS. Con Disko, puoi descrivere dischi, partizioni e filesystem (inclusi subvolume Btrfs, cifratura LUKS, swap e altro) in semplici file `.nix`, garantendo configurazioni coerenti e ripetibili su più macchine.

---

## Introduzione

- **Configurazione Dichiarativa**: scrivi file `.nix` che specificano come dischi e partizioni devono essere impostati.  
- **Integrazione con NixOS**: utilizza Disko direttamente all’interno della configurazione di NixOS.  
- **Automazione & Riproducibilità**: replica facilmente la stessa struttura del disco su più macchine.  
- **Ampio Supporto Filesystem**: GPT, partizioni EFI, cifratura LUKS, subvolumi Btrfs, ext4, swap, ecc.  
- **Esempi Completi**: questo repository include esempi adattati per setup tipici (Btrfs o ext4, con o senza LUKS, ecc.).

Per maggiori dettagli, consulta il [repository ufficiale di Disko](https://github.com/nix-community/disko).

---

## Struttura della Cartella

```bash
hosts/
└── disk_configurations/
    ├── btrfs/
    │   ├── btrfs-only-root-subvolume.nix
    │   ├── btrfs-subvolumes.nix
    │   ├── btrfs-subvolumes-luks.nix
    │   ├── btrfs-subvolumes-luks-no_swap.nix
    │   └── btrfs-worker-luks.nix
    └── ext4/
        ├── single-disk-ext4.nix
        ├── single-disk-ext4-bios.nix
        ├── single-disk-ext4-bios-luks.nix
        └── single-disk-ext4-luks.nix
```

- **`btrfs`**: Template che utilizzano il filesystem Btrfs (opzionalmente con subvolumi e LUKS).  
- **`ext4`**: Template che utilizzano il filesystem ext4, con boot BIOS o EFI, eventualmente cifrato.

> **Nota**: i file in questa cartella sono ricette Disko usate **in fase di installazione**. Se ne copia una sull'installer, si modifica il nome del device e poi si tiene la copia modificata dentro `hosts/client/<nome>/` o `hosts/server/<nome>/`. Importa la ricetta preparata insieme al modulo Disko.
>
> Le controparti **a runtime** vivono in `common/config/` e si importano come qualsiasi altro modulo: [`btrfs_scrub.nix`](../../common/config/btrfs_scrub.nix) per il controllo periodico di integrità e [`btrfs_snapshots.nix`](../../common/config/btrfs_snapshots.nix) per gli snapshot timeline di snapper. Seleziona scrub solo per host Btrfs; il modulo snapshot configura root/home separatamente quando i rispettivi mount sono Btrfs. La GUI Btrfs Assistant è un modulo di pacchetti opzionale separato. Vedi [common/config/README.it.md](../../common/config/README.it.md).

---


## Selezione del layout pubblico

`DISK_LAYOUT` vuoto indica `single-disk-ext4` per un client oppure `btrfs-worker-luks` per un server. Durante la preparazione manuale risolvi questo valore e importa la ricetta corrispondente insieme a `common/config/disko.nix`. Entrambi i valori predefiniti sono UEFI; GRUB richiede la selezione esplicita di una ricetta BIOS. `none` esplicito richiede una dichiarazione hardware reale comprensiva dei filesystem della destinazione; il template hardware generico non basta. Scegliere una ricetta non esegue partizionamento o formattazione.

## Layout server Btrfs/LUKS

[`btrfs/btrfs-worker-luks.nix`](btrfs/btrfs-worker-luks.nix) è una ricetta separata per i server:

- Partizione EFI da 1 GiB montata in `/boot`.
- Partizione swap di dimensione `SWAP_SIZE` (predefinita `16G`) con nuova chiave di cifratura casuale a ogni avvio.
- Spazio rimanente protetto da LUKS2 con passphrase interattiva; nessun file chiave specifico di un host è incorporato.
- Subvolumi Btrfs montati in `/`, `/home`, `/nix` e `WORK_ROOT`, con `compress=zstd` e `noatime`.

La swap con chiave casuale non consente di riprendere un'immagine di ibernazione del boot precedente; l'host server disabilita ibernazione e resume. Permessi della directory di lavoro e policy snapshot opzionale sono dichiarati nel modulo account worker e nella configurazione host server, non nella ricetta disco.

Sostituisci `${DISK_DEVICE}`, `${SWAP_SIZE}` e `${WORK_ROOT}` con i valori pubblici scelti. Le ricette con `device = "/dev/${DISK_DEVICE}"` richiedono la parte successiva a `/dev/`, per esempio `disk/by-id/REPLACE_WITH_TARGET_DISK`. Verifica il disco reale con `lsblk`. Un host in `hosts/server/<nome>/` può importare la ricetta preparata da `../../disk_configurations/btrfs/btrfs-worker-luks.nix`, oppure copiarla localmente e importarla come `./disk-config.nix`. Importa anche il modulo Disko fissato alla revisione prevista.

## Utilizzo

Per istruzioni complete, leggi la [Disko Quickstart Guide](https://github.com/nix-community/disko/blob/master/docs/quickstart.md). Di seguito un riassunto:

1. **Scegli un Template**  
   - Seleziona uno dei file `.nix` disponibili in `btrfs` o `ext4`, oppure creane uno tuo.

2. **Avvia l’Installer di NixOS**  
   - Usa l’[ISO ufficiale di NixOS](https://nixos.org/download.html#nixos-iso) sulla macchina di destinazione.

3. **Identifica il Disco di Destinazione**  
   - Esegui `lsblk` per trovare il nome del dispositivo del disco (es. `/dev/sda` o `/dev/nvme0n1`).

4. **Copia il Template Scelto**  
   - Copia il file `.nix` (es. `btrfs-subvolumes-luks.nix`) nell’ambiente dell’installer.

5. **Modifica il Template**  
   - Aggiorna il nome del disco (`device` nel template) con quello trovato al passaggio 3.

6. **Esegui Disko**  
   - **Attenzione**: l’operazione rimuove tutti i dati esistenti dal disco.  
   ```bash
   sudo nix --experimental-features "nix-command flakes" \
        run github:nix-community/disko/v1.13.0 -- \
        --mode destroy,format,mount /tmp/disk-config.nix
   ```
   Sostituisci `/tmp/disk-config.nix` con il percorso al tuo template modificato.  
   - Verifica che il disco sia montato in `/mnt` con `mount | grep /mnt`.

7. **Completa l’Installazione di NixOS**
   1. **Genera la configurazione hardware** senza riferimenti al filesystem:
      ```bash
      nixos-generate-config --no-filesystems --root /mnt
      ```
   2. **Sposta** il file `.nix` di Disko in `/mnt/etc/nixos/`:
      ```bash
      mv /tmp/disk-config.nix /mnt/etc/nixos/
      ```
   3. **(Opzionale) Sostituisci `configuration.nix`**  
      Se preferisci, puoi usare il tuo `configuration.nix`. Assicurati solo di seguire comunque il passaggio **7.4** di seguito (che importa il modulo Disko e il tuo template).
   4. **Modifica `/mnt/etc/nixos/configuration.nix`**  
      - Aggiungi sia Disko che il tuo template `.nix` alla lista `imports`:
        ```nix
        imports = [
          ./hardware-configuration.nix
          "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/refs/tags/v1.13.0.tar.gz"}/module.nix"
          ./disk-config.nix
        ];
        ```
      - Modifica il resto di `configuration.nix` (ad es. utenti, host, ecc.) a tuo piacimento.
   5. **Controlla la sezione del bootloader**  
      - Assicurati che corrisponda allo schema usato nel template (EFI o GRUB). Dettagli qui sotto.
   6. **Installa & Riavvia**  
      ```bash
      nixos-install
      reboot
      ```
      - **Importante**: Durante l’installazione, ti verrà chiesta la password dell’**utente root**.  
      - Se non hai dichiarato una password per l’utente normale (ad es. con `users.users.<nome>.hashedPassword`), dovrai impostarla dopo il primo avvio, effettuando login come `root`.

---

## Bootloader

In base a EFI o Legacy BIOS:

- **Partizione EFI (“EF00”)**  
  - In genere si monta su `/boot` con `format = "vfat"`.  
  - Esempio dal template:
    ```nix
    ESP = {
      size = "512M";
      type = "EF00";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [ "umask=0077" ];
      };
    };
    ```
  - In `configuration.nix`, imposta:
    ```nix
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true; # Opzionale
    ```

- **Partizione GRUB (“EF02”)**  
  - Una partizione piccola (es. 1MB) per l’immagine core di GRUB.  
  - Esempio dal template:
    ```nix
    boot = {
      size = "1M";
      type = "EF02";
    };
    ```
  - In `configuration.nix`:
    ```nix
    boot.loader.grub.enable = true;
    boot.loader.grub.efiSupport = true; # opzionale
    boot.loader.grub.efiInstallAsRemovable = true; # opzionale
    ```

Per dettagli aggiuntivi, consultare [manuale di installazione NixOS](https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual-partitioning), [GRUB](https://wiki.archlinux.org/title/GRUB) e [systemd-boot](https://wiki.archlinux.org/title/Systemd-boot).

---

## Cifratura LUKS

Tutti e cinque i layout LUKS di questa cartella usano **`askPassword = true;` come impostazione predefinita**. Disko chiede la passphrase interattivamente per le proprie operazioni di creazione/apertura del volume durante l’installazione. Agli avvii successivi digita la stessa passphrase, salvo aver configurato esplicitamente lo sblocco tramite chiavetta USB o TPM2.

```nix
type = "luks";
name = "crypted";
askPassword = true;
settings = {
  allowDiscards = true;
};
```

Il caso predefinito non richiede `/tmp/secret.key` o altri file della passphrase principale.

`passwordFile` è un'alternativa opzionale per fornire da un file la passphrase durante le operazioni Disko di creazione/apertura. Per usarla, sostituisci l'impostazione interattiva con:

```nix
askPassword = false;
passwordFile = "/tmp/secret.key";
```

Prepara quel file soltanto per questa alternativa. Rimuovi o disabilita `askPassword` quando scegli `passwordFile`. Se rimane configurato `askPassword = true;`, questo prevale e il file viene ignorato. Disko non cancella automaticamente il file della passphrase. `passwordFile` da solo non configura lo sblocco automatico al boot.

Per aprire manualmente la partizione cifrata, se necessario:

```bash
cryptsetup luksOpen /dev/disk/by-id/REPLACE_WITH_LUKS_PARTITION data
mount /dev/mapper/data /mnt
```

Il volume cifrato diventa disponibile in `/dev/mapper/data`.

Per la variante opzionale con file, i keyslot multipli, le chiavette USB e lo sblocco TPM2, vedi [LUKS_KEYS.it.md](LUKS_KEYS.it.md). La guida distingue l’inserimento della passphrase per le operazioni Disko dalle opzioni di boot come `keyFile` e `keyFileTimeout`.

---

## Fonti & Riferimenti

- **Disko**: [https://github.com/nix-community/disko](https://github.com/nix-community/disko)  
- **Disko Templates**: [https://github.com/nix-community/disko-templates](https://github.com/nix-community/disko-templates)  
- **Esempi Disko**: [https://github.com/nix-community/disko/tree/master/example](https://github.com/nix-community/disko/tree/master/example)  
- **Manuale NixOS** (Sezione Partizionamento): [https://nixos.org/manual/nixos/stable](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning)

Questi template sono stati adattati dagli esempi ufficiali di Disko.

Consulta queste risorse per ulteriori dettagli e suggerimenti aggiuntivi sulla configurazione Disko e sul partizionamento manuale in NixOS.