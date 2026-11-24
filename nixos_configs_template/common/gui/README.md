# Graphical interfaces

> **Language versions**: [English (current)](README.md) | [Italiano](README.it.md)

Local desktop selection and remote Xfce sessions are independent. Select `none`, KDE, GNOME or Hyprland for the local desktop. A headless host needs no local desktop module.

| File | Purpose |
| --- | --- |
| `gnome.nix` | GNOME desktop and its display manager. |
| `kde.nix` | KDE Plasma, its display manager and KDE package group. |
| `hyprland.nix.template` | Hyprland Wayland environment, session tools and theme; replace `${FONT}`. |
| `xfce-rdp.nix` | Xfce sessions over xrdp, without starting a local display manager. |

## Usage

From `hosts/client/<name>/configuration.nix` or `hosts/server/<name>/configuration.nix`, select one local desktop through an optional import:

```nix
imports = [
  ../../../common/gui/kde.nix
];
```

For optional remote Xfce, add `../../../common/gui/xfce-rdp.nix` independently of local desktop selection. The host sets `RDP_PORT`; permitted IPv4/IPv6 CIDRs belong in the host's `nm_configurations.nix`. The RDP module opens no firewall port automatically, disallows direct root login and requires a non-empty PAM password. Set up the intended non-root account's password separately; SSH keys are not RDP credentials.

`xfce-rdp.nix` uses a dedicated D-Bus session and leaves the local X server disabled by default. A selected local desktop can still enable its own local display service.

## Themes and local configuration

[`themes/`](themes/README.md) contains GRUB, Hyprland and Plymouth themes. Select one theme per application and review each desktop's packages and defaults. Keyboard layout comes from the shared `system.nix.template` using `KEY_LAYOUT`.

Avoid selecting multiple complete local desktop modules unless you have reviewed their display-manager and session settings. Desktop selection does not select optional application groups, Docker or libvirt.

For Hyprland, include its system Polkit agent startup configuration in `~/.config/hypr/hyprland.conf`:

```conf
# Import NixOS system-wide configuration.
source = /etc/hyprland/hyprland.d/polkit.conf
```

Place this near the other `source` directives. An authentication agent is required for desktop privilege prompts such as Virt Manager, drive mounting and Btrfs Assistant.
