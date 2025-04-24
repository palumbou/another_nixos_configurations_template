# System Configuration

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

This folder contains core system configuration files that define fundamental system behaviors and user privileges.

## Available Files

- **`sudo.nix`** - Configuration for sudo privileges and user permissions
- **`system.nix`** - Core system settings including locale, time zone, and basic system behaviors

## Usage

Import these configuration files in your host-specific `configuration.nix` file:

```nix
imports = [
  # ...other imports...
  ../common/config/sudo.nix
  ../common/config/system.nix
  # ...other configurations as needed...
];
```

## Customization

The configuration files in this directory define foundational system settings. You can:

- Modify `sudo.nix` to adjust user privilege levels and security policies
- Update `system.nix` to change locale settings, time zones, or core system behaviors
- Reference host-specific variables to customize settings per machine

### Example Modification

If you want to customize the system settings in `system.nix`:

```nix
# In system.nix
{ config, pkgs, ... }:

{
  # Set your time zone
  time.timeZone = "Europe/Rome";
  
  # Select internationalization properties
  i18n.defaultLocale = "it_IT.UTF-8";
  
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };
  
  # Add your custom system settings here
  system.stateVersion = "24.11"; # DO NOT CHANGE THIS
}
```

### Considerations

- The configuration files in this directory form the foundation of your system setup
- Be careful when modifying core settings as they can affect system stability
- Always test changes in a controlled environment before deploying to production systems