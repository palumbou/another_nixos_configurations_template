{
  disko.devices = {
    disk = {
      main = {
        # Identifies that we're working with a disk (instead of e.g. a partition)
        type = "disk";
        # Specifies the device path where the disk is located
        device = "/dev/${DISK_DEVICE}";

        content = {
          # Use a GPT partition table for this disk
          type = "gpt";
          partitions = {
            # EFI System Partition (ESP)
            ESP = {
              size = "512M";  # Sets the partition size to 512 MiB
              type = "EF00";  # GPT code for an EFI System Partition
              content = {
                # Declares that this partition is to be formatted as a filesystem
                type = "filesystem";
                format = "vfat";     # FAT32 (vfat) required by EFI
                mountpoint = "/boot"; # Mount the ESP at /boot
                mountOptions = [ "umask=0077" ]; # Provides secure permissions
              };
            };

            # Encrypted partition (LUKS)
            luks = {
              size = "100%";  # Use all remaining space
              content = {
                # Declares this partition as a LUKS container
                type = "luks";
                name = "crypted"; # Name used for the mapped device
                # A key file can be used instead of an interactive password
                passwordFile = "/tmp/secret.key"; # Currently points to a file, but can be replaced with interactive entry
                settings = {
                  allowDiscards = true; # Allows TRIM operations on the encrypted partition
                  # Unlock at boot with a USB key instead of typing the passphrase (see LUKS_KEYS.md):
                  # keyFile = "/dev/usbkey";   # udev symlink to the USB key stick
                  # keyFileSize = 4096;        # read only the first 4096 bytes as the key
                  # keyFileTimeout = 10;       # fall back to the passphrase prompt after 10 seconds
                };
                # Enroll extra keys (e.g. USB sticks) at format time (see LUKS_KEYS.md):
                # additionalKeyFiles = [ "/tmp/usbkey1.key" "/tmp/usbkey2.key" ];

                # Inside the LUKS container, set up a Btrfs filesystem
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Force overwrite if needed
                  # Creates separate Btrfs subvolumes for root, home, and nix
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}