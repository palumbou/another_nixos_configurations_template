{
  disko.devices = {
    disk = {
      main = {
        # Specifies that we're configuring a disk (rather than a partition, etc.)
        type = "disk";
        # The device path where this disk resides
        device = "/dev/${DISK_DEVICE}";

        content = {
          # Use a GPT (GUID Partition Table) on this disk
          type = "gpt";
          partitions = {
            # EFI System Partition (ESP)
            ESP = {
              # Priority determines the order if multiple partitions might overlap
              priority = 1;
              name = "ESP";
              start = "1M";     # The partition starts at 1 MiB
              end   = "128M";   # Ends at 128 MiB, making it 127 MiB in size
              type  = "EF00";   # GPT partition type code for EFI System Partitions
              content = {
                # Create a filesystem on this partition
                type = "filesystem";
                format = "vfat";     # FAT32 required for EFI boot
                mountpoint = "/boot"; # Mount the partition at /boot
                mountOptions = [ "umask=0077" ]; # Restrictive file permissions
              };
            };

            # The root partition
            root = {
              size = "100%"; # Use the remaining disk space
              content = {
                # Format this partition with Btrfs
                type = "btrfs";
                # Overwrite an existing partition if present
                extraArgs = [ "-f" ];

                # Declare multiple Btrfs subvolumes
                subvolumes = {
                  # Subvolume with a different name than its mountpoint
                  "/rootfs" = {
                    mountpoint = "/";
                  };
                  # Subvolume name matches its mountpoint; uses compression
                  "/home" = {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/home";
                  };
                  # A deeper subvolume under /home with no direct mountpoint, since its parent is mounted
                  "/home/user" = { };
                  # Another subvolume requiring a mountpoint since its parent isn't mounted
                  "/nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                  # This subvolume is created but not mounted
                  "/test" = { };
                  # A subvolume designated for swap usage
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap = {
                      swapfile.size = "20M";
                      # Optionally define a second swapfile with a different path
                      swapfile2.size = "20M";
                      swapfile2.path = "rel-path";
                    };
                  };
                };

                # Mountpoint for the overall partition itself (only used if subvolumes are not individually mounted)
                mountpoint = "/partition-root";

                # Define additional swapfiles within the root partition
                swap = {
                  swapfile = {
                    size = "20M";
                  };
                  swapfile1 = {
                    size = "20M";
                  };
                };
              };
            };
          };
        };
      };
