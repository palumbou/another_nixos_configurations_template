{ ... }:
{
  # Periodic btrfs scrub: re-reads every allocated block and verifies its checksum.
  # Catches silent corruption (bit rot) instead of discovering it when opening a file.
  # DUP/RAID metadata is repaired from the good copy; single data is only reported.
  # WARNING: import only on btrfs hosts, on other filesystems the build fails on an assertion.
  services.btrfs.autoScrub = {
    enable = true;

    # Systemd calendar expression, monthly is the period recommended by btrfs-scrub(8)
    interval = "monthly";

    # Defaults to every btrfs mount point, deduplicated per device (one unit per disk)
    #fileSystems = [ "/" ];

    # Throughput cap in bytes per second (K/M/G/T suffixes), useful on slow disks
    #limit = "100M";
  };
}
