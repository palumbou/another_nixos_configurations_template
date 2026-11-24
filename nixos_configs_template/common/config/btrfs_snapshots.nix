{ config, lib, ... }:
{
  # Create a snapshot container for every configured Btrfs subvolume.
  systemd.tmpfiles.rules = lib.unique (
    lib.mapAttrsToList (_: snapshot:
      "v ${lib.removeSuffix "/" (toString snapshot.SUBVOLUME)}/.snapshots 0750 root root -"
    ) (
      lib.filterAttrs (_: snapshot: snapshot.FSTYPE == "btrfs")
        config.services.snapper.configs
    )
  );

  # Shared defaults for Btrfs hosts with separate root and home subvolumes.
  services.snapper = {
    snapshotInterval = lib.mkDefault "hourly";
    cleanupInterval = lib.mkDefault "1d";
    persistentTimer = lib.mkDefault true;

    configs = lib.mkMerge [ (lib.mkIf ((config.fileSystems."/".fsType or "") == "btrfs") {
      root = {
        SUBVOLUME = lib.mkDefault "/";
        TIMELINE_CREATE = lib.mkDefault true;
        TIMELINE_CLEANUP = lib.mkDefault true;
        TIMELINE_LIMIT_HOURLY = lib.mkDefault 3;
        TIMELINE_LIMIT_DAILY = lib.mkDefault 4;
        TIMELINE_LIMIT_WEEKLY = lib.mkDefault 0;
        TIMELINE_LIMIT_MONTHLY = lib.mkDefault 0;
        TIMELINE_LIMIT_YEARLY = lib.mkDefault 0;
      };

    }) (lib.mkIf ((config.fileSystems."/home".fsType or "") == "btrfs") {
      home = {
        SUBVOLUME = lib.mkDefault "/home";
        TIMELINE_CREATE = lib.mkDefault true;
        TIMELINE_CLEANUP = lib.mkDefault true;
        TIMELINE_LIMIT_HOURLY = lib.mkDefault 6;
        TIMELINE_LIMIT_DAILY = lib.mkDefault 7;
        TIMELINE_LIMIT_WEEKLY = lib.mkDefault 4;
        TIMELINE_LIMIT_MONTHLY = lib.mkDefault 2;
        TIMELINE_LIMIT_YEARLY = lib.mkDefault 0;
      };
    }) ];
  };
}
