# Disk Partition Templates Overview

> **Available languages**: [English (current)](DISK_PARTITION_TEMPLATES.md) | [Italiano](DISK_PARTITION_TEMPLATES.it.md)

This document provides an overview of the seven available disk partitioning templates using the **Disko** module for NixOS. Each template provides a specific and declarative way to automatically configure partitions, filesystems, and optionally LUKS encryption.

## Btrfs Templates

### 1. `btrfs-only-root-subvolume.nix`
- GPT partition table.
- EFI partition (ESP) formatted with FAT32 filesystem mounted at `/boot`.
- Single root partition using all remaining space, formatted with Btrfs filesystem, `zstd` compression, and no additional subvolumes.

### 2. `btrfs-subvolumes.nix`
- GPT partition table with EFI partition (ESP) mounted at `/boot`.
- Root partition formatted as Btrfs with `zstd` compression and organized into dedicated subvolumes (e.g., root, home, nix-store).
- Includes a swap partition (2GB).

### 3. `btrfs-subvolumes-luks.nix`
- GPT partition table with 512MB EFI partition (ESP) mounted at `/boot`.
- LUKS-encrypted partition covering all remaining space, containing a Btrfs filesystem structured into subvolumes.
- Includes encrypted swap partition (2GB).

### 4. `btrfs-subvolumes-luks-no_swap.nix`
- Similar to the previous template (`btrfs-subvolumes-luks.nix`) but without a swap partition.
- LUKS encryption of the entire root partition with Btrfs filesystem divided into subvolumes.

## Ext4 Templates

### 5. `single-disk-ext4.nix`
- GPT partition table with 1GB EFI partition (ESP), formatted with FAT32 and mounted at `/boot`.
- Single root partition using the remaining space, formatted with Ext4 filesystem.

### 6. `single-disk-ext4-bios.nix`
- GPT partition table with a 1MB BIOS boot partition (compatible with GRUB booting in BIOS mode).
- Single root partition occupying all remaining disk space with Ext4 filesystem.

### 7. `single-disk-ext4-luks.nix`
- GPT partition table with a 500MB EFI partition (ESP) mounted at `/boot`.
- LUKS encryption on a single partition occupying the rest of the disk, formatted with Ext4 filesystem.

## How to use templates

- Identify your disk with `lsblk` and update the variable `${DISK_DEVICE}`.
- Choose your desired template, adapt any details (such as LUKS keys or partition sizes), and proceed with Disko:

```bash
sudo nix --experimental-features "nix-command flakes" \
     run github:nix-community/disko/latest -- \
     --mode destroy,format,mount /path/to/template.nix
```

Then proceed with the standard NixOS installation:

```bash
nixos-generate-config --no-filesystems --root /mnt
nixos-install
```

Finally, reboot your system with `reboot` to complete the installation.