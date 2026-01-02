# GUI

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

This folder contains configurations for different graphical user interfaces (GUIs) that can be used in your NixOS hosts.

## Available Files

- **`gnome.nix`** - Configuration for the GNOME desktop environment
- **`hyprland.nix`** - Configuration for the Hyprland Wayland-based desktop environment
- **`kde.nix`** - Configuration for the KDE Plasma desktop environment

## Themes

This folder also contains a **`themes`** directory with various themes for software considered in the configuration files, organized by application:

- **`grub`** - Themes for the GRUB bootloader
- **`hyprland`** - Themes for the Hyprland window manager
- **`plymouth`** - Themes for the Plymouth boot splash screen

To use these themes, they need to be enabled individually in their respective installation files. See the [README.md](./themes/README.md) in the **`themes`** folder for more details.

## Usage

To use one of these desktop environments, import the corresponding file in your host's `configuration.nix` file:

```nix
# For GNOME
imports = [
  # ...other imports...
  ../common/gui/gnome.nix
];

# For KDE Plasma
imports = [
  # ...other imports...
  ../common/gui/kde.nix
];

# OR for Hyprland
imports = [
  # ...other imports...
  ../common/gui/hyprland.nix
];
```

## Customization

Each file contains both the packages required for the desktop environment and specific configurations. You can modify these files to:

- Add or remove environment-specific packages
- Change default settings
- Enable or disable specific features

### Hyprland Specific Setup

When using Hyprland, you need to manually add the following line to your `~/.config/hypr/hyprland.conf` file to enable the polkit authentication agent (required for virt-manager, mounting drives, and other privileged operations):

```conf
# Import NixOS system-wide configurations
source = /etc/hyprland/hyprland.d/polkit.conf
```

Add this line near the beginning of your configuration file, after other `source` directives. The polkit agent will then start automatically when Hyprland launches.

### Usage Notes

- **Avoid importing multiple GUI files simultaneously** in a single host to prevent conflicts.
- If you want to use components from multiple desktop environments, consider creating a custom file that imports only specific packages from each environment.
- The files are organized to be modular and independent of user configurations, allowing you to share them across multiple hosts.