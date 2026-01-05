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
    │   └── btrfs-subvolumes-luks-no_swap.nix
    └── ext4/
        ├── single-disk-ext4.nix
        ├── single-disk-ext4-bios.nix
        └── single-disk-ext4-luks.nix
```

- **`btrfs`**: Template che utilizzano il filesystem Btrfs (opzionalmente con subvolumi e LUKS).  
- **`ext4`**: Template che utilizzano il filesystem ext4, con boot BIOS o EFI, eventualmente cifrato.

---

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
        run github:nix-community/disko/latest -- \
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
          "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
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

I template con “luks” nel nome includono **cifratura disco** tramite LUKS. Ad esempio:
```nix
type = "luks";
name = "crypted";
passwordFile = "/tmp/secret.key";
settings = {
  allowDiscards = true;
};
```
Puoi generare `/tmp/secret.key` con:
```bash
echo -n "tuapassword" > /tmp/secret.key
```
Per aprire manualmente la partizione cifrata, se necessario:
```bash
cryptsetup luksOpen /dev/nvme0n1p2 data
mount /dev/mapper/data /mnt
```
In questo modo il disco cifrato diventa disponibile in `/dev/mapper/data`.

---

## Fonti & Riferimenti

- **Disko**: [https://github.com/nix-community/disko](https://github.com/nix-community/disko)  
- **Disko Templates**: [https://github.com/nix-community/disko-templates](https://github.com/nix-community/disko-templates)  
- **Esempi Disko**: [https://github.com/nix-community/disko/tree/master/example](https://github.com/nix-community/disko/tree/master/example)  
- **Manuale NixOS** (Sezione Partizionamento): [https://nixos.org/manual/nixos/stable](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning)

Questi template sono stati adattati dagli esempi ufficiali di Disko.

Consulta queste risorse per ulteriori dettagli e suggerimenti aggiuntivi sulla configurazione Disko e sul partizionamento manuale in NixOS.