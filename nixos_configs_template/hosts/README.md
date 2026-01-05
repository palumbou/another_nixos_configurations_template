# Hosts Folder

> **Available languages**: [English (current)](README.md) | [Italiano](README.it.md)

The **`hosts`** folder contains configurations for each of your machines (hosts). Each host resides in its own subfolder named after that host. This folder also includes:

- **`disk_configurations/`** - Disko templates for declarative disk partitioning and filesystem setup
- **`secure_boot/`** - Secure Boot configuration files using Lanzaboote for automatic signing
- Individual host folders (e.g., **`ABC/`**) containing host-specific configuration files

Each host folder typically includes:

- **`configuration.nix`** - Base configuration file with imports for GUI, packages, users, and optional features
- **`hardware-configuration.nix`** - Hardware-specific configuration generated during installation
- **`nm_configurations.nix`** (optional) - NetworkManager connection files to import during build

## Folder Structure

```bash
hosts/
├── ABC/                          # Example host folder
│   ├── configuration.nix
│   ├── hardware-configuration.nix
│   └── nm_configurations.nix
├── disk_configurations/          # Disko templates for disk setup
│   ├── btrfs/
│   └── ext4/
└── secure_boot/                  # Secure Boot with Lanzaboote
    ├── lon.nix
    └── secure_boot.nix
```

The **`ABC`** folder is a sample. Copy it, rename it to match your actual hostname, and then modify its files as needed.

---

## Optional: Secure Boot Configuration

The **`secure_boot`** folder provides configuration files to enable Secure Boot on your NixOS system using **Lanzaboote**, a community tool that automates the signing of boot files.

**What is Secure Boot?**  
Secure Boot is a UEFI firmware feature that ensures only cryptographically signed bootloaders and kernels can run, protecting against boot-level malware and unauthorized modifications.

**Why use Lanzaboote?**  
Lanzaboote integrates Secure Boot signing directly into the NixOS rebuild process, eliminating the need to manually sign boot files after each system update.

**How to enable:**  
1. Follow the detailed instructions in [`secure_boot/README.md`](secure_boot/README.md)
2. Uncomment the line `#../secure_boot/secure_boot.nix` in your host's `configuration.nix`
3. Complete the key generation and enrollment steps described in the README
4. Enable Secure Boot in your UEFI firmware after verification

---

## Optional: Disk Configuration with Disko

The **`disk_configurations`** folder contains templates for declarative disk partitioning using Disko. Refer to [`disk_configurations/README.md`](disk_configurations/README.md) for detailed information about available templates (Btrfs, ext4, LUKS encryption, etc.) and usage instructions.

---

## `configuration.nix` File

1. **Uncomment the imports** you need. For example, choose only one GUI (`gnome.nix`, `hyprland.nix` or `kde.nix`). Uncomment relevant packages/services from `../../common/packages/`. 

2. **Optional features**: Uncomment `../secure_boot/secure_boot.nix` for Secure Boot support, or `../disk_configurations/...` if using Disko for disk management.

3. **User configuration**: Point to the correct user config, e.g., `../../users/XYZ/user.nix`.

4. **Set the bootloader device** by replacing `/dev/disk/by-id/wwn-0x500001234567890a` with your actual disk identifier:
    
        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/disk/by-id/wwn-0x500001234567890a";
        boot.loader.grub.useOSProber = false;

   You can find this by:
   - Installing NixOS and copying from `/etc/nixos/configuration.nix`, or  
   - Running `nixos-generate-config` on your machine.

5. **Set the hostname**:
    
        networking.hostName = "nixos"; # Replace with your own hostname

6. **Enable selected Syncthing folders** specified for the host (optional).

    If you use Syncthing to sync folders between your computers, you can use this option to enable the synchronization of specific folders during the system build.

    Replace "NAME FOLDER" with the name of the folder you want to sync.

        services.syncthing.settings.folders.NAME FOLDER.enable = true;

  - **Use one option per folder:** add more lines for all folders you want to enable.
  - **Note:** the corresponding folder configurations must be specified in the Syncthing configuration file (`../../common/packages/syncthing.nix`).

---

## `hardware-configuration.nix` File

This file holds hardware-specific settings for the host.  
You can acquire it by:

- Installing NixOS from an [official ISO](https://nixos.org/download) and copying `/etc/nixos/hardware-configuration.nix`.
- Running `nixos-generate-config` on the target host.
- Importing it from [nixos-hardware](https://github.com/NixOS/nixos-hardware), if a matching profile exists.

---

## `nm_configurations.nix` File (Optional)

If you need to import `.nmconnection` files at build time (e.g., WiFi or VPN settings):

1. Place those files in `nixos_configs/common/network/nmconnection_files/`.
2. Uncomment the line `./nm_configurations.nix` in your `configuration.nix`.
3. In `nm_configurations.nix`, reference the files with the correct absolute path. For example:

        {
          environment.etc."NetworkManager/system-connections/HomeWiFi.nmconnection" = {
            source = "${BASEPATHNM}/nixos_configs/common/network/nmconnection_files/HomeWiFi.nmconnection";
            mode = "0600";
            user = "root";
            group = "root";
          };
        }

Replace `${BASEPATHNM}` with your actual path to `nixos_configs` and `HomeWiFi.nmconnection` with your file name.
If a file is declared but not found, you'll see a warning during the build, but it will not fail.

> **Note:** you can also manage WiFi through [`networking.wireless.networks`](https://search.nixos.org/options?channel=25.11&from=0&size=50&sort=relevance&type=packages&query=networking.wireless.networks.), but that approach enables `wpa_supplicant` and disables WiFi control in NetworkManager.

---

## Summary

1. **Copy the `ABC` folder**, rename it to your host's name.  
2. **Edit** `configuration.nix`, `hardware-configuration.nix`, and optionally `nm_configurations.nix`.  
3. **Uncomment** what you need and set correct identifiers (bootloader device, hostname, etc.).

With this in place, `hosts/ABC` should be ready for NixOS builds.
