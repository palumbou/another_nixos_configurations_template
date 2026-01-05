# Secure Boot with NixOS

> **Available languages**: [English (current)](README.md) | [Italiano](README.it.md)

This guide explains how to enable **Secure Boot** on NixOS using two approaches:

1. **Manual method** with `sbctl` (requires manual signing)
2. **Automated method** with **Lanzaboote** (automatic signing)

---

## Introduction

**Secure Boot** is a UEFI firmware security feature that protects your system by ensuring only cryptographically signed bootloaders, kernels, and drivers can run during the boot process. This prevents malware and unauthorized modifications from executing at the boot level, providing a critical layer of security for your system.

**How it works:**  
Secure Boot uses digital signatures to verify the authenticity of boot components. When enabled, the UEFI firmware checks each component against trusted keys stored in its database before allowing it to execute. Only properly signed components with valid signatures can boot the system.

**Why use Secure Boot on NixOS?**  
- **Enhanced security**: protection against boot-level malware and rootkits
- **Integrity verification**: ensures no unauthorized modifications to boot files
- **Compliance**: required for certain enterprise and security-sensitive environments
- **Full disk encryption benefits**: when combined with TPM, provides stronger protection

**Two implementation methods:**
1. **Manual with sbctl**: gives you direct control but requires signing after each system update
2. **Automated with Lanzaboote**: integrates signing into the NixOS rebuild process for seamless operation

---

## Folder Structure

```bash
hosts/
└── secure_boot/
    ├── lon.nix               # Lanzaboote source definition
    └── secure_boot.nix       # Complete Lanzaboote configuration file
```

**File descriptions:**

- **`lon.nix`** - Defines the Lanzaboote source location using `builtins.fetchTarball` to download from GitHub. This file is imported by `secure_boot.nix` to provide the Lanzaboote module.

- **`secure_boot.nix`** - Ready-to-import configuration file that:
  - Imports the Lanzaboote module from `lon.nix`
  - Disables the standard systemd-boot module (using `lib.mkForce false`)
  - Enables Lanzaboote with automatic boot file signing
  - Includes the `sbctl` package for key management
  - Configures the PKI path (`/var/lib/sbctl`)

---

## Prerequisites

Before proceeding, ensure:

1. **UEFI firmware** (not legacy BIOS)
2. **Secure Boot initially disabled** in firmware settings
3. **systemd-boot** as bootloader (required by both methods)

To verify systemd-boot is active:

```bash
bootctl status
```

This command also shows your current Secure Boot status and other important information:
- Current bootloader and firmware type (must be UEFI)
- Whether Secure Boot is **enabled** or **disabled**
- Boot entries and available kernels

**What to verify in the output:**
- `Firmware: UEFI` (not legacy BIOS)
- `Secure Boot: disabled` (must be disabled initially)
- `systemd-boot` listed as the boot loader

If Secure Boot is already enabled, disable it in your UEFI firmware settings before proceeding.

---

## Overview

Both approaches follow this workflow:

1. **Phase A** - Prepare the system (systemd-boot + sbctl)
2. **Phase B** - Generate and enroll Secure Boot keys
3. **Phase C** - Enable signing (manual with sbctl **or** automated with Lanzaboote)
4. **Phase D** - Verify all boot files are signed
5. **Phase E** - Enable Secure Boot in firmware

**Key difference**:
- **Manual method**: you must sign kernels after every update with `sbctl sign-all`
- **Lanzaboote method**: automatic signing during `nixos-rebuild`

> **Note about Lanzaboote**: Lanzaboote replaces the standard systemd-boot NixOS module with a modified version that includes automatic signing. systemd-boot remains the actual bootloader, but is managed differently to integrate Secure Boot signing into the build process.

---

## Method 1: Manual with sbctl

### Phase A — System Preparation

#### 1. Enable systemd-boot

In your `configuration.nix`:

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

Rebuild:

```bash
sudo nixos-rebuild switch
```

#### 2. Install sbctl

Add to your `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [ sbctl ];
```

Rebuild again:

```bash
sudo nixos-rebuild switch
```

---

### Phase B — Generate and Enroll Keys

#### 1. Create Secure Boot keys

```bash
sudo sbctl create-keys
```

Keys are stored in `/var/lib/sbctl/`.

#### 2. Enroll keys in firmware

```bash
sudo sbctl enroll-keys --microsoft
```

> **About the `--microsoft` flag**: This includes Microsoft certificates in the key database. This is **required** if you dual-boot with Windows or need to boot hardware with drivers signed by Microsoft (e.g., some network cards, graphics cards). If you only boot NixOS and don't have such hardware, you can omit this flag, though including it is generally safer for compatibility.

> **Warning**: Secure Boot remains **disabled** in firmware at this stage. Do not enable it yet.

