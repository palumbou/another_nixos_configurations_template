# Another NixOS Configurations Template

> **Available languages**: [English (current)](README.md) | [Italiano](README.it.md)

A template-based approach to setting up and replicating NixOS configurations quickly and consistently.

## Introduction

Returning to Linux as my daily operating system, I wanted a stable, secure, and easily replicable setup-one that would get me from a blank hard drive to a fully configured workstation, complete with my personal settings, in the shortest time possible.

I also wanted an operating system that would facilitate company-wide client management, allowing for exact environment replication (except for user-specific data). For me, the answer was **NixOS**.

Initially, in early 2023, I started exploring NixOS but set it aside due to lack of time, switching to Fedora KDE (which I loved and could configure in under an hour from scratch). By the end of 2024, eager to invest time in developing dotfiles for a completely customized and replicable graphical environment, I decided to go one step further. Instead of just revisiting my desktop environment, I wanted to rebuild my entire OS configuration, so I returned to NixOS.

I spent countless hours reading the official manual, watching YouTube videos, and studying other users’ configuration files on GitHub (all sources are listed in the [Sources](#sources--references) section). Then I chose to write all configuration files from scratch, structuring folders and files to meet my needs while keeping the principle of **“Keep It Simple”** and **“Less Is More”** in mind.

**Why share these files?**  
I decided to turn my configs into a readable, heavily commented template that anyone could copy and modify as needed.

---

## Branch Information

This repository maintains different branches for different NixOS versions:

- **`master`** - Contains configurations for **NixOS 26.05**
- **`26.05`** - Contains configurations for **NixOS 26.05** (aligned with master)
- **`25.11`** - Contains configurations for **NixOS 25.11**
- **`25.05`** - Contains configurations for **NixOS 25.05**
- **`24.11`** - Contains configurations for **NixOS 24.11**

Choose the appropriate branch based on your NixOS version. The master branch is always aligned with the latest supported NixOS version.

---

## Explanation of Choices

In 2023, I made the mistake of jumping straight into **Flakes** and **Home Manager**, thinking I needed to include everything from the get-go. This complexity led me to abandon the project. In 2024, I nearly repeated the same mistake until I read [this update](https://github.com/Misterio77/nix-starter-configs/issues/86) from [Misterio77’s nix-starter-configs](https://github.com/Misterio77/nix-starter-configs). It was one of many insights suggesting that Flakes and Home Manager might be introduced later if really necessary, rather than right away.

---

## Folder and File Structure

The reusable configuration tree is under `nixos_configs_template/`. Copy it to a location of your choice and prepare the selected templates manually; the resulting tree can be called `nixos_configs/`. Keep the relative directory structure intact.

```text
nixos_configs_template/
├── common/
│   ├── config/                   # System settings, power, snapshots and SOPS
│   ├── gui/                      # Local desktops and optional Xfce RDP
│   ├── network/                  # Client and server networking
│   ├── packages/                 # Independent application groups
│   └── services/                 # Docker, libvirt and server SSH
├── roles/                        # base.nix, client.nix, server.nix
├── hosts/
│   ├── client/ABC/               # Client host example
│   ├── server/ABC/               # Server host example
│   ├── disk_configurations/      # Shared Disko layouts
│   └── secure_boot/              # Lanzaboote configuration
├── users/
│   ├── ADMIN/                    # admin.nix and optional client.nix
│   └── WORKER/                   # worker.nix
├── secrets/                      # Encrypted data prepared separately
└── .sops.yaml                    # Recipient rules prepared separately
```

### Preparing a host

Read [`env.conf`](env.conf) for the public parameter names and example values. Copy either `hosts/client/ABC` or `hosts/server/ABC` to a host directory within the same category. Prepare selected `.nix.template` files as `.nix` files and replace only their documented placeholders with values for that host. No substitution occurs merely by editing `env.conf`. The [HOWTO](HOWTO.md) explains typed values, optional import lists and installation.

A host at `hosts/client/<name>/` or `hosts/server/<name>/` imports common modules, roles and users through `../../../`. Shared Disko layouts and Secure Boot modules are reached through `../../disk_configurations/` and `../../secure_boot/`. Obtain a hardware declaration for the actual target with `nixos-generate-config` or an appropriate [nixos-hardware](https://github.com/NixOS/nixos-hardware) module; the public CPU and platform fields are examples, not a substitute for hardware detection.

### `common`

The [common guide](nixos_configs_template/common/README.md) links the five module categories. Local desktop selection (`none`, KDE, GNOME or Hyprland), optional Xfce RDP, application groups and local daemons are independent choices. A host without a desktop can still enable Docker, libvirt, Syncthing, snapshots and CLI tools.

Importing [`battery_management.nix`](nixos_configs_template/common/config/battery_management.nix) also installs `energy-profile` through [`energy_profiles.nix`](nixos_configs_template/common/config/energy_profiles.nix), requiring TLP 1.9 or newer. Automatic operation selects Performance on AC and Balanced on battery. Use `energy-profile performance`, `energy-profile balanced` or `energy-profile saver` temporarily; `energy-profile auto` restores automatic operation and `energy-profile status` returns JSON. Reboot restores automatic operation through TLP's native state. Active local users in `wheel` can change profiles through its dedicated Polkit action.

Balanced allows turbo and uses `balance_performance`; manually selected Saver uses `balance_power` with turbo disabled. Governor defaults target active `intel_pstate`/`amd-pstate` drivers. Override `services.tlp.settings` for other drivers or firmware profile names and inspect `tlp-stat -p` for supported values. Firmware defaults are `performance` on AC and `balanced` for both battery profiles.

Btrfs snapshots use the separate filesystem-aware core module. The optional `btrfs_assistant.nix` module installs the GUI package separately. The selected desktop provides Polkit; graphical privilege prompts also need its running authentication agent. See the [configuration guide](nixos_configs_template/common/config/README.md) and [package guide](nixos_configs_template/common/packages/README.md).

### `roles` and `hosts`

[Roles](nixos_configs_template/roles/README.md) compose shared modules: `base.nix` supplies locale, time zone and keyboard settings; `client.nix` adds binary compatibility, optimizations and client sudo rules; `server.nix` adds essential CLI tools, server SSH and server networking. The host selects its role, users, hardware, storage, boot and optional features. Keep `system.stateVersion` at the release used for the original installation.

The [host guide](nixos_configs_template/hosts/README.md) covers the client and server examples. WiFi, SSH/RDP access restrictions and Syncthing live in each host directory. The [Disko guide](nixos_configs_template/hosts/disk_configurations/README.md) includes a server layout with a 1 GiB EFI partition, random-key encrypted swap and passphrase-protected LUKS2 Btrfs subvolumes for root, home, the Nix store and the work directory. [Secure Boot](nixos_configs_template/hosts/secure_boot/README.md) remains optional.

### `users` and secrets

[Account modules](nixos_configs_template/users/README.md) separate the administrator identity, optional client customizations and worker identity. The worker account uses a dedicated work group and directory. Prepare SSH public-key data through the shared and host encrypted values consumed by each host configuration and keep passwords, password hashes, WiFi PSKs and private keys outside `env.conf` and plain Nix files. Follow the [SOPS guide](nixos_configs_template/common/config/SECRETS.md) to prepare encrypted values and recipients. Syncthing device and folder declarations belong to the selected host.

---

## Usage

Refer to the [`HOWTO.md`](HOWTO.md) file to learn how to use the configuration files.

### Upgrading NixOS

For detailed instructions on upgrading your NixOS system to a newer version (both minor and major upgrades), including important information about the `stateVersion` variable, please refer to the [`UPGRADE_SYSTEM.md`](UPGRADE_SYSTEM.md) file.

---

## Additional Motivations

I used the need to “quickly replicate workstation configurations” as an excuse to try out **NixOS** and its immutable-system approach. Of course, there are many other ways to achieve similar results (e.g., using Ansible), but I wanted a project where I could also leverage AI services for certain tasks like adding explanatory comments next to each package, which saved a lot of time.

This project is still a **work in progress**; the next steps (see [To-Do](#to-do) below) remain to be implemented.

---

## To-Do

- ~~**Installation with Btrfs**  
  The graphical installers currently only allow formatting the root disk with an `ext4` filesystem. However, it is possible to manually set up a `Btrfs` filesystem.  
  See [Btrfs on NixOS Wiki](https://nixos.wiki/wiki/Btrfs).~~
  ✅ *Completed: configuration using Disko added in March 2025.*

- ~~**Secure Boot Activation with Lanzaboote**  
  Enable Secure Boot using the community tool [Lanzaboote](https://github.com/nix-community/lanzaboote).~~
  ✅ *Completed: configuration files and comprehensive documentation added in January 2026. See [`hosts/secure_boot/`](nixos_configs_template/hosts/secure_boot/README.md) for details.*

- **Import KDE Profile**  
  Automatically import the KDE profile during the build, rather than requiring a manual import.


---

## Contributing

If you find these configs useful or want to help improve them, feel free to open a pull request or create an issue in the repository.

---

## Sources & References

- **Vimjoyer’s YouTube Channel**  
  [https://www.youtube.com/@vimjoyer](https://www.youtube.com/@vimjoyer)  
  My first encounter with NixOS, offering helpful insights into the system.

- **Sascha Koenig’s “Rebuilding my NixOS flake configuration from scratch”**  
  [Playlist](https://www.youtube.com/playlist?list=PLCQqUlIAw2cCuc3gRV9jIBGHeekVyBUnC)  
  This series provided inspiration for the folder/file structure, which itself drew on:

- **Misterio77’s nix-starter-configs**  
  [https://github.com/Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)

- **Official NixOS Manual**  
  [https://nixos.org/manual/nixos/stable/](https://nixos.org/manual/nixos/stable/)

- **NixOS Wiki**  
  [https://nixos.wiki/wiki/](https://nixos.wiki/wiki/)

- **Nix Package & Option Search**  
  [https://search.nixos.org/packages](https://search.nixos.org/packages?)

- **notusknot's dotfiles and nix files repository**
  [https://github.com/notusknot/dotfiles-nix/](https://github.com/notusknot/dotfiles-nix/)

- **Configuration example (Blog)**: [https://0xda.de/blog/2024/06/framework-and-nixos-day-one/](https://0xda.de/blog/2024/06/framework-and-nixos-day-one/)

- **Another configuration example (Blog)**: [https://bmcgee.ie/posts/2022/12/setting-up-my-new-laptop-nix-style/](https://bmcgee.ie/posts/2022/12/setting-up-my-new-laptop-nix-style/)

---

## Disclaimer

This is a work in progress, and I am still learning how to use this Operating System.  
I assume no responsibility for any malfunctions or data loss on your computer.  
Use these configuration files at your own risk.
