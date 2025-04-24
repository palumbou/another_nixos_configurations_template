# Packages

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

This folder contains configuration files for various package groups and services, organized by functional category.

## Available Files

- **`default_packages_services.nix`** - Essential default packages and services for basic system functionality
- **`extra_packages_services.nix`** - Additional packages and services for extended functionality
- **`grub.nix`** - GRUB bootloader configuration (must be imported when using GRUB as bootloader)
- **`kde_packages.nix`** - Packages specific to the KDE Plasma environment (already imported in file ../gui/kde.nix)
- **`syncthing.nix`** - Configuration for the Syncthing file synchronization service
- **`workstation_packages_services.nix`** - Packages and services tailored for workstation setups

## Usage

Import the desired files in your host-specific `configuration.nix` file:

```nix
imports = [
  # ...other imports...
  ../common/packages/default_packages_services.nix
  ../common/packages/workstation_packages_services.nix
  ../common/packages/syncthing.nix
  # ...other packages as needed...
];
```

## Customization

Each file is designed to be modular and include a coherent set of related packages. You can:

- Modify existing files to add or remove packages
- Create new files for package groups specific to your use case
- Use conditions to install packages only on certain hosts

### Example Modification

If you want to customize the `workstation_packages_services.nix` file to add a new package:

```nix
# In workstation_packages_services.nix
{ config, pkgs, ... }:
{
  # Add workstation packages
  environment.systemPackages = with pkgs; [
    gimp    # Image editor
    # Add your new package
    vscode  # Visual Studio Code editor
  ];

  # Other workstation-related configuration
}

```

### Considerations

- It's advisable to keep files organized by category for easy maintenance
- Consider dependencies between packages when modifying files
- Files in this folder should only contain configurations you want to share across multiple hosts