---

### Phase C — Manual Signing

#### 1. Sign all boot files

```bash
sudo sbctl sign-all
```

This signs:
- `systemd-bootx64.efi`
- `BOOTX64.EFI`
- All `nixos-generation-*.efi` files

#### 2. After every system update

**Important**: You must manually run this command after each rebuild:

```bash
sudo sbctl sign-all
```

Forgetting this step will prevent boot after enabling Secure Boot.

---

### Phase D — Verification (mandatory)

```bash
sbctl verify
```

All boot files must show as **signed**. Example output:

```
✓ /boot/EFI/systemd/systemd-bootx64.efi is signed
✓ /boot/EFI/BOOT/BOOTX64.EFI is signed
✓ /boot/EFI/nixos/nixos-generation-1.efi is signed
```

---

### Phase E — Enable Secure Boot

Only after successful verification:

1. Reboot the system
2. Enter BIOS/UEFI setup (typically DEL, F2, or F12 during boot)
3. Enable **Secure Boot**
4. Set mode to **Custom** or **Setup Mode** (if available)
5. Save and exit

If the system doesn't boot, disable Secure Boot in firmware and verify all files are signed.

---

## Method 2: Automated with Lanzaboote

**Lanzaboote** is a community tool that integrates Secure Boot signing into NixOS rebuilds, eliminating manual intervention. It replaces the standard NixOS systemd-boot module with a version that automatically signs all boot files during system builds.

### Phase A — System Preparation

Same as Method 1 (systemd-boot + sbctl).

---

### Phase B — Generate and Enroll Keys

#### With nix-shell (if sbctl not yet installed)

```bash
sudo nix-shell -p sbctl --run "sbctl create-keys"
sudo nix-shell -p sbctl --run "sbctl enroll-keys --microsoft"
```

#### With installed sbctl

```bash
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
```

> **About the `--microsoft` flag**: Include it if you dual-boot with Windows or have hardware requiring Microsoft-signed drivers. See Phase B in Method 1 for details.

> **Warning**: Secure Boot remains **disabled** in firmware.

---

### Phase C — Enable Lanzaboote

#### 1. Import `secure-boot.nix` in your host configuration

In your `configuration.nix` (e.g., `hosts/ABC/configuration.nix`), add:

```nix
imports = [
  ./hardware-configuration.nix
  ../secure_boot/secure_boot.nix
];
```

The `secure_boot.nix` file provided in this directory contains:
- Lanzaboote configuration with PKI bundle path
- Forced disabling of the standard systemd-boot module
- sbctl package for key management

#### 2. Rebuild

```bash
sudo nixos-rebuild switch
```

Lanzaboote will automatically sign all boot files during the rebuild.

---

### Phase D — Verification (mandatory)

```bash
sbctl verify
```

Must show all files signed:

- `systemd-bootx64.efi`
- `BOOTX64.EFI`
- `nixos-generation-*.efi`

---

### Phase E — Enable Secure Boot

Same procedure as Method 1:

1. Reboot
2. Enter BIOS/UEFI setup
3. Enable **Secure Boot**
4. Set mode to **Custom / Setup Mode**
5. Save and exit

With Lanzaboote, **no manual signing is required** after future updates.

---

## Comparison

| Aspect              | Manual (sbctl) | Lanzaboote |
| ------------------- | -------------- | ---------- |
| systemd-boot        | ✔              | ✔ (modified module) |
| Automatic signing   | ✖              | ✔          |
| Risk of forgetting  | High           | Minimal    |
| Initial complexity  | Low            | Medium     |
| Maintenance         | Manual         | Automatic  |

---

## Official Resources

- **NixOS Manual – Bootloader & Secure Boot**  
  [https://nixos.org/manual/nixos/stable/#sec-boot](https://nixos.org/manual/nixos/stable/#sec-boot)

- **sbctl (Foxboron)**  
  [https://github.com/Foxboron/sbctl](https://github.com/Foxboron/sbctl)

- **Lanzaboote – Getting Started**  
  [https://github.com/nix-community/lanzaboote/blob/master/docs/getting-started/prepare-your-system.md](https://github.com/nix-community/lanzaboote/blob/master/docs/getting-started/prepare-your-system.md)

- **systemd-boot Documentation**  
  [https://www.freedesktop.org/software/systemd/man/systemd-boot.html](https://www.freedesktop.org/software/systemd/man/systemd-boot.html)

---

## Important Notes

Regardless of the chosen method:

- **Never enable Secure Boot before verification** - always run `sbctl verify` first
- **Keep a recovery method available** - BIOS access + NixOS live USB
- **Test thoroughly** before deploying on production systems

This is not a NixOS limitation, but an inherent property of Secure Boot.

---

