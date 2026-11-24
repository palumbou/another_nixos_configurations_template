# Disk Partition Templates Overview

> **Lingue disponibili**: [English](DISK_PARTITION_TEMPLATES.md) | [Italiano (corrente)](DISK_PARTITION_TEMPLATES.it.md)

Questo documento offre una panoramica descrittiva dei nove template disponibili per il partizionamento del disco utilizzando il modulo **Disko** per NixOS. Ogni template fornisce un modo specifico e dichiarativo per configurare automaticamente partizioni, filesystem ed eventualmente cifratura LUKS.

## Templates Btrfs

### 1. `btrfs-only-root-subvolume.nix`
- Utilizza una tabella delle partizioni GPT.
- Partizione EFI (ESP) formattata con filesystem FAT32 e montata in `/boot`.
- Una singola partizione root che utilizza tutto lo spazio rimanente, formattata con filesystem Btrfs, compressione `zstd` e senza subvolumi aggiuntivi.

### 2. `btrfs-subvolumes.nix`
- Tabella GPT con partizione EFI (ESP) montata su `/boot`.
- Partizione root Btrfs con compressione `zstd` e organizzazione in subvolumi dedicati (es. root, home, nix-store).
- Include swapfile di esempio (valori demo da 20 MB, da adattare).

### 3. `btrfs-subvolumes-luks.nix`
- Tabella GPT con partizione EFI (ESP) da 512 MB montata su `/boot`.
- Partizione LUKS che cifra tutto lo spazio rimanente, contenente filesystem Btrfs organizzato in subvolumi.
- Include uno swapfile di esempio cifrato (valore demo da 20 MB) in un subvolume dedicato.

### 4. `btrfs-subvolumes-luks-no_swap.nix`
- Simile al template precedente (`btrfs-subvolumes-luks.nix`) ma senza partizione swap.
- Crittografia LUKS dell'intera partizione root con filesystem Btrfs suddiviso in subvolumi.

### 5. `btrfs-worker-luks.nix`

- GPT con EFI da 1 GiB montata in `/boot`.
- Partizione swap `SWAP_SIZE`, predefinita `16G`, cifrata con chiave casuale a ogni avvio.
- LUKS2 con richiesta interattiva della passphrase per lo spazio rimanente.
- Subvolumi Btrfs root, home, Nix store e lavoro montati in `WORK_ROOT`, con compressione zstd e noatime.
- Nessuna ibernazione con la swap a chiave casuale; l’host server disabilita ibernazione e resume.

## Templates Ext4

### 6. `single-disk-ext4.nix`
- Tabella GPT con partizione EFI (ESP) di 1GB, formattata in FAT32 montata su `/boot`.
- Singola partizione root che utilizza lo spazio restante, formattata con filesystem Ext4.

### 7. `single-disk-ext4-bios.nix`
- Utilizza GPT con partizione di boot BIOS di 1MB (compatibile con avvio GRUB in modalità BIOS).
- Unica partizione root che occupa tutto lo spazio restante con filesystem Ext4.

### 8. `single-disk-ext4-luks.nix`
- Tabella GPT con partizione EFI (ESP) da 500MB montata su `/boot`.
- Cifratura LUKS su una singola partizione che occupa il resto del disco, formattata con Ext4.

### 9. `single-disk-ext4-bios-luks.nix`
- Tabella GPT con partizione di boot BIOS da 1MB (compatibile con avvio GRUB in modalità BIOS) e una partizione `/boot` ext4 separata non cifrata da 1GB.
- Cifratura LUKS sulla partizione root che occupa il resto del disco, formattata con Ext4.

## Come utilizzare i template

- Identificare il disco con `lsblk` e aggiornare la variabile `${DISK_DEVICE}`.
- Scegliere il template desiderato, adattare eventuali dettagli (come la chiave LUKS o dimensioni partizioni) e procedere con Disko:

```bash
sudo nix --experimental-features "nix-command flakes" \
     run github:nix-community/disko/v1.13.0 -- \
     --mode destroy,format,mount /percorso/al/file.nix
```

Dopodiché, procedere con l'installazione standard di NixOS:

```bash
nixos-generate-config --no-filesystems --root /mnt
nixos-install
```

Riavviare infine con `reboot` per completare l'installazione.