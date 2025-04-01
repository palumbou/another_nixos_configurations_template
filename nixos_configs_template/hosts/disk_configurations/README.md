# Disko Disk Configurations

> **Available languages**: [English (current)](README.md) | [Italiano](README.it.md)

This directory contains **disk partition and filesystem templates** designed for use with [Disko](https://github.com/nix-community/disko), a tool that lets you **declaratively** configure disk layouts for NixOS installations. With Disko, you can describe disks, partitions, filesystems (including Btrfs subvolumes, LUKS encryption, swap, and more) using a simple `.nix` file, enabling consistent and reproducible setups across multiple machines.

---

## Introduction

- **Declarative Configuration**: write `.nix` files specifying how disks and partitions should be set up.  
- **NixOS Integration**: use Disko directly within your NixOS configuration.  
- **Automation & Reproducibility**: quickly replicate the same disk structure on multiple machines.  
- **Broad Filesystem Support**: GPT, EFI partitions, LUKS encryption, Btrfs subvolumes, ext4, swap, etc.  
- **Complete Examples**: this repository includes adapted examples for typical setups (Btrfs or ext4, with or without LUKS encryption, etc.).  

For more details, see the official [Disko repository](https://github.com/nix-community/disko).

---

## Folder Structure

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

- **`btrfs`**: Templates using a Btrfs filesystem (with optional subvolumes and LUKS).  
- **`ext4`**: Templates using the ext4 filesystem, with BIOS or EFI boot, optionally encrypted.

### Sources & References

- **Disko Templates**: [https://github.com/nix-community/disko-templates](https://github.com/nix-community/disko-templates)  
- **Disko Example Files**: [https://github.com/nix-community/disko/tree/master/example](https://github.com/nix-community/disko/tree/master/example)

These templates have been adapted from the official Disko examples.

---

## Usage

For complete usage instructions, read the [Disko Quickstart Guide](https://github.com/nix-community/disko/blob/master/docs/quickstart.md). Below is a brief summary:

1. **Choose a Template**  
   - Pick one of the provided `.nix` files in `btrfs` or `ext4`, or write your own.

2. **Boot from NixOS Installer**  
   - Use the official [NixOS installer ISO](https://nixos.org/download.html#nixos-iso) on the target machine.

3. **Identify the Target Disk**  
   - Run `lsblk` to find the disk device name (e.g. `/dev/sda` or `/dev/nvme0n1`).

4. **Copy the Chosen Template**  
   - Copy your selected `.nix` file (e.g. `btrfs-subvolumes-luks.nix`) onto the installer environment.

5. **Edit the Template**  
   - Update the disk device name (`device` in the template) to match your target disk from step 3.

6. **Run Disko**  
   - **Warning**: this destroys existing data on the disk.  
   ```bash
   sudo nix --experimental-features "nix-command flakes" \
        run github:nix-community/disko/latest -- \
        --mode destroy,format,mount /tmp/disk-config.nix
   ```
   Replace `/tmp/disk-config.nix` with the path to your edited template.  
   - Verify the disk is mounted under `/mnt` by checking `mount | grep /mnt`.

7. **Complete the NixOS Installation**
   1. **Generate hardware config** without filesystem references:
      ```bash
      nixos-generate-config --no-filesystems --root /mnt
      ```
   2. **Move** your Disko `.nix` file to `/mnt/etc/nixos/`:
      ```bash
      mv /tmp/disk-config.nix /mnt/etc/nixos/
      ```
   3. **(Optional) Replace `configuration.nix`**  
      You can use your own `configuration.nix` file here if you wish. Just ensure you still do step **7-4** below (which imports the Disko module and your template).
   4. **Edit `/mnt/etc/nixos/configuration.nix`**  
      - Add both Disko and your `.nix` template to the `imports` array:
        ```nix
        imports = [
          ./hardware-configuration.nix
          "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
          ./disk-config.nix
        ];
        ```
      - Adjust the rest of `configuration.nix` as desired (e.g., user accounts, host configuration, etc.).
   5. **Check the bootloader section**  
      - Make sure it matches whichever scheme (EFI or GRUB) the template uses (see below for details).
   6. **Install & Reboot**  
      ```bash
      nixos-install
      reboot
      ```
      - **Important**: During installation, you’ll be prompted for the **root user** password.  
      - If you haven’t declared a password for your normal user (e.g. via `users.users.<name>.hashedPassword`), you must set it after the first boot when logged in as `root`.

---

## Bootloader

Depending on EFI or Legacy BIOS:

- **EFI Partition (“EF00”)**  
  - Typically mount at `/boot` and set `format = "vfat"`.  
  - Example from a template:
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
  - In `configuration.nix`, add:
    ```nix
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true; # Optional
    ```

- **GRUB Partition (“EF02”)**  
  - Small partition (e.g. 1MB) for GRUB’s core image.  
  - Example from a template:
    ```nix
    boot = {
      size = "1M";
      type = "EF02";
    };
    ```
  - In `configuration.nix`:
    ```nix
    boot.loader.grub.enable = true;
    boot.loader.grub.efiSupport = true; # optional
    boot.loader.grub.efiInstallAsRemovable = true; # optional
    ```

For more details, refer to the [NixOS installation manual](https://nixos.org/manual/nixos/stable/index.html#sec-installation-manual-partitioning), [GRUB](https://wiki.archlinux.org/title/GRUB) and [systemd-boot](https://wiki.archlinux.org/title/Systemd-boot).

---

## LUKS Encryption

Templates containing “luks” in their name indicate **disk encryption** with LUKS. For example:
```nix
type = "luks";
name = "crypted";
passwordFile = "/tmp/secret.key";
settings = {
  allowDiscards = true;
};
```
You can generate `/tmp/secret.key` via:
```bash
echo -n "yourpassword" > /tmp/secret.key
```
Use `cryptsetup` to open the partition manually if needed:
```bash
cryptsetup luksOpen /dev/nvme0n1p2 data
mount /dev/mapper/data /mnt
```
This makes the encrypted volume available at `/dev/mapper/data`.

---

## Sources

- **Disko**: [https://github.com/nix-community/disko](https://github.com/nix-community/disko)  
- **NixOS Manual** (Partitioning Section): [https://nixos.org/manual/nixos/stable](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning)

Refer to these resources for further details and additional configuration guidance. 
