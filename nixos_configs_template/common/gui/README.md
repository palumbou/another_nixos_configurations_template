# GUI

This folder contains configurations for different graphical user interfaces (GUIs) that can be used in your NixOS hosts.

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

## Available Files

- **`hyprland.nix`** - Configuration for the Hyprland Wayland-based desktop environment
- **`kde.nix`** - Configuration for the KDE Plasma desktop environment

## Usage

To use one of these desktop environments, import the corresponding file in your host's `configuration.nix` file:

```nix
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

### Usage Notes

- **Avoid importing multiple GUI files simultaneously** in a single host to prevent conflicts.
- If you want to use components from multiple desktop environments, consider creating a custom file that imports only specific packages from each environment.
- The files are organized to be modular and independent of user configurations, allowing you to share them across multiple hosts.