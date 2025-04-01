{
  disko.devices = {
    disk = {
      main = {
        # Specifies the disk device to partition and format
        type = "disk";
        device = "/dev/${DISK_DEVICE}";

        content = {
          # Defines a GPT partition table for this disk
          type = "gpt";
          partitions = {
            # EFI System Partition (ESP)
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";    # The partition begins at 1MiB (common alignment practice)
              end   = "128M";  # Size goes up to 128MiB for the ESP
              type  = "EF00";  # GPT code for EFI partitions
              content = {
                # Formats this partition as a filesystem
                type = "filesystem";
                format = "vfat";
                # Mounts the EFI partition at /boot
                mountpoint = "/boot";
                # Sets file system options for improved security
                mountOptions = [ "umask=0077" ];
              };
            };

            # The root partition
            root = {
              size = "100%";  # Uses the remainder of the disk
              content = {
                # Sets the filesystem type to btrfs
                type = "btrfs";
                # Forces the operation if a partition with data already exists
                extraArgs = [ "-f" ]; # Override existing partition
                mountpoint = "/";
                # Compresses data with zstd and disables access time updates
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}