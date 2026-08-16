{
  disko.devices = {
    disk = {
      main = {
        # Identifies that we're configuring a disk
        type = "disk";
        # Specifies the device path that we are partitioning and formatting
        device = "/dev/${DISK_DEVICE}";

        content = {
          # Use a GPT partition table on this disk
          type = "gpt";
          partitions = {
            # EFI System Partition (ESP)
            ESP = {
              size = "512M";  # Partition size for the EFI boot partition
              type = "EF00";  # GPT partition type code for EFI
              content = {
                # Specifies a filesystem on this partition
                type = "filesystem";
                format = "vfat";     # FAT32 needed by EFI
                mountpoint = "/boot"; # Mount the ESP at /boot
                # Restricts access for increased security
                mountOptions = [ "umask=0077" ];
              };
            };

            # Encrypted partition (LUKS)
            luks = {
              size = "100%";  # Occupies all remaining space
              content = {
                # Indicates a LUKS-encrypted container
                type = "luks";
                name = "crypted";  # Name for the opened LUKS device
                # Allows a password file rather than interactive entry
                passwordFile = "/tmp/secret.key"; # Set to enable interactive or file-based decryption
                settings = {
                  allowDiscards = true; # Enables TRIM commands on this encrypted partition
                  # Unlock at boot with a USB key instead of typing the passphrase (see LUKS_KEYS.md):
                  # keyFile = "/dev/usbkey";   # udev symlink to the USB key stick
                  # keyFileSize = 4096;        # read only the first 4096 bytes as the key
                  # keyFileTimeout = 10;       # fall back to the passphrase prompt after 10 seconds
                };
                # Enroll extra keys (e.g. USB sticks) at format time (see LUKS_KEYS.md):
                # additionalKeyFiles = [ "/tmp/usbkey1.key" "/tmp/usbkey2.key" ];

                content = {
                  # Formats the inside of the LUKS container as Btrfs
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Force override if a filesystem is already present
                  # Defines multiple Btrfs subvolumes
                  subvolumes = {
                    "/root" = {
                      # The primary root volume
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      # A separate subvolume for /home
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      # A separate subvolume for /nix
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/swap" = {
                      # A subvolume intended for a swap file
                      mountpoint = "/.swapvol";
                      # Defines a 20MB swap file in this subvolume
                      swap.swapfile.size = "20M";
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