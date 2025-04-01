# Disk Partition Templates Overview

> **Lingue disponibili**: [English](DISK_PARTITION_TEMPLATES.md) | [Italiano (corrente)](DISK_PARTITION_TEMPLATES.it.md)

Questo documento offre una panoramica descrittiva dei sette template disponibili per il partizionamento del disco utilizzando il modulo **Disko** per NixOS. Ogni template fornisce un modo specifico e dichiarativo per configurare automaticamente partizioni, filesystem ed eventualmente cifratura LUKS.

## Templates Btrfs

### 1. `btrfs-only-root-subvolume.nix`
- Utilizza una tabella delle partizioni GPT.
- Partizione EFI (ESP) formattata con filesystem FAT32 e montata in `/boot`.
- Una singola partizione root che utilizza tutto lo spazio rimanente, formattata con filesystem Btrfs, compressione `zstd` e senza subvolumi aggiuntivi.

### 2. `btrfs-subvolumes.nix`
- Tabella GPT con partizione EFI (ESP) montata su `/boot`.
- Partizione root Btrfs con compressione `zstd` e organizzazione in subvolumi dedicati (es. root, home, nix-store).
- Include anche una partizione swap (2GB).

### 3. `btrfs-subvolumes-luks.nix`
- Tabella GPT con partizione EFI (ESP) da 512 MB montata su `/boot`.
- Partizione LUKS che cifra tutto lo spazio rimanente, contenente filesystem Btrfs organizzato in subvolumi.
- Include swap criptato (2GB).

### 4. `btrfs-subvolumes-luks-no_swap.nix`
- Simile al template precedente (`btrfs-subvolumes-luks.nix`) ma senza partizione swap.
- Crittografia LUKS dell'intera partizione root con filesystem Btrfs suddiviso in subvolumi.

## Templates Ext4

### 5. `single-disk-ext4.nix`
- Tabella GPT con partizione EFI (ESP) di 1GB, formattata in FAT32 montata su `/boot`.
- Singola partizione root che utilizza lo spazio restante, formattata con filesystem Ext4.

### 6. `single-disk-ext4-bios.nix`
- Utilizza GPT con partizione di boot BIOS di 1MB (compatibile con avvio GRUB in modalità BIOS).
- Unica partizione root che occupa tutto lo spazio restante con filesystem Ext4.

### 7. `single-disk-ext4-luks.nix`
- Tabella GPT con partizione EFI (ESP) da 500MB montata su `/boot`.
- Cifratura LUKS su una singola partizione che occupa il resto del disco, formattata con Ext4.

## Come utilizzare i template

- Identificare il disco con `lsblk` e aggiornare la variabile `${DISK_DEVICE}`.
- Scegliere il template desiderato, adattare eventuali dettagli (come la chiave LUKS o dimensioni partizioni) e procedere con Disko:

```bash
sudo nix --experimental-features "nix-command flakes" \
     run github:nix-community/disko/latest -- \
     --mode destroy,format,mount /percorso/al/file.nix
```

Dopodiché, procedere con l'installazione standard di NixOS:

```bash
nixos-generate-config --no-filesystems --root /mnt
nixos-install
```

Riavviare infine con `reboot` per completare l'installazione.