# Packages

This folder contains configuration files for various package groups and services, organized by functional category.

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

## Available Files

- **`desktop.nix`** - Generic packages for desktop environments
- **`development.nix`** - Development tools, IDEs, compilers, etc.
- **`firmware.nix`** - Drivers and firmware for various devices
- **`fonts.nix`** - Fonts and related configurations
- **`gnome.nix`** - Packages specific to the GNOME environment
- **`impresarial.nix`** - Business-oriented software
- **`management.nix`** - System management tools
- **`multimedia.nix`** - Audio/video players, media editors, etc.
- **`network.nix`** - Network tools, browsers, email clients, etc.
- **`printing.nix`** - CUPS and other printing packages
- **`reading.nix`** - PDF readers and other document readers
- **`ssh.nix`** - SSH client/server configuration
- **`system.nix`** - Essential system packages

## Usage

Import the desired files in your host-specific `configuration.nix` file:

```nix
imports = [
  # ...other imports...
  ../common/packages/desktop.nix
  ../common/packages/development.nix
  ../common/packages/multimedia.nix
  # ...other packages as needed...
];
```

## Customization

Each file is designed to be modular and include a coherent set of related packages. You can:

- Modify existing files to add or remove packages
- Create new files for package groups specific to your use case
- Use conditions to install packages only on certain hosts

### Example Modification

If you want to customize the `multimedia.nix` file to add a new package:

```nix
# In multimedia.nix
{ config, pkgs, ... }:

{
  # Multimedia packages
  environment.systemPackages = with pkgs; [
    # Existing packages
    vlc
    mpv
    audacity
    # Add your new package
    obs-studio
  ];

  # Other multimedia-related configurations
}
```

### Considerations

- It's advisable to keep files organized by category for easy maintenance
- Consider dependencies between packages when modifying files
- Files in this folder should only contain configurations you want to share across multiple hosts