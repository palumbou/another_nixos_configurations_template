# Another NixOS Configurations Template

A template-based approach to setting up and replicating NixOS configurations quickly and consistently.

## Introduction

Returning to Linux as my daily operating system, I wanted a stable, secure, and easily replicable setup-one that would get me from a blank hard drive to a fully configured workstation, complete with my personal settings, in the shortest time possible.

I also wanted an operating system that would facilitate company-wide client management, allowing for exact environment replication (except for user-specific data). For me, the answer was **NixOS**.

Initially, in early 2023, I started exploring NixOS but set it aside due to lack of time, switching to Fedora KDE (which I loved and could configure in under an hour from scratch). By the end of 2024, eager to invest time in developing dotfiles for a completely customized and replicable graphical environment, I decided to go one step further. Instead of just revisiting my desktop environment, I wanted to rebuild my entire OS configuration, so I returned to NixOS.

I spent countless hours reading the official manual, watching YouTube videos, and studying other users’ configuration files on GitHub (all sources are listed in the [Sources](#sources) section). Then I chose to write all configuration files from scratch, structuring folders and files to meet my needs while keeping the principle of **“Keep It Simple”** and **“Less Is More”** in mind.

**Why share these files?**  
I decided to turn my configs into a readable, heavily commented template that anyone could copy and modify as needed. I also created a script to automate their customization.

---

## Explanation of Choices

In 2023, I made the mistake of jumping straight into **Flakes** and **Home Manager**, thinking I needed to include everything from the get-go. This complexity led me to abandon the project. In 2024, I nearly repeated the same mistake until I read [this update](https://github.com/Misterio77/nix-starter-configs/issues/86) from [Misterio77’s nix-starter-configs](https://github.com/Misterio77/nix-starter-configs). It was one of many insights suggesting that Flakes and Home Manager might be introduced later if really necessary, rather than right away.

---

## Folder and File Structure

Below is the directory structure I’ve planned, along with the files included. Each subfolder has its own dedicated README explaining the files and subfolders in detail:
```bash
nixos_configs/                    # Parent folder
└── common/                       # Configuration files and subfolders common to all hosts/users
    ├── gui/                      # GUI-related configuration
    ├── packages/                 # Configuration for software packages to install
    └── network/                  # Network-related configuration files
    │   └── nmconnection_files/   # NetworkManager connection files
└── hosts/                        # Subfolders for each defined host
    └── ABC/                      # Configuration files for host 'ABC'
└── users/                        # Subfolders for each defined user
    └── XYZ/                      # Configuration files for user 'XYZ'
        └── dotfile/              # Dotfiles for user 'XYZ'
```

### The `nixos_configs` Folder

The `nixos_configs` folder contains all the configuration files needed for your environment.  
It must be **copied onto the target system**, and you’ll need to replace the path within the configuration files wherever file-copy paths are referenced. This ensures you have the correct absolute path for the build process to pull the specified files.

Inside `nixos_configs`, there are three subfolders:

1. [`common`](#common)
2. [`hosts`](#hosts)
3. [`users`](#users)

---

#### `common`

The **`common`** folder contains NixOS configuration files that are shared by all hosts and users. Inside it, there are three subfolders:

- **`gui`** – Contains possible GUI configurations (currently Hyprland and KDE), from which you can choose.  
- **`packages`** – Specifies which packages to install and which services to enable.  
- **`network`** – Network-related configurations. Inside this folder is another subfolder, `nmconnection_files`, which holds the Network Manager connection files.

---

#### `hosts`

The **`hosts`** folder stores individual host configurations, each in its own subfolder named after the host. Inside every host’s subfolder, you’ll find:

- **`configuration.nix`** – The base configuration for that specific host. Here you specify which common packages and services to import from `common/packages` as well as which users you want to define.  
- **`hardware-configuration.nix`** – Defines hardware-specific settings. You can obtain this file by:
  - Copying it from `/etc/nixos` after installing NixOS from an [official ISO](https://nixos.org/download/).
  - Generating it via `nixos-generate-config` on the host.
  - Importing it from the official [nixos-hardware repository](https://github.com/NixOS/nixos-hardware), which hosts a collection of hardware-specific configurations.

- (Optional) The file `nm_configurations.nix` for importing specific Network Manager connections needed by that host.

To add a new host, create a new folder named after the host and place both `configuration.nix` and `hardware-configuration.nix` inside it. In `configuration.nix`, be sure to reference:

- The desired `common/packages` configurations.
- The `users` you want to enable for that host.

---

#### `users`

The **`users`** folder contains configurations for individual users, each in its own subfolder named after the user. Within each user subfolder:

- **`USERNAME.nix`** – The NixOS configuration file for that user.
- A **`dotfiles`** subfolder – Holds the user’s personal dotfiles, which will be copied into the user’s `~/.config/` directory.

You’ll reference a user’s configuration in the chosen host’s `configuration.nix` file to make that user available when the system is built.

---

## Usage

Currently, this guide does not provide steps for installing NixOS **directly** with your own configurations.  
Instead, you should:

1. **Install NixOS** normally.
2. **Modify** the configuration files as desired.
3. **Build** those files on your NixOS host.

---

### Installing NixOS

Download the desired ISO (either Gnome or KDE-Plasma) from the  
[official NixOS project page](https://nixos.org/download/) under the “NixOS: the Linux distribution” heading.  
Boot this ISO on your host machine.

During the installation:

- **Disk Partitioning**  
  After installation, you’ll find a generated configuration file in `/etc/nixos/configuration.nix`.  
  Inside it, there will be a line specifying the GRUB device, for example:  
  ```nix
  boot.loader.grub.device = "/dev/disk/by-id/wwn-0x500001234567890a";
  ```  
  Ensure you **save** this value (`/dev/disk/by-id/wwn-...`) for later use, as it will be needed in your custom configuration.

- **User**  
  Choose the same username as you plan to specify in the configuration files that your host will import.  
  Alternatively, if you want to keep an existing user, copy its configuration from the file generated by the installer.

> **Important**: All these settings will be overwritten by your own configuration files after the first build, so partitioning and user naming are the main details to watch during installation.

---

### Modifying Configuration Files

You can use this structure in **two ways**:

> **Notice**: before you edit any configuration files, make sure to **read the `env.conf` file**.
> It contains environment variables and references to the files where they are used.
> Feel free to modify `env.conf` to suit your needs, whether you’re copying files manually or using the script. 

1. **Manual Copy**  
   - Make a copy of the `nixos_configs_template` folder.  
   - Remove the `template` suffix from each file extension (changing `.nix.template` to `.nix`).  
   - In every file, replace any variables (listed in the `env.conf` file) with the appropriate values for your setup.

2. **Using the Script**  
   - Run the `nixos_configs_generator.sh` script (see the  
     [nixos_configurations_generator repository](https://github.com/palumbou/nixos_configurations_generator)) to automate the steps above.

---

### Build

When you’re ready to **build** using your chosen configuration file, run:

```bash
nixos-rebuild switch -I nixos-config=PATH_NIXOS_CONF_FOLDER/configuration.nix
```

Replace **`PATH_NIXOS_CONF_FOLDER`** with either the **absolute** or **relative** path to the folder containing `configuration.nix` file.

> **Tip:** For additional details during the build process, add the `--show-trace` option.  
> Example:
> ```bash
> nixos-rebuild switch -I nixos-config=./configuration.nix --show-trace
> ```

---

## Additional Motivations

I used the need to “quickly replicate workstation configurations” as an excuse to try out **NixOS** and its immutable-system approach. Of course, there are many other ways to achieve similar results (e.g., using Ansible), but I wanted a project where I could also leverage AI services for certain tasks like adding explanatory comments next to each package, which saved a lot of time.

This project is still a **work in progress**; the next steps (see [To-Do](#to-do) below) remain to be implemented.

---

## To-Do

- **Installation with Btrfs**  
  The graphical installers currently only allow formatting the root disk with an `ext4` filesystem. However, it is possible to manually set up a `Btrfs` filesystem.  
  See [Btrfs on NixOS Wiki](https://nixos.wiki/wiki/Btrfs).

- **Import KDE Profile**  
  Automatically import the KDE profile during the build, rather than requiring a manual import.

- **Improve the `nixos_config_generator.sh` Script**  
  Add functionality to generate configuration and hardware files via `nixos-generate-config`.

---

## Contributing

If you find these configs useful or want to help improve them, feel free to open a pull request or create an issue in the repository.

---

## Sources

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

---

## Disclaimer

This is a work in progress, and I am still learning how to use this Operating System.  
I assume no responsibility for any malfunctions or data loss on your computer.  
Use these configuration files at your own risk.
