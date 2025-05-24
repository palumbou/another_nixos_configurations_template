# Themes

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

This directory contains various themes available for software that has been considered in the configuration files.

## Available Themes

The themes are organized by software:

- **grub**: themes for the GRUB bootloader
- **hyprland**: themes for the Hyprland window manager
- **plymouth**: themes for the Plymouth boot splash screen

## How to Use

To use any of these themes, you need to enable them individually in their respective installation files. Each theme file is structured as a NixOS module that can be imported into your system configuration.

### Example

To enable a theme, import its configuration file in the specific software configuration file:

```nix
# In ../common/gui/hyprland.nix
{
  imports = [
    # Relative path to the theme you want to use
    ./themes/hyprland/hyprland_catppuccin.nix
  ];
}
```

Make sure to only enable one theme per software at a time to avoid conflicts.
