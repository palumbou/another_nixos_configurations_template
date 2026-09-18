{ config, lib, pkgs, ... }:
let
  # Normal (non-system) users allowed to browse and restore their own /home snapshots
  normalUsers = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
in
{
  # Snapper timeline snapshots on / and /home, both btrfs subvolumes of the same disk.
  # /nix stays out on purpose: the store is rebuilt from the Nix generations.
  # /boot is vfat and /.swapvol is a sibling subvolume, neither ends up in a snapshot.
  # WARNING: import only on btrfs hosts whose / and /home are subvolumes.

  # Snapper needs a .snapshots subvolume inside each configured subvolume and NixOS
  # never runs "snapper create-config", so create them here ("v" makes a subvolume).
  systemd.tmpfiles.rules = [
    "v /.snapshots 0750 root root -"
    "v /home/.snapshots 0750 root root -"
  ];

  # Qt GUI to browse and restore snapshots and manage subvolumes, escalates via pkexec.
  # The snapper CLI and btrfs-progs arrive on their own from the snapper and btrfs modules.
  environment.systemPackages = [ pkgs.btrfs-assistant ];

  services.snapper = {
    # Timeline snapshots are taken hourly and pruned once a day
    snapshotInterval = "hourly";
    cleanupInterval = "1d";

    # Runs a missed snapshot at the next boot, needed on machines that are often off
    persistentTimer = true;

    # Takes an extra snapshot of / at every boot, needs a config named "root"
    #snapshotRootOnBoot = true;

    configs = {
      # System state outside the Nix store: /etc, /var and /var/lib service data
      root = {
        SUBVOLUME = "/";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 3;
        TIMELINE_LIMIT_DAILY = 4;
        TIMELINE_LIMIT_WEEKLY = 0;
        TIMELINE_LIMIT_MONTHLY = 0;
        TIMELINE_LIMIT_YEARLY = 0;
      };

      # User data, the part with no equivalent of the Nix generations rollback
      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = normalUsers;
        SYNC_ACL = true; # Grants ALLOW_USERS access to .snapshots through ACLs
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 6;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 2;
        TIMELINE_LIMIT_YEARLY = 0;
      };
    };
  };
}
