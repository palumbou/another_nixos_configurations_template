# NixOS Upgrade Guide

> **Available languages**: [English (current)](UPGRADE_SYSTEM.md) | [Italiano](UPGRADE_SYSTEM.it.md)

This guide explains how to upgrade your NixOS system to a newer version, both for minor and major version updates.

---

## Table of Contents

- [Understanding NixOS Versions](#understanding-nixos-versions)
- [Understanding stateVersion](#understanding-stateversion)
- [Before You Upgrade](#before-you-upgrade)
- [Minor Version Upgrade](#minor-version-upgrade)
- [Major Version Upgrade](#major-version-upgrade)
- [Post-Upgrade Steps](#post-upgrade-steps)
- [Troubleshooting](#troubleshooting)

---

## Understanding NixOS Versions

NixOS uses a versioning scheme of `YY.MM`:
- **Major version**: represents a significant release (e.g., 24.11, 25.05, 25.11)
- **Minor version**: bug fixes and security updates within the same major version

Examples:
- `24.11` → `25.05`: **Major upgrade**
- `25.05` → `25.11`: **Major upgrade**
- Updates within `25.11`: **Minor upgrade** (channel updates, package updates)

---

## Understanding stateVersion

The `system.stateVersion` variable in your configuration is **critical** and should be handled with care:

```nix
system.stateVersion = "25.11"; # This value determines the stateful data schema
```

### What is stateVersion?

`stateVersion` defines the NixOS release version that your system's **stateful data** (databases, state files, configurations) was originally set up with. It does NOT define which version of NixOS you're running.

### When to Change stateVersion

⚠️ **IMPORTANT**: only change `stateVersion` in these cases:

1. **Fresh installation**: set it to the version you're installing
2. **Intentional state migration**: when you want to migrate stateful data to a newer schema (requires careful planning)

### When NOT to Change stateVersion

❌ **DO NOT** change `stateVersion` when:
- Upgrading to a new NixOS version
- Updating packages
- Switching channels
- Rebuilding your system

### Why This Matters

Changing `stateVersion` can:
- Trigger automatic migrations of databases and state files
- Change default behaviors of services
- Potentially break existing services that depend on the current state schema
- Cause data loss if migrations fail

**Rule of thumb**: if your system is working, leave `stateVersion` unchanged unless you have a specific reason and understand the consequences.

---

## Before You Upgrade

### 1. Backup Your System

Always create a backup before upgrading:

```bash
# Backup important data
sudo rsync -av /home /path/to/backup/location
sudo rsync -av /etc/nixos /path/to/backup/location

# Document your current configuration
nixos-version > ~/nixos-version-before-upgrade.txt
nix-channel --list > ~/channels-before-upgrade.txt
```

### 2. Review the Release Notes

Always read the release notes for the target version:
- [NixOS 25.11 Release Notes](https://nixos.org/manual/nixos/stable/release-notes.html#sec-release-25.11)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

Look for:
- Breaking changes
- Deprecated options
- Required manual interventions
- New features and improvements

### 3. Clean Up Your System

```bash
# Remove old generations (keep last 3)
sudo nix-collect-garbage --delete-older-than 3d

# Check available disk space
df -h
```

---

## Minor Version Upgrade

Minor upgrades are updates within the same NixOS version (e.g., package updates, security patches).

### Steps

1. **Update channels**:
   ```bash
   sudo nix-channel --update
   ```

2. **Rebuild the system**:
   ```bash
   sudo nixos-rebuild switch
   ```

3. **Verify the update**:
   ```bash
   nixos-version
   ```

4. **Reboot if kernel was updated**:
   ```bash
   sudo reboot
   ```

**Note**: No changes to `stateVersion` are needed for minor upgrades.

---

## Major Version Upgrade

Major upgrades involve switching to a new NixOS release (e.g., 25.05 → 25.11).

### Method 1: Using Channels (Recommended for Stable Systems)

#### Step 1: Switch to the New Channel

```bash
# Check current channels
sudo nix-channel --list

# Switch to the new version (example: 25.11)
sudo nix-channel --add https://nixos.org/channels/nixos-25.11 nixos
sudo nix-channel --update
```

#### Step 2: Review Configuration Changes

Check for deprecated options or breaking changes:

```bash
# Test the configuration without applying
sudo nixos-rebuild dry-build
```

#### Step 3: Apply the Upgrade

```bash
# Upgrade the system
sudo nixos-rebuild switch --upgrade

# Alternative: build first, then switch
sudo nixos-rebuild boot --upgrade
sudo reboot
```

#### Step 4: Verify the Upgrade

```bash
nixos-version
# Should show: 25.11.xxxxxx.xxxxxxx (NixOS)
```

---

## Post-Upgrade Steps

### 1. Check System Status

```bash
# Check for failed services
systemctl --failed

# Check system logs
journalctl -p err -b
```

### 2. Update User Channels (if applicable)

```bash
# For each user
nix-channel --update
```

### 3. Clean Up Old Generations

After confirming the system works correctly:

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Remove old generations (keep last 5)
sudo nix-collect-garbage --delete-older-than 5d

# Or remove specific generations
sudo nix-env --delete-generations 1 2 3 --profile /nix/var/nix/profiles/system
```

### 4. Optimize Nix Store

```bash
sudo nix-store --optimise
```

---

## Troubleshooting

### System Won't Boot After Upgrade

1. **Boot into previous generation**:
   - At boot, select an older generation from the bootloader menu
   - Once booted, investigate the issue

2. **Rollback**:
   ```bash
   # Rollback to previous generation
   sudo nixos-rebuild switch --rollback
   ```

### Configuration Errors

If you encounter configuration errors:

```bash
# Check for syntax errors
sudo nixos-rebuild dry-build

# Review the error messages carefully
# Common issues:
# - Removed or renamed options
# - Changed default values
# - Incompatible package combinations
```

### Service Failures

```bash
# Check specific service
sudo systemctl status service-name

# View logs
sudo journalctl -u service-name -b

# Restart service
sudo systemctl restart service-name
```

### Package Build Failures

```bash
# Clear package cache
nix-collect-garbage -d

# Try rebuilding
sudo nixos-rebuild switch --upgrade

# If a specific package fails, check:
# - Release notes for that package
# - NixOS discourse: https://discourse.nixos.org/
# - GitHub issues: https://github.com/NixOS/nixpkgs/issues
```

### Recovering from a Bad stateVersion Change

If you accidentally changed `stateVersion` and things broke:

1. **Immediately change it back** to the original value
2. **Rebuild**:
   ```bash
   sudo nixos-rebuild switch
   ```
3. **Check service states**:
   ```bash
   sudo systemctl --failed
   ```
4. **Restore from backup** if necessary

---

## Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Wiki - Upgrading](https://nixos.wiki/wiki/Upgrading_NixOS)
- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS GitHub](https://github.com/NixOS/nixpkgs)
- [NixOS Release Channels](https://channels.nixos.org/